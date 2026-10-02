import 'package:flutter_test/flutter_test.dart';
import 'package:stevedore/rules/rule.dart';

void main() {
  final now = DateTime(2026, 10, 1, 12);
  FileFacts file(String name, {int size = 100, Duration age = Duration.zero}) =>
      FileFacts(name: name, sizeBytes: size, modified: now.subtract(age));

  group('RuleCondition', () {
    test('조건이 하나도 없으면 아무 것도 고르지 않는다', () {
      expect(const RuleCondition().matches(file('a.pdf'), now: now), isFalse);
      expect(const RuleCondition(nameContains: '').matches(file('a.pdf'), now: now), isFalse);
    });

    test('확장자는 대소문자와 점을 가리지 않고, 겹 확장자도 맞는다', () {
      const c = RuleCondition(extensions: ['.PDF', 'tar.gz']);
      expect(c.matches(file('Report.pdf'), now: now), isTrue);
      expect(c.matches(file('REPORT.PDF'), now: now), isTrue);
      expect(c.matches(file('backup.tar.gz'), now: now), isTrue);
      expect(c.matches(file('backup.gz'), now: now), isFalse);
      expect(c.matches(file('pdf'), now: now), isFalse);
    });

    test('이름 포함은 대소문자를 가리지 않는다', () {
      const c = RuleCondition(nameContains: 'invoice');
      expect(c.matches(file('2026-INVOICE-03.pdf'), now: now), isTrue);
      expect(c.matches(file('receipt.pdf'), now: now), isFalse);
    });

    test('크기 범위는 경계를 포함한다', () {
      const c = RuleCondition(minSizeBytes: 100, maxSizeBytes: 200);
      expect(c.matches(file('a', size: 99), now: now), isFalse);
      expect(c.matches(file('a', size: 100), now: now), isTrue);
      expect(c.matches(file('a', size: 200), now: now), isTrue);
      expect(c.matches(file('a', size: 201), now: now), isFalse);
    });

    test('경과 일수는 정확히 N일이면 일치한다', () {
      const c = RuleCondition(olderThanDays: 30);
      expect(c.matches(file('a', age: const Duration(days: 29, hours: 23)), now: now), isFalse);
      expect(c.matches(file('a', age: const Duration(days: 30)), now: now), isTrue);
    });

    test('여러 조건은 모두 만족해야 한다', () {
      const c = RuleCondition(extensions: ['zip'], olderThanDays: 7);
      expect(c.matches(file('a.zip', age: const Duration(days: 8)), now: now), isTrue);
      expect(c.matches(file('a.zip', age: const Duration(days: 1)), now: now), isFalse);
      expect(c.matches(file('a.txt', age: const Duration(days: 8)), now: now), isFalse);
    });
  });

  group('Rule', () {
    const rule = Rule(
      id: 'r1',
      name: 'PDF 정리',
      watchedFolder: '~/Downloads',
      condition: RuleCondition(extensions: ['pdf']),
      action: MoveAction('~/Documents/PDF'),
    );

    test('꺼진 규칙은 일치하지 않는다', () {
      expect(rule.matches(file('a.pdf'), now: now), isTrue);
      expect(rule.copyWith(enabled: false).matches(file('a.pdf'), now: now), isFalse);
    });

    test('JSON으로 왕복해도 같다', () {
      final back = Rule.fromJson(rule.toJson());
      expect(back.toJson(), rule.toJson());
      expect(back.action, isA<MoveAction>());
      expect(Rule.fromJson(const Rule(
        id: 'r2',
        name: '오래된 zip',
        watchedFolder: '~/Downloads',
        condition: RuleCondition(extensions: ['zip'], olderThanDays: 30, maxSizeBytes: 5000),
        action: TrashAction(),
        enabled: false,
      ).toJson()).toJson()['action'], {'type': 'trash'});
    });

    test('알 수 없는 동작은 거부한다', () {
      expect(() => RuleAction.fromJson({'type': 'delete-forever'}), throwsFormatException);
    });
  });

  test('includeSubfolders는 저장되고, 없으면 꺼짐', () {
    const base = Rule(
      id: '1',
      name: 'n',
      watchedFolder: '~/D',
      condition: RuleCondition(extensions: ['pdf']),
      action: TrashAction(),
    );
    expect(Rule.fromJson(base.toJson()).includeSubfolders, isFalse);
    expect(Rule.fromJson(base.copyWith(includeSubfolders: true).toJson()).includeSubfolders, isTrue);
  });
}
