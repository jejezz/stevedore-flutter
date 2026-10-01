// From jejezz/application-release-templates common/ @ conventions-v1.
//
// 새 앱의 시작점. 규약이 요구하는 연결을 한곳에 모았다:
//   창 크기(window_manager) · 추가 라이선스 · 설정 로드 · 라이트/다크 ·
//   언어 해석 · macOS 앱 메뉴 About · 앱 바 [테마 | 언어 | 정보] · 빈 상태.
// 기존 앱에는 통째로 덮어쓰지 말고 필요한 부분만 옮긴다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'about/about_dialog.dart';
import 'about/app_menu_bar.dart';
import 'about/extra_licenses.dart';
import 'app_identity.dart';
import 'l10n/app_localizations.dart';
import 'settings/app_settings.dart';
import 'theme/app_theme.dart';
import 'engine/history.dart';
import 'engine/tidy_engine.dart';
import 'engine/tidy_service.dart';
import 'rules/rule_store.dart';
import 'tray/tray_controller.dart';
import 'ui/home_screen.dart';

final bool _isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerExtraLicenses();

  if (_isDesktop) {
    await windowManager.ensureInitialized();
    // ui-ux.md §5: 최소 크기는 960×600 이하 (1366×768 노트북).
    const options = WindowOptions(
      size: Size(960, 640),
      minimumSize: Size(800, 560),
      center: true,
      title: AppIdentity.displayName,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final settings = await AppSettings.load();
  runApp(App(settings: settings, service: await _startService()));
}

/// 저장된 규칙으로 감시를 시작한다. 규칙이 없으면 감시할 폴더도 없다.
Future<TidyService> _startService() async {
  final service = TidyService(
    engine: TidyEngine(),
    ruleStore: RuleStore.standard(),
    historyStore: HistoryStore.standard(),
  );
  await service.init();
  return service;
}

class App extends StatefulWidget {
  const App({super.key, required this.settings, required this.service});

  final AppSettings settings;
  final TidyService service;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _homeKey = GlobalKey<HomeScreenState>();
  TrayController? _tray;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      _tray = TrayController(
        settings: widget.settings,
        onAbout: () async => _showAbout(),
        onTidyNow: () async => _homeKey.currentState?.tidyNow(),
      );
      _tray!.init();
    }
    WidgetsBinding.instance.addObserver(this);
    widget.settings.addListener(_syncWindowBrightness);
    _syncWindowBrightness();
  }

  @override
  void dispose() {
    widget.settings.removeListener(_syncWindowBrightness);
    _tray?.dispose();
    widget.service.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 앱에서 다크를 골라도 OS가 라이트면 제목 표시줄은 밝게 남는다 (theming.md §4).
  @override
  void didChangePlatformBrightness() => _syncWindowBrightness();

  void _syncWindowBrightness() {
    if (!_isDesktop || Platform.isLinux) return;
    final brightness = switch (widget.settings.themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness,
    };
    windowManager.setBrightness(brightness);
  }

  void _showAbout() {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    final l10n = AppLocalizations.of(context);
    showAppAboutDialog(context, tagline: l10n.aboutTagline, description: l10n.aboutDescription);
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: widget.settings,
      child: ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) => MaterialApp(
          navigatorKey: _navigatorKey,
          title: AppIdentity.displayName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(dense: _isDesktop),
          darkTheme: AppTheme.dark(dense: _isDesktop),
          themeMode: widget.settings.themeMode,
          locale: widget.settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: AppSettings.resolveLocale,
          builder: (context, child) => AppMenuBar(onAbout: _showAbout, child: child!),
          home: HomeScreen(key: _homeKey, onAbout: _showAbout, service: widget.service),
        ),
      ),
    );
  }
}
