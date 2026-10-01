import 'dart:io';
import 'dart:ui';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/app_localizations.dart';
import '../app_identity.dart';
import '../settings/app_settings.dart';
import '../system/login_item.dart';

/// 상주 동작을 맡는다: 트레이/메뉴바 아이콘과 메뉴, 창을 닫으면 숨기기만 하고
/// 앱은 계속 실행한다. 완전히 끝내는 길은 트레이 메뉴의 "종료"뿐이다.
class TrayController with TrayListener, WindowListener {
  TrayController({required this.settings, required this.loginItem, required this.onAbout, required this.onTidyNow});

  final AppSettings settings;
  final LoginItemController loginItem;

  /// 정보 창 열기. 창을 먼저 보여준 뒤 부른다 (about-dialog.md §1: 앱 메뉴가
  /// 없는 상주 앱은 트레이 메뉴가 그 자리를 대신한다).
  final Future<void> Function() onAbout;

  /// "지금 정리": 창을 보여준 뒤 미리보기를 연다.
  final Future<void> Function() onTidyNow;

  static const _keyOpen = 'open';
  static const _keyTidyNow = 'tidy_now';
  static const _keyAbout = 'about';
  static const _keyLogin = 'login_item';
  static const _keyQuit = 'quit';

  Future<void> init() async {
    trayManager.addListener(this);
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/tray/tray_icon.ico' : 'assets/tray/tray_icon.png',
      isTemplate: true, // macOS: 라이트/다크 메뉴바 색을 OS가 맡는다 (icons.md §4).
    );
    settings.addListener(_rebuildMenu);
    loginItem.addListener(_rebuildMenu);
    await _rebuildMenu();
  }

  Future<void> dispose() async {
    settings.removeListener(_rebuildMenu);
    loginItem.removeListener(_rebuildMenu);
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    await trayManager.destroy();
  }

  /// 메뉴는 위젯 트리 밖이라 로케일을 직접 구한다.
  AppLocalizations get _l10n {
    final locale = settings.locale ??
        AppSettings.resolveLocale(PlatformDispatcher.instance.locale, AppLocalizations.supportedLocales);
    return lookupAppLocalizations(locale);
  }

  Future<void> _rebuildMenu() async {
    final l10n = _l10n;
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: _keyOpen, label: l10n.trayOpen),
      MenuItem(key: _keyTidyNow, label: l10n.trayTidyNow),
      MenuItem.separator(),
      if (loginItem.supported)
        MenuItem.checkbox(key: _keyLogin, label: l10n.trayLoginItem, checked: loginItem.enabled),
      MenuItem(key: _keyAbout, label: l10n.aboutMenuItem(AppIdentity.displayName)),
      MenuItem.separator(),
      MenuItem(key: _keyQuit, label: l10n.trayQuit),
    ]));
  }

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  // macOS는 아이콘을 누르면 메뉴, Windows는 왼쪽 클릭이 창 열기, 오른쪽 클릭이 메뉴.
  @override
  void onTrayIconMouseDown() {
    if (Platform.isWindows) {
      showWindow();
    } else {
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case _keyOpen:
        showWindow();
      case _keyTidyNow:
        showWindow().then((_) => onTidyNow());
      case _keyLogin:
        loginItem.setEnabled(!loginItem.enabled);
      case _keyAbout:
        showWindow().then((_) => onAbout());
      case _keyQuit:
        quit();
    }
  }

  /// 창의 닫기 버튼은 숨기기만 한다.
  @override
  void onWindowClose() => windowManager.hide();

  Future<void> quit() async {
    await windowManager.setPreventClose(false);
    await dispose();
    await windowManager.destroy();
  }
}
