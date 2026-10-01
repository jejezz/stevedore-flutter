import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stevedore/engine/history.dart';
import 'package:stevedore/engine/tidy_engine.dart';
import 'package:stevedore/engine/tidy_service.dart';
import 'package:stevedore/l10n/app_localizations.dart';
import 'package:stevedore/rules/rule.dart';
import 'package:stevedore/rules/rule_store.dart';
import 'package:stevedore/ui/rule_editor.dart';
import 'package:stevedore/ui/rule_formatting.dart';

void main() {
  late Directory root;
  late TidyService service;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('stevedore_ui_');
    final support = Directory('${root.path}/Stevedore');
    service = TidyService(engine: TidyEngine(), ruleStore: RuleStore(support), historyStore: HistoryStore(support));
    await service.init();
    await service.engine.stop();
  });
  tearDown(() async {
    await service.engine.dispose();
    root.deleteSync(recursive: true);
  });

  Rule rule(String id, {bool enabled = true}) => Rule(
        id: id,
        name: id,
        enabled: enabled,
        watchedFolder: '${root.path}/in',
        condition: const RuleCondition(extensions: ['txt']),
        action: const TrashAction(),
      );

  group('TidyService 규칙 관리', () {
    test('추가·수정·끄기·삭제가 저장되고 순서 바꾸기가 우선순위를 바꾼다', () async {
      await service.saveRule(rule('a'));
      await service.saveRule(rule('b'));
      await service.saveRule(rule('c'));
      await service.saveRule(rule('b').copyWith(name: 'B2'));
      expect(service.rules.map((r) => r.name), ['a', 'B2', 'c']);

      await service.setRuleEnabled('a', false);
      await service.reorderRules(2, 0); // c를 맨 위로
      expect(service.rules.map((r) => r.id), ['c', 'a', 'b']);
      await service.deleteRule('b');

      final reloaded = await RuleStore(Directory('${root.path}/Stevedore')).load();
      expect(reloaded.map((r) => (r.id, r.enabled)), [('c', true), ('a', false)]);
      expect(service.engine.rules.map((r) => r.id), ['c', 'a']);
    });

    test('previewRule은 저장하지 않은 규칙으로 맞는 파일을 보여준다', () async {
      final dir = Directory('${root.path}/in')..createSync();
      File('${dir.path}/a.txt')
        ..writeAsStringSync('x')
        ..setLastModifiedSync(DateTime.now().subtract(const Duration(minutes: 5)));
      File('${dir.path}/b.pdf').writeAsStringSync('x');
      final plan = await service.previewRule(rule('draft', enabled: false));
      expect(plan.actions.map((a) => a.facts.name), ['a.txt']);
      expect(service.rules, isEmpty);
    });
  });

  group('rule_formatting', () {
    test('크기 표기', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1024), '1 KB');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(5 * 1024 * 1024), '5 MB');
    });
  });

  group('규칙 편집기', () {
    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showRuleEditor(context, service),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
    }

    testWidgets('비워 둔 채 저장하면 안내하고 닫히지 않는다', (tester) async {
      await open(tester);
      await tester.tap(find.text('저장'));
      await tester.pump();
      expect(find.text('규칙 이름을 입력하세요'), findsOneWidget);
      expect(find.text('새 규칙'), findsOneWidget);
    });

    testWidgets('조건이 없으면 거부하고, 같은 폴더로 이동도 거부한다', (tester) async {
      await open(tester);
      await tester.enterText(find.widgetWithText(TextField, '규칙 이름'), '내 규칙');
      await tester.tap(find.text('저장'));
      await tester.pump();
      expect(find.text('조건을 하나 이상 지정하세요'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, '확장자'), 'pdf');
      await tester.enterText(find.widgetWithText(TextField, '이동할 폴더'), '~/Downloads/');
      await tester.tap(find.text('저장'));
      await tester.pump();
      expect(find.text('이동할 폴더가 감시 폴더와 같습니다'), findsOneWidget);
    });

    testWidgets('입력한 값으로 규칙을 만들어 돌려준다', (tester) async {
      Rule? saved;
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => saved = await showRuleEditor(context, service),
            child: const Text('열기'),
          ),
        ),
      ));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, '규칙 이름'), 'PDF 정리');
      await tester.enterText(find.widgetWithText(TextField, '확장자'), '.PDF, docx  pdf');
      await tester.enterText(find.widgetWithText(TextField, '최소 크기'), '1.5');
      await tester.enterText(find.widgetWithText(TextField, '경과 일수'), '30');
      await tester.enterText(find.widgetWithText(TextField, '이동할 폴더'), '~/Documents/PDF');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.name, 'PDF 정리');
      expect(saved!.watchedFolder, '~/Downloads');
      expect(saved!.condition.extensions, ['pdf', 'docx']);
      expect(saved!.condition.minSizeBytes, (1.5 * 1024 * 1024).round());
      expect(saved!.condition.olderThanDays, 30);
      expect((saved!.action as MoveAction).destination, '~/Documents/PDF');
      expect(saved!.enabled, isTrue);
    });
  });
}
