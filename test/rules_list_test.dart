import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stevedore/l10n/app_localizations.dart';
import 'package:stevedore/rules/rule.dart';
import 'package:stevedore/ui/rules_list.dart';

void main() {
  Rule rule(String id, String folder, {bool enabled = true}) => Rule(
        id: id,
        name: id,
        enabled: enabled,
        watchedFolder: folder,
        condition: const RuleCondition(extensions: ['txt']),
        action: const TrashAction(),
      );

  Future<void> pump(WidgetTester tester, List<Rule> rules, {void Function(int, int)? onReorder, Set<String> collapsed = const {}, void Function(String, bool)? onToggle}) =>
      tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: RulesList(
              rules: rules,
              onToggle: (_, _) {},
              onEdit: (_) {},
              onDelete: (_) {},
              onReorder: onReorder ?? (_, _) {},
              collapsedFolders: collapsed,
              onToggleFolder: onToggle ?? (_, _) {},
            ),
          ),
        ),
      ));

  testWidgets('감시 폴더별로 묶고 같은 폴더의 다른 표기·끝 구분자는 한 그룹이다', (tester) async {
    await pump(tester, [
      rule('a', '/data/in'),
      rule('b', '/data/out', enabled: false),
      rule('c', '/data/in/'),
    ]);
    expect(find.text('/data/in'), findsOneWidget);
    expect(find.text('/data/out'), findsOneWidget);
    expect(find.text('2 of 2 on'), findsOneWidget);
    expect(find.text('0 of 1 on'), findsOneWidget);
  });

  testWidgets('접어 둔 그룹은 규칙을 숨기고, 헤더를 누르면 토글을 알린다', (tester) async {
    final calls = <(String, bool)>[];
    await pump(tester, [rule('a', '/data/in'), rule('b', '/data/out')],
        collapsed: {'/data/in'}, onToggle: (f, c) => calls.add((f, c)));
    expect(find.text('a'), findsNothing);
    expect(find.text('b'), findsOneWidget);
    await tester.tap(find.text('/data/in'));
    await tester.tap(find.text('/data/out'));
    expect(calls, [('/data/in', false), ('/data/out', true)]);
  });

  testWidgets('그룹 안 순서 변경이 전체 목록 인덱스로 바뀌어 전달된다', (tester) async {
    (int, int)? got;
    // 전체 순서: a(in) x(out) c(in) → in 그룹은 전체 인덱스 0, 2.
    await pump(tester, [rule('a', '/data/in'), rule('x', '/data/out'), rule('c', '/data/in')],
        onReorder: (o, n) => got = (o, n));
    final list = tester.widget<ReorderableListView>(find.byType(ReorderableListView).first);
    list.onReorderItem!(0, 1);
    expect(got, (0, 2));
  });
}
