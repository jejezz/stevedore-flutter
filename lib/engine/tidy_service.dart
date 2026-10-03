import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../rules/rule.dart';
import '../rules/rule_store.dart';
import 'history.dart';
import 'tidy_engine.dart';

/// 화면이 보는 쪽: 규칙, 기록, 감시 오류를 한곳에 모으고 엔진 실행 결과를 기록으로 남긴다.
class TidyService extends ChangeNotifier {
  TidyService({required this.engine, required this.ruleStore, required this.historyStore});

  final TidyEngine engine;
  final RuleStore ruleStore;
  final HistoryStore historyStore;

  List<Rule> _rules = const [];
  List<HistoryEntry> _history = const [];
  Object? _watchError;
  StreamSubscription<List<ActionResult>>? _resultsSub;
  StreamSubscription<Object>? _errorsSub;

  List<Rule> get rules => _rules;

  /// 최신 항목이 앞.
  List<HistoryEntry> get history => _history;

  /// 폴더를 읽지 못하는 등의 마지막 감시 오류. 확인하면 [dismissWatchError]로 지운다.
  Object? get watchError => _watchError;

  Future<void> init() async {
    _rules = await ruleStore.load();
    _history = await historyStore.load();
    _resultsSub = engine.results.listen(_record);
    _errorsSub = engine.errors.listen((e) {
      _watchError = e;
      notifyListeners();
    });
    // 되돌려 놓은 파일을 재시작 뒤에도 규칙이 다시 옮기지 않게 한다.
    for (final h in _history.where((h) => h.undone)) {
      await engine.suppress(h.restoredPath!);
    }
    await engine.setRules(_rules);
    await engine.start();
    notifyListeners();
  }

  /// 규칙을 추가하거나(같은 id가 없을 때) 바꾼다.
  Future<void> saveRule(Rule rule) {
    final list = [..._rules];
    final i = list.indexWhere((r) => r.id == rule.id);
    if (i < 0) {
      list.add(rule);
    } else {
      list[i] = rule;
    }
    return _setRules(list);
  }

  /// 여러 규칙을 한 번에 추가한다 (추천 규칙). 저장과 감시 갱신은 한 번만 한다.
  Future<void> addRules(List<Rule> rules) => _setRules([..._rules, ...rules]);

  Future<void> deleteRule(String id) => _setRules([..._rules.where((r) => r.id != id)]);

  Future<void> setRuleEnabled(String id, bool enabled) =>
      _setRules([for (final r in _rules) r.id == id ? r.copyWith(enabled: enabled) : r]);

  /// 순서가 곧 우선순위다 — 위에 있는 규칙이 먼저 적용된다. [newIndex]는
  /// `ReorderableListView.onReorderItem`이 주는, 뺀 뒤 기준의 값이다.
  Future<void> reorderRules(int oldIndex, int newIndex) {
    final list = [..._rules];
    list.insert(newIndex, list.removeAt(oldIndex));
    return _setRules(list);
  }

  String newRuleId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// 편집 중인 규칙이 지금 어떤 파일에 맞는지. 저장하지 않은 규칙도 볼 수 있다.
  Future<PlanResult> previewRule(Rule rule) =>
      engine.plan(requireStable: false, rules: [rule.copyWith(enabled: true)]);

  Future<void> _setRules(List<Rule> rules) async {
    _rules = List.unmodifiable(rules);
    // 저장·감시 폴더 재동기화는 느릴 수 있으니 화면부터 새 규칙으로 바꾼다.
    notifyListeners();
    await ruleStore.save(_rules);
    await engine.setRules(_rules);
  }

  /// "지금 정리"가 보여줄 미리보기. 파일을 건드리지 않는다.
  Future<PlanResult> preview() => engine.plan(requireStable: false);

  /// 미리보기에서 확인한 계획을 실행한다.
  Future<List<ActionResult>> run(PlanResult plan) => engine.apply(plan.actions);

  /// 기록한 동작을 되돌린다. 실패하면 예외를 던지고 기록은 그대로 둔다.
  Future<void> undo(HistoryEntry entry) async {
    final restored = await engine.undo(entry);
    _history = [for (final h in _history) h.id == entry.id ? h.withRestored(restored) : h];
    await historyStore.save(_history);
    notifyListeners();
  }

  void dismissWatchError() {
    _watchError = null;
    notifyListeners();
  }

  Future<void> _record(List<ActionResult> results) async {
    final entries = [
      for (final r in results)
        HistoryEntry(
          id: '${r.time.microsecondsSinceEpoch}-${_history.length}-${r.planned.path.hashCode}',
          time: r.time,
          ruleId: r.planned.rule.id,
          ruleName: r.planned.rule.name,
          kind: switch (r.planned.action) {
            MoveAction() => HistoryKind.move,
            TrashAction() => HistoryKind.trash,
          },
          fileName: p.basename(r.planned.path),
          sourcePath: r.planned.path,
          resultPath: r.resultPath,
          error: r.error?.toString(),
        ),
    ];
    _history = [...entries.reversed, ..._history].take(HistoryStore.maxEntries).toList();
    await historyStore.save(_history);
    notifyListeners();
  }

  @override
  void dispose() {
    _resultsSub?.cancel();
    _errorsSub?.cancel();
    engine.dispose();
    super.dispose();
  }
}
