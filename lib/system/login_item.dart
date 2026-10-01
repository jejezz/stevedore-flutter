import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// 로그인할 때 앱을 자동으로 실행하는 설정. 켜졌는지는 OS에 등록된 항목 자체가 기준이다
/// (별도 설정 파일을 두지 않는다 — 사용자가 시스템 설정에서 지워도 앞뒤가 맞는다).
abstract class LoginItemBackend {
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);

  /// 이미 켜져 있으면 등록 내용을 지금 실행 중인 앱의 경로로 맞춘다 (앱을 옮긴 경우).
  Future<void> refresh();

  static LoginItemBackend? forPlatform() {
    if (Platform.isMacOS) return MacLoginItem();
    if (Platform.isWindows) return WindowsLoginItem();
    return null;
  }
}

/// 로그인으로 실행됐음을 알리는 인자. 창을 보이지 않고 트레이에서만 시작한다.
const backgroundFlag = '--background';

/// macOS: `~/Library/LaunchAgents`의 LaunchAgent. 인자를 넘길 수 있어서 창 없이 시작시킨다.
class MacLoginItem implements LoginItemBackend {
  MacLoginItem({String? home, String? appBundlePath})
      : _home = home ?? Platform.environment['HOME']!,
        _appBundle = appBundlePath ?? _bundleOf(Platform.resolvedExecutable);

  static const label = 'art.zoomon.stevedore';

  final String _home;
  final String _appBundle;

  File get _plist => File(p.join(_home, 'Library', 'LaunchAgents', '$label.plist'));

  /// `…/Stevedore.app/Contents/MacOS/Stevedore` → `…/Stevedore.app`
  static String _bundleOf(String executable) => p.dirname(p.dirname(p.dirname(executable)));

  @visibleForTesting
  String plistContent() => '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$label</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/bin/open</string>
		<string>-a</string>
		<string>${_xml(_appBundle)}</string>
		<string>--args</string>
		<string>$backgroundFlag</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>LimitLoadToSessionType</key>
	<string>Aqua</string>
</dict>
</plist>
''';

  static String _xml(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  @override
  Future<bool> isEnabled() => _plist.exists();

  @override
  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      await _plist.parent.create(recursive: true);
      await _plist.writeAsString(plistContent());
    } else if (await _plist.exists()) {
      await _plist.delete();
    }
  }

  @override
  Future<void> refresh() async {
    if (!await _plist.exists()) return;
    final wanted = plistContent();
    if (await _plist.readAsString() != wanted) await _plist.writeAsString(wanted);
  }
}

typedef ProcessRunner = Future<ProcessResult> Function(String executable, List<String> arguments);

/// Windows: `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`의 값. 관리자 권한이 필요 없다.
class WindowsLoginItem implements LoginItemBackend {
  WindowsLoginItem({ProcessRunner? run, String? executable})
      : _run = run ?? Process.run,
        _exe = executable ?? Platform.resolvedExecutable;

  static const _key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const _name = 'Stevedore';

  final ProcessRunner _run;
  final String _exe;

  String get _command => '"$_exe" $backgroundFlag';

  @override
  Future<bool> isEnabled() async => (await _run('reg', ['query', _key, '/v', _name])).exitCode == 0;

  @override
  Future<void> setEnabled(bool enabled) async {
    final result = enabled
        ? await _run('reg', ['add', _key, '/v', _name, '/t', 'REG_SZ', '/d', _command, '/f'])
        : await _run('reg', ['delete', _key, '/v', _name, '/f']);
    // 지울 값이 원래 없었던 경우는 실패가 아니다.
    if (result.exitCode != 0 && !(enabled == false && !await isEnabled())) {
      throw ProcessException('reg', [], '${result.stderr}', result.exitCode);
    }
  }

  @override
  Future<void> refresh() async {
    final result = await _run('reg', ['query', _key, '/v', _name]);
    if (result.exitCode == 0 && !'${result.stdout}'.contains(_command)) await setEnabled(true);
  }
}

/// 화면과 트레이 메뉴가 같은 상태를 보도록 둘 사이에서 공유하는 켜짐 상태.
class LoginItemController extends ChangeNotifier {
  LoginItemController(this.backend);

  /// 지원하지 않는 플랫폼이면 null.
  final LoginItemBackend? backend;
  bool _enabled = false;

  bool get supported => backend != null;
  bool get enabled => _enabled;

  Future<void> init() async {
    final b = backend;
    if (b == null) return;
    await b.refresh();
    _enabled = await b.isEnabled();
    notifyListeners();
  }

  /// 실패하면 예외를 던지고 상태는 그대로 둔다.
  Future<void> setEnabled(bool value) async {
    await backend!.setEnabled(value);
    _enabled = await backend!.isEnabled();
    notifyListeners();
  }
}
