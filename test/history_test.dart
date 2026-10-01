import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stevedore/engine/file_ops.dart';
import 'package:stevedore/engine/history.dart';
import 'package:stevedore/engine/tidy_engine.dart';
import 'package:stevedore/engine/tidy_service.dart';
import 'package:stevedore/rules/rule.dart';
import 'package:stevedore/rules/rule_store.dart';

class _Ops implements FileOps {
  /// 휴지통 흉내: 임시 폴더로 옮기고 그 경로를 돌려준다.
  _Ops(this.fakeTrash);
  final Directory fakeTrash;

  @override
  Future<String> move(String src, String destDir, {String? asName}) =>
      SystemFileOps().move(src, destDir, asName: asName);

  @override
  Future<String?> trash(String path) => move(path, fakeTrash.path);
}

void main() {
  late Directory root;
  late Directory downloads;
  late Directory out;
  late TidyEngine engine;

  Rule rule(RuleAction action, {String ext = 'txt'}) => Rule(
        id: 'r',
        name: '규칙',
        watchedFolder: downloads.path,
        condition: RuleCondition(extensions: [ext]),
        action: action,
      );

  File put(String name, [String body = 'data']) => File('${downloads.path}/$name')..writeAsStringSync(body);

  setUp(() {
    root = Directory.systemTemp.createTempSync('stevedore_history_');
    downloads = Directory('${root.path}/Downloads')..createSync();
    out = Directory('${root.path}/out')..createSync();
    engine = TidyEngine(ops: _Ops(Directory('${root.path}/trash')..createSync()), settle: Duration.zero);
  });
  tearDown(() async {
    await engine.dispose();
    root.deleteSync(recursive: true);
  });

  group('HistoryStore', () {
    test('저장한 기록을 그대로 읽고, 최근 500개만 남긴다', () async {
      final store = HistoryStore(Directory('${root.path}/Stevedore'));
      expect(await store.load(), isEmpty);
      HistoryEntry e(int i) => HistoryEntry(
            id: '$i',
            time: DateTime(2026, 10, 1, 12, 0, i % 60),
            ruleId: 'r',
            ruleName: '규칙',
            kind: HistoryKind.move,
            fileName: 'a$i.txt',
            sourcePath: '/in/a$i.txt',
            resultPath: '/out/a$i.txt',
          );
      await store.save([for (var i = 0; i < 600; i++) e(i)]);
      final loaded = await store.load();
      expect(loaded.length, HistoryStore.maxEntries);
      expect(loaded.first.toJson(), e(0).toJson());
    });
  });

  group('되돌리기', () {
    test('이동한 파일을 원래 폴더·이름으로 돌려놓고, 규칙이 다시 옮기지 않는다', () async {
      put('a.txt', 'hello');
      await engine.setRules([rule(MoveAction(out.path))]);
      final done = await engine.apply((await engine.plan(requireStable: false)).actions);
      final entry = HistoryEntry(
        id: '1',
        time: DateTime.now(),
        ruleId: 'r',
        ruleName: '규칙',
        kind: HistoryKind.move,
        fileName: 'a.txt',
        sourcePath: done.single.planned.path,
        resultPath: done.single.resultPath,
      );
      expect(File('${downloads.path}/a.txt').existsSync(), isFalse);

      final restored = await engine.undo(entry);
      expect(restored, '${downloads.path}/a.txt');
      expect(File(restored).readAsStringSync(), 'hello');
      expect(File('${out.path}/a.txt').existsSync(), isFalse);
      // 되돌린 파일은 계속 규칙에 맞지만 다시 계획에 오르지 않는다.
      expect((await engine.plan(requireStable: false)).actions, isEmpty);
    });

    test('원래 자리에 같은 이름이 새로 생겼으면 번호를 붙여 돌려놓는다', () async {
      put('a.txt', 'v1');
      await engine.setRules([rule(MoveAction(out.path))]);
      final done = await engine.apply((await engine.plan(requireStable: false)).actions);
      put('a.txt', 'v2'); // 그 사이 같은 이름의 새 파일
      final entry = HistoryEntry(
        id: '1',
        time: DateTime.now(),
        ruleId: 'r',
        ruleName: '규칙',
        kind: HistoryKind.move,
        fileName: 'a.txt',
        sourcePath: done.single.planned.path,
        resultPath: done.single.resultPath,
      );
      final restored = await engine.undo(entry);
      expect(restored, '${downloads.path}/a (1).txt');
      expect(File('${downloads.path}/a.txt').readAsStringSync(), 'v2');
      expect(File(restored).readAsStringSync(), 'v1');
    });

    test('옮긴 파일이 없어졌으면 실패하고 되돌릴 수 없는 기록은 거부한다', () async {
      final gone = HistoryEntry(
        id: '1',
        time: DateTime.now(),
        ruleId: 'r',
        ruleName: '규칙',
        kind: HistoryKind.move,
        fileName: 'a.txt',
        sourcePath: '${downloads.path}/a.txt',
        resultPath: '${out.path}/nope.txt',
      );
      expect(engine.undo(gone), throwsA(isA<FileSystemException>()));
      final noPath = HistoryEntry(
        id: '2',
        time: DateTime.now(),
        ruleId: 'r',
        ruleName: '규칙',
        kind: HistoryKind.trash,
        fileName: 'a.txt',
        sourcePath: '${downloads.path}/a.txt',
      );
      expect(noPath.canUndo, isFalse);
      expect(engine.undo(noPath), throwsStateError);
    });
  });

  test('실패한 동작은 파일이 바뀔 때까지 되풀이하지 않는다', () async {
    final f = put('a.txt');
    await engine.setRules([rule(MoveAction('${f.path}/not-a-dir'))]); // 파일 아래라 폴더를 만들 수 없음
    final first = await engine.apply((await engine.plan(requireStable: false)).actions);
    expect(first.single.succeeded, isFalse);
    expect((await engine.plan(requireStable: false)).actions, isEmpty);
    f.writeAsStringSync('changed');
    expect((await engine.plan(requireStable: false)).actions, hasLength(1));
  });

  test('수동 정리는 방금 바뀐 파일을 건너뛴다', () async {
    final e = TidyEngine(ops: _Ops(Directory('${root.path}/t2')), settle: const Duration(seconds: 5));
    addTearDown(e.dispose);
    final f = put('a.txt');
    await e.setRules([rule(MoveAction(out.path))]);
    var plan = await e.plan(requireStable: false);
    expect((plan.actions.length, plan.waiting), (0, 1));
    f.setLastModifiedSync(DateTime.now().subtract(const Duration(minutes: 1)));
    plan = await e.plan(requireStable: false);
    expect((plan.actions.length, plan.waiting), (1, 0));
  });

  group('TidyService', () {
    test('실행 결과를 기록으로 남기고, 되돌리면 기록에 표시하며 재시작 뒤에도 유지한다', () async {
      final support = Directory('${root.path}/Stevedore');
      final ruleStore = RuleStore(support);
      final historyStore = HistoryStore(support);
      await ruleStore.save([rule(MoveAction(out.path))]);
      put('a.txt', 'hello').setLastModifiedSync(DateTime.now().subtract(const Duration(minutes: 1)));

      var service = TidyService(engine: engine, ruleStore: ruleStore, historyStore: historyStore);
      await service.init();
      await engine.stop(); // 자동 감시는 끄고 수동 경로만 시험
      final plan = await service.preview();
      expect(plan.actions, hasLength(1));
      await service.run(plan);
      await Future<void>.delayed(const Duration(milliseconds: 50)); // results 스트림 전달

      expect(service.history, hasLength(1));
      final entry = service.history.single;
      expect((entry.fileName, entry.kind, entry.succeeded, entry.canUndo), ('a.txt', HistoryKind.move, true, true));

      await service.undo(entry);
      expect(service.history.single.undone, isTrue);
      expect(File('${downloads.path}/a.txt').readAsStringSync(), 'hello');
      await engine.dispose();

      // 재시작: 기록이 남아 있고, 되돌린 파일은 새 엔진이 다시 옮기지 않는다.
      engine = TidyEngine(ops: _Ops(Directory('${root.path}/trash2')..createSync()), settle: Duration.zero);
      service = TidyService(engine: engine, ruleStore: ruleStore, historyStore: historyStore);
      await service.init();
      await engine.stop();
      expect(service.history.single.undone, isTrue);
      expect((await engine.plan(requireStable: false)).actions, isEmpty);
    });
  });
}
