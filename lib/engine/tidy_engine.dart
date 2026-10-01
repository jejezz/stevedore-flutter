import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../rules/rule.dart';
import 'file_ops.dart';
import 'history.dart';
import 'ignored_files.dart';
import 'paths.dart';
import 'stability_tracker.dart';

typedef _Signature = ({int size, DateTime modified});

/// 규칙에 걸린 파일 하나와 해야 할 일. 실행하기 전의 계획이라서 미리보기에도 쓴다.
class PlannedAction {
  const PlannedAction({required this.rule, required this.path, required this.facts});

  final Rule rule;
  final String path;
  final FileFacts facts;

  RuleAction get action => rule.action;
}

class PlanResult {
  const PlanResult({required this.actions, required this.waiting});

  final List<PlannedAction> actions;

  /// 규칙에는 맞지만 아직 받는 중일 수 있어 기다리는 파일 수.
  final int waiting;
}

/// 실행한 결과 하나. [resultPath]는 옮긴 곳(이동) 또는 휴지통 안의 위치(알 수 있을 때).
class ActionResult {
  const ActionResult({required this.planned, required this.time, this.resultPath, this.error});

  final PlannedAction planned;
  final DateTime time;
  final String? resultPath;
  final Object? error;

  bool get succeeded => error == null;
}

/// 폴더를 감시하다가 규칙에 맞는 파일을 정리한다.
///
/// - 폴더 바로 아래의 일반 파일만 본다 (하위 폴더, 심볼릭 링크, 숨김 파일은 건드리지 않음).
/// - 받는 중인 임시 파일은 제외하고, 크기·수정 시각이 [settle] 동안 같은 파일만 처리한다.
/// - 규칙은 목록 순서대로 보고 처음 맞는 하나만 적용한다.
class TidyEngine {
  TidyEngine({
    FileOps? ops,
    DateTime Function()? clock,
    this.settle = const Duration(seconds: 5),
    this.tick = const Duration(seconds: 2),
    Map<String, String>? env,
  })  : _ops = ops ?? SystemFileOps(env: env),
        _clock = clock ?? DateTime.now,
        _env = env,
        _stability = StabilityTracker(settle: settle);

  final FileOps _ops;
  final DateTime Function() _clock;
  final Duration settle;
  final Duration tick;
  final Map<String, String>? _env;
  final StabilityTracker _stability;

  List<Rule> _rules = const [];

  /// 건드리지 않을 파일: 되돌려 놓은 파일, 실행에 실패한 파일. 크기·수정 시각이
  /// 그대로인 동안만 건너뛴다 — 되돌린 파일을 규칙이 바로 다시 옮기거나 실패를
  /// 무한히 되풀이하는 일을 막는다.
  final Map<String, _Signature> _suppressed = {};
  final Map<String, StreamSubscription<FileSystemEvent>> _watchers = {};
  Timer? _timer;
  bool _dirty = false;
  bool _busy = false;

  final _results = StreamController<List<ActionResult>>.broadcast();
  final _errors = StreamController<Object>.broadcast();

  /// 실행이 끝날 때마다 그 결과들이 나온다.
  Stream<List<ActionResult>> get results => _results.stream;

  /// 폴더를 열지 못하는 등 감시 중 생긴 오류 (권한 거부 포함).
  Stream<Object> get errors => _errors.stream;

  List<Rule> get rules => _rules;

  bool get isRunning => _timer != null;

  String _folderOf(Rule r) => expandPath(r.watchedFolder, env: _env);

  /// 규칙을 바꾼다. 실행 중이면 감시 폴더도 새 규칙에 맞게 다시 잡는다.
  Future<void> setRules(List<Rule> rules) async {
    _rules = List.unmodifiable(rules);
    if (isRunning) await _syncWatchers();
  }

  /// [path]를 내용이 바뀔 때까지 정리 대상에서 뺀다.
  Future<void> suppress(String path) async {
    try {
      final stat = await File(path).stat();
      if (stat.type == FileSystemEntityType.file) _suppressed[path] = (size: stat.size, modified: stat.modified);
    } on FileSystemException {
      // 이미 없다
    }
  }

  /// 기록한 이동·휴지통 동작을 되돌린다. 원래 폴더가 없어졌으면 만들고, 원래 이름이
  /// 이미 쓰이고 있으면 번호를 붙인다. 되돌려진 경로를 돌려준다.
  Future<String> undo(HistoryEntry entry) async {
    final from = entry.resultPath;
    if (!entry.canUndo || from == null) throw StateError('되돌릴 수 없는 기록입니다');
    if (await FileSystemEntity.type(from, followLinks: false) != FileSystemEntityType.file) {
      throw FileSystemException('옮긴 파일을 찾을 수 없습니다', from);
    }
    final restored = await _ops.move(from, p.dirname(entry.sourcePath), asName: p.basename(entry.sourcePath));
    await suppress(restored);
    return restored;
  }

  /// 지금 폴더들을 훑어서 할 일을 계획한다. 파일을 건드리지 않는다.
  /// [requireStable]이 true면 아직 안정되지 않은 파일은 [PlanResult.waiting]으로만 센다.
  Future<PlanResult> plan({required bool requireStable}) async {
    final now = _clock();
    final byFolder = <String, List<Rule>>{};
    for (final r in _rules.where((r) => r.enabled)) {
      byFolder.putIfAbsent(_folderOf(r), () => []).add(r);
    }

    final actions = <PlannedAction>[];
    final live = <String>{};
    var waiting = 0;

    for (final entry in byFolder.entries) {
      final List<FileSystemEntity> entries;
      try {
        entries = await Directory(entry.key).list(followLinks: false).toList();
      } on FileSystemException catch (e) {
        _errors.add(e);
        continue;
      }
      for (final e in entries) {
        if (e is! File) continue; // 폴더, 링크 제외
        final name = p.basename(e.path);
        if (isIgnoredFileName(name)) continue;
        final FileStat stat;
        try {
          stat = await e.stat();
        } on FileSystemException {
          continue; // 그 사이 사라짐
        }
        final facts = FileFacts(name: name, sizeBytes: stat.size, modified: stat.modified);
        final rule = entry.value.where((r) => r.matches(facts, now: now)).firstOrNull;
        if (rule == null) continue;
        final held = _suppressed[e.path];
        if (held != null) {
          if (held.size == stat.size && held.modified == stat.modified) continue;
          _suppressed.remove(e.path); // 내용이 바뀌었으니 다시 대상
        }
        live.add(e.path);
        // 수동 정리도 방금 바뀐 파일(받는 중일 수 있음)은 건드리지 않는다.
        if (!requireStable && settle > Duration.zero && now.difference(stat.modified) < settle) {
          waiting++;
          continue;
        }
        if (requireStable &&
            !_stability.isStable(e.path, size: stat.size, modified: stat.modified, now: now)) {
          waiting++;
          continue;
        }
        actions.add(PlannedAction(rule: rule, path: e.path, facts: facts));
      }
    }
    _stability.retainOnly(live);
    return PlanResult(actions: actions, waiting: waiting);
  }

  /// 계획을 실행한다. 계획한 뒤 파일이 바뀌었으면(받기가 다시 시작되는 등) 건너뛴다.
  /// 실행한 것의 결과만 돌려준다 — 건너뛴 것은 다음 훑기에서 다시 본다.
  Future<List<ActionResult>> apply(List<PlannedAction> planned) async {
    final out = <ActionResult>[];
    for (final item in planned) {
      final FileStat stat;
      try {
        stat = await File(item.path).stat();
      } on FileSystemException {
        continue;
      }
      if (stat.type != FileSystemEntityType.file ||
          stat.size != item.facts.sizeBytes ||
          stat.modified != item.facts.modified) {
        continue;
      }
      try {
        final resultPath = switch (item.action) {
          MoveAction(:final destination) => await _ops.move(item.path, destination),
          TrashAction() => await _ops.trash(item.path),
        };
        _stability.forget(item.path);
        out.add(ActionResult(planned: item, time: _clock(), resultPath: resultPath));
      } on Object catch (e) {
        _suppressed[item.path] = (size: stat.size, modified: stat.modified);
        out.add(ActionResult(planned: item, time: _clock(), error: e));
      }
    }
    if (out.isNotEmpty) _results.add(out);
    return out;
  }

  /// 감시를 시작한다. 시작 직후 한 번 훑고, 이후에는 폴더에 변화가 있을 때만 깨어난다.
  Future<void> start() async {
    if (isRunning) return;
    _dirty = true;
    _timer = Timer.periodic(tick, (_) => _onTick());
    await _syncWatchers();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    for (final w in _watchers.values) {
      await w.cancel();
    }
    _watchers.clear();
  }

  Future<void> dispose() async {
    await stop();
    await _results.close();
    await _errors.close();
  }

  Future<void> _syncWatchers() async {
    final wanted = {for (final r in _rules.where((r) => r.enabled)) _folderOf(r)};
    for (final gone in _watchers.keys.where((f) => !wanted.contains(f)).toList()) {
      await _watchers.remove(gone)!.cancel();
    }
    for (final folder in wanted.where((f) => !_watchers.containsKey(f))) {
      try {
        _watchers[folder] = Directory(folder).watch().listen(
          (_) => _dirty = true,
          onError: (Object e) => _errors.add(e),
        );
      } on FileSystemException catch (e) {
        _errors.add(e);
      }
    }
    _dirty = true;
  }

  Future<void> _onTick() async {
    if (!_dirty || _busy) return;
    _busy = true;
    try {
      _dirty = false;
      final plan = await this.plan(requireStable: true);
      final done = await apply(plan.actions);
      // 기다리는 파일이 있거나 건너뛴 것이 있으면 변화 알림이 없어도 다시 본다.
      if (plan.waiting > 0 || done.length < plan.actions.length) _dirty = true;
    } on Object catch (e) {
      _errors.add(e);
    } finally {
      _busy = false;
    }
  }
}
