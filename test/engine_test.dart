import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stevedore/engine/file_ops.dart';
import 'package:stevedore/engine/ignored_files.dart';
import 'package:stevedore/engine/paths.dart';
import 'package:stevedore/engine/stability_tracker.dart';
import 'package:stevedore/engine/tidy_engine.dart';
import 'package:stevedore/rules/rule.dart';

class _FakeOps implements FileOps {
  final trashed = <String>[];

  @override
  Future<String> move(String src, String destDir, {String? asName}) =>
      SystemFileOps().move(src, destDir, asName: asName);

  @override
  Future<String?> trash(String path) async {
    trashed.add(path);
    File(path).deleteSync();
    return '/fake-trash/$path';
  }
}

void main() {
  group('expandPath', () {
    const env = {'HOME': '/Users/me'};
    test('~를 홈으로 풀고 끝 구분자를 없앤다', () {
      expect(expandPath('~', env: env), '/Users/me');
      expect(expandPath('~/Downloads/', env: env), '/Users/me/Downloads');
      expect(expandPath('/tmp/x', env: env), '/tmp/x');
    });
  });

  group('isIgnoredFileName', () {
    test('받는 중·숨김·OS 파일은 제외', () {
      for (final n in ['a.crdownload', 'B.PART', 'c.download', '.DS_Store', '~\$doc.docx', 'Thumbs.db', 'x.tmp']) {
        expect(isIgnoredFileName(n), isTrue, reason: n);
      }
      for (final n in ['a.pdf', 'download.zip', 'part1.txt']) {
        expect(isIgnoredFileName(n), isFalse, reason: n);
      }
    });
  });

  group('StabilityTracker', () {
    final t0 = DateTime(2026, 10, 1, 12);
    final m = DateTime(2026, 10, 1, 11);

    test('처음 본 파일은 불안정, settle 동안 같으면 안정', () {
      final t = StabilityTracker(settle: const Duration(seconds: 5));
      expect(t.isStable('a', size: 10, modified: m, now: t0), isFalse);
      expect(t.isStable('a', size: 10, modified: m, now: t0.add(const Duration(seconds: 4))), isFalse);
      expect(t.isStable('a', size: 10, modified: m, now: t0.add(const Duration(seconds: 5))), isTrue);
    });

    test('크기가 바뀌면 다시 처음부터 센다', () {
      final t = StabilityTracker(settle: const Duration(seconds: 5));
      t.isStable('a', size: 10, modified: m, now: t0);
      expect(t.isStable('a', size: 20, modified: m, now: t0.add(const Duration(seconds: 6))), isFalse);
      expect(t.isStable('a', size: 20, modified: m, now: t0.add(const Duration(seconds: 11))), isTrue);
    });
  });

  group('uniquePath', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('stevedore_unique_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('같은 이름이 있으면 번호를 붙인다 (겹 확장자 포함)', () async {
      expect(await uniquePath(dir.path, 'a.pdf'), '${dir.path}/a.pdf');
      File('${dir.path}/a.pdf').writeAsStringSync('x');
      expect(await uniquePath(dir.path, 'a.pdf'), '${dir.path}/a (1).pdf');
      File('${dir.path}/a (1).pdf').writeAsStringSync('x');
      expect(await uniquePath(dir.path, 'a.pdf'), '${dir.path}/a (2).pdf');
      File('${dir.path}/b.tar.gz').writeAsStringSync('x');
      expect(await uniquePath(dir.path, 'b.tar.gz'), '${dir.path}/b (1).tar.gz');
    });
  });

  group('TidyEngine', () {
    late Directory root;
    late Directory downloads;
    late _FakeOps ops;
    var now = DateTime.now();

    Rule moveRule(String id, List<String> ext, String dest, {int? olderThanDays}) => Rule(
          id: id,
          name: id,
          watchedFolder: downloads.path,
          condition: RuleCondition(extensions: ext, olderThanDays: olderThanDays),
          action: MoveAction(dest),
        );

    File put(String name, {String body = 'data', Duration age = Duration.zero}) {
      final f = File('${downloads.path}/$name')..writeAsStringSync(body);
      f.setLastModifiedSync(DateTime.now().subtract(age));
      return f;
    }

    setUp(() {
      root = Directory.systemTemp.createTempSync('stevedore_engine_');
      downloads = Directory('${root.path}/Downloads')..createSync();
      ops = _FakeOps();
      now = DateTime.now();
    });
    tearDown(() => root.deleteSync(recursive: true));

    TidyEngine engine({Duration settle = Duration.zero}) =>
        TidyEngine(ops: ops, settle: settle, clock: () => now);

    test('처음 맞는 규칙 하나만 적용하고, 꺼진 규칙·무관한 파일은 건드리지 않는다', () async {
      put('a.pdf');
      put('b.txt');
      final e = engine();
      await e.setRules([
        moveRule('off', ['pdf'], '${root.path}/off').copyWith(enabled: false),
        moveRule('first', ['pdf'], '${root.path}/first'),
        moveRule('second', ['pdf', 'txt'], '${root.path}/second'),
      ]);
      final plan = await e.plan(requireStable: false);
      expect({for (final a in plan.actions) a.facts.name: a.rule.id}, {'a.pdf': 'first', 'b.txt': 'second'});
    });

    test('임시 파일·숨김 파일·하위 폴더·링크는 계획에서 빠진다', () async {
      put('a.pdf.crdownload');
      put('.hidden.pdf');
      put('real.pdf');
      Directory('${downloads.path}/sub.pdf').createSync();
      File('${downloads.path}/sub.pdf/inner.pdf').writeAsStringSync('x');
      Link('${downloads.path}/link.pdf').createSync('${downloads.path}/real.pdf');
      final e = engine();
      await e.setRules([moveRule('r', ['pdf', 'crdownload'], '${root.path}/out')]);
      final plan = await e.plan(requireStable: false);
      expect(plan.actions.map((a) => a.facts.name), ['real.pdf']);
    });

    test('requireStable이면 처음엔 기다리고 settle이 지나면 계획한다', () async {
      put('a.pdf');
      final e = engine(settle: const Duration(seconds: 5));
      await e.setRules([moveRule('r', ['pdf'], '${root.path}/out')]);
      var plan = await e.plan(requireStable: true);
      expect((plan.actions.length, plan.waiting), (0, 1));
      now = now.add(const Duration(seconds: 6));
      plan = await e.plan(requireStable: true);
      expect((plan.actions.length, plan.waiting), (1, 0));
    });

    test('이동: 실제로 옮기고, 같은 이름이 있으면 덮어쓰지 않는다', () async {
      final out = Directory('${root.path}/out')..createSync();
      File('${out.path}/a.pdf').writeAsStringSync('old');
      put('a.pdf', body: 'new');
      final e = engine();
      await e.setRules([moveRule('r', ['pdf'], out.path)]);
      final results = await e.apply((await e.plan(requireStable: false)).actions);
      expect(results.single.succeeded, isTrue);
      expect(results.single.resultPath, '${out.path}/a (1).pdf');
      expect(File('${out.path}/a.pdf').readAsStringSync(), 'old');
      expect(File('${out.path}/a (1).pdf').readAsStringSync(), 'new');
      expect(File('${downloads.path}/a.pdf').existsSync(), isFalse);
    });

    test('휴지통: 오래된 파일만 보낸다', () async {
      put('old.zip', age: const Duration(days: 40));
      put('new.zip');
      final e = engine();
      await e.setRules([
        Rule(
          id: 't',
          name: 't',
          watchedFolder: downloads.path,
          condition: const RuleCondition(extensions: ['zip'], olderThanDays: 30),
          action: const TrashAction(),
        ),
      ]);
      final results = await e.apply((await e.plan(requireStable: false)).actions);
      expect(results.map((r) => r.planned.facts.name), ['old.zip']);
      expect(ops.trashed.single, endsWith('old.zip'));
      expect(File('${downloads.path}/new.zip').existsSync(), isTrue);
    });

    test('계획 뒤에 파일이 바뀌었으면 건너뛴다', () async {
      final f = put('a.pdf');
      final e = engine();
      await e.setRules([moveRule('r', ['pdf'], '${root.path}/out')]);
      final plan = await e.plan(requireStable: false);
      f.writeAsStringSync('more data now'); // 받기가 계속되는 상황
      expect(await e.apply(plan.actions), isEmpty);
      expect(f.existsSync(), isTrue);
    });

    test('감시: 새로 생긴 파일을 안정된 뒤 자동으로 옮긴다', () async {
      final out = '${root.path}/out';
      final e = TidyEngine(
        ops: ops,
        settle: const Duration(milliseconds: 300),
        tick: const Duration(milliseconds: 100),
      );
      addTearDown(e.dispose);
      await e.setRules([moveRule('r', ['txt'], out)]);
      await e.start();

      final moved = e.results.first.timeout(const Duration(seconds: 8));
      put('late.txt');
      final results = await moved;
      expect(results.single.planned.facts.name, 'late.txt');
      expect(File('$out/late.txt').existsSync(), isTrue);
      expect(File('${downloads.path}/late.txt').existsSync(), isFalse);
    });

    test('감시 폴더가 없으면 오류를 알리고 멈추지 않는다', () async {
      final e = engine();
      addTearDown(e.dispose);
      final err = e.errors.first.timeout(const Duration(seconds: 3));
      await e.setRules([
        Rule(
          id: 'x',
          name: 'x',
          watchedFolder: '${root.path}/nope',
          condition: const RuleCondition(extensions: ['pdf']),
          action: const TrashAction(),
        ),
      ]);
      await e.plan(requireStable: false);
      expect(await err, isA<FileSystemException>());
    });
  });
}
