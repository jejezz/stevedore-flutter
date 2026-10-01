import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stevedore/rules/rule.dart';
import 'package:stevedore/rules/rule_store.dart';

void main() {
  late Directory dir;
  late RuleStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('stevedore_rules_');
    store = RuleStore(Directory('${dir.path}/Stevedore'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  const sample = Rule(
    id: 'r1',
    name: '이미지 정리',
    watchedFolder: '~/Downloads',
    condition: RuleCondition(extensions: ['png', 'jpg'], minSizeBytes: 1024),
    action: MoveAction('~/Pictures/Downloads'),
  );

  test('파일이 없으면 빈 목록', () async {
    expect(await store.load(), isEmpty);
  });

  test('저장한 규칙을 그대로 읽는다 (폴더가 없어도 만든다)', () async {
    await store.save([sample, sample.copyWith(name: '두 번째', enabled: false)]);
    final loaded = await store.load();
    expect(loaded.map((r) => r.toJson()), [
      sample.toJson(),
      sample.copyWith(name: '두 번째', enabled: false).toJson(),
    ]);
  });

  test('저장하면 임시 파일이 남지 않는다', () async {
    await store.save([sample]);
    final names = store.directory.listSync().map((e) => e.uri.pathSegments.last).toList();
    expect(names, [RuleStore.fileName]);
  });

  test('깨진 파일은 .bak으로 옮기고 빈 목록으로 시작한다', () async {
    await store.directory.create(recursive: true);
    final file = File('${store.directory.path}/${RuleStore.fileName}');
    await file.writeAsString('{ not json');
    expect(await store.load(), isEmpty);
    expect(await file.exists(), isFalse);
    expect(await File('${file.path}.bak').readAsString(), '{ not json');
  });
}
