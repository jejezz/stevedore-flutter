import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stevedore/rules/presets.dart';
import 'package:stevedore/rules/rule.dart';
import 'package:stevedore/system/login_item.dart';

void main() {
  group('MacLoginItem', () {
    late Directory home;
    setUp(() => home = Directory.systemTemp.createTempSync('stevedore_login_'));
    tearDown(() => home.deleteSync(recursive: true));

    MacLoginItem item([String app = '/Applications/Stevedore.app']) =>
        MacLoginItem(home: home.path, appBundlePath: app);

    test('켜면 LaunchAgent를 만들고 --background로 실행하게 하며, 끄면 지운다', () async {
      final login = item();
      expect(await login.isEnabled(), isFalse);
      await login.setEnabled(true);
      expect(await login.isEnabled(), isTrue);
      final plist = File('${home.path}/Library/LaunchAgents/art.zoomon.stevedore.plist').readAsStringSync();
      expect(plist, contains('<string>/Applications/Stevedore.app</string>'));
      expect(plist, contains('<string>--background</string>'));
      expect(plist, contains('<key>RunAtLoad</key>'));
      await login.setEnabled(false);
      expect(await login.isEnabled(), isFalse);
      await login.setEnabled(false); // 이미 꺼져 있어도 오류가 아니다
    });

    test('앱을 옮겼으면 켜져 있을 때만 새 경로로 고친다', () async {
      await item('/old/Stevedore.app').refresh();
      expect(await item().isEnabled(), isFalse); // 꺼져 있으면 만들지 않는다
      await item('/old/Stevedore.app').setEnabled(true);
      await item('/new/Stevedore.app').refresh();
      final plist = File('${home.path}/Library/LaunchAgents/art.zoomon.stevedore.plist').readAsStringSync();
      expect(plist, contains('/new/Stevedore.app'));
      expect(plist, isNot(contains('/old/')));
    });

    test('경로의 특수문자는 이스케이프한다', () {
      expect(item('/Apps/A&B <x>.app').plistContent(), contains('/Apps/A&amp;B &lt;x&gt;.app'));
    });
  });

  group('WindowsLoginItem', () {
    test('reg add/query/delete를 올바른 인자로 부른다', () async {
      final calls = <List<String>>[];
      var registered = false;
      Future<ProcessResult> run(String exe, List<String> args) async {
        calls.add([exe, ...args]);
        switch (args.first) {
          case 'add':
            registered = true;
            return ProcessResult(0, 0, '', '');
          case 'delete':
            final ok = registered;
            registered = false;
            return ProcessResult(0, ok ? 0 : 1, '', '');
          default:
            return ProcessResult(0, registered ? 0 : 1, registered ? r'"C:\App\stevedore.exe" --background' : '', '');
        }
      }

      final login = WindowsLoginItem(run: run, executable: r'C:\App\stevedore.exe');
      expect(await login.isEnabled(), isFalse);
      await login.setEnabled(true);
      expect(calls.firstWhere((c) => c[1] == 'add'), [
        'reg', 'add', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run', '/v', 'Stevedore',
        '/t', 'REG_SZ', '/d', r'"C:\App\stevedore.exe" --background', '/f',
      ]);
      expect(await login.isEnabled(), isTrue);
      await login.setEnabled(false);
      expect(await login.isEnabled(), isFalse);
      await login.setEnabled(false); // 없는 값을 지워도 오류가 아니다
    });

    test('등록된 경로가 다르면 refresh가 다시 쓴다', () async {
      final calls = <String>[];
      Future<ProcessResult> run(String exe, List<String> args) async {
        calls.add(args.first);
        return ProcessResult(0, 0, r'"C:\Old\stevedore.exe" --background', '');
      }

      await WindowsLoginItem(run: run, executable: r'C:\New\stevedore.exe').refresh();
      expect(calls, contains('add'));
    });
  });

  test('LoginItemController는 백엔드가 없으면 지원하지 않는다고 답한다', () async {
    final c = LoginItemController(null);
    await c.init();
    expect((c.supported, c.enabled), (false, false));
  });

  group('RulePreset', () {
    test('이동 규칙은 감시 폴더 안 하위 폴더로 보내고, 휴지통 규칙만 휴지통으로 보낸다', () {
      for (final p in RulePreset.values) {
        final r = p.build(id: p.name, name: p.name, folderName: '폴더');
        expect(r.watchedFolder, '~/Downloads');
        if (p.trash) {
          expect(r.action, isA<TrashAction>());
          expect(r.condition.olderThanDays, isNotNull); // 나이 조건 없이 휴지통 규칙이 되는 일은 없다
        } else {
          expect((r.action as MoveAction).destination, '~/Downloads/폴더');
        }
        expect(r.condition.isEmpty, isFalse);
      }
    });

    test('같은 확장자가 이동 규칙과 휴지통 규칙에 걸리면 휴지통(오래된 것)이 먼저 온다', () {
      expect(RulePreset.values.first, RulePreset.oldInstallers);
    });

    test('문서 규칙은 확장자를 대소문자와 상관없이 맞춘다', () {
      final r = RulePreset.documents.build(id: 'd', name: '문서', folderName: '문서');
      final now = DateTime(2026, 10, 1);
      final file = FileFacts(name: 'Report.PDF', sizeBytes: 10, modified: now);
      expect(r.matches(file, now: now), isTrue);
    });
  });
}
