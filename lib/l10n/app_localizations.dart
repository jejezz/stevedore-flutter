import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @aboutTooltip.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get aboutTooltip;

  /// No description provided for @aboutVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 {version} (빌드 {build})'**
  String aboutVersion(String version, String build);

  /// No description provided for @aboutOpenSourceLicenses.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get aboutOpenSourceLicenses;

  /// No description provided for @aboutRepository.
  ///
  /// In ko, this message translates to:
  /// **'GitHub'**
  String get aboutRepository;

  /// No description provided for @commonClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// No description provided for @aboutMenuItem.
  ///
  /// In ko, this message translates to:
  /// **'{appName} 정보'**
  String aboutMenuItem(String appName);

  /// No description provided for @themeMenuTooltip.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get themeMenuTooltip;

  /// No description provided for @themeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정 따르기'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get themeDark;

  /// No description provided for @languageMenuTooltip.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get languageMenuTooltip;

  /// No description provided for @languageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정 따르기 / System'**
  String get languageSystem;

  /// No description provided for @languageSystemShort.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get languageSystemShort;

  /// No description provided for @aboutTagline.
  ///
  /// In ko, this message translates to:
  /// **'다운로드 폴더를 규칙대로 알아서 정리합니다'**
  String get aboutTagline;

  /// No description provided for @aboutDescription.
  ///
  /// In ko, this message translates to:
  /// **'Stevedore는 다운로드 폴더 같은 곳에 생긴 파일을 확장자, 이름, 크기, 오래된 정도에 따라 자동으로 분류하고 정리합니다. 상주하며 바로 처리하거나, 원할 때 \"지금 정리\"로 직접 실행할 수 있습니다.'**
  String get aboutDescription;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 정리 규칙이 없습니다. 규칙을 추가해 다운로드 폴더 정리를 시작하세요'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyAction.
  ///
  /// In ko, this message translates to:
  /// **'규칙 추가'**
  String get homeEmptyAction;

  /// No description provided for @trayOpen.
  ///
  /// In ko, this message translates to:
  /// **'Stevedore 열기'**
  String get trayOpen;

  /// No description provided for @trayTidyNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 정리'**
  String get trayTidyNow;

  /// No description provided for @trayQuit.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get trayQuit;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get commonCopy;

  /// No description provided for @tidyNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 정리'**
  String get tidyNow;

  /// No description provided for @homeRulesSummary.
  ///
  /// In ko, this message translates to:
  /// **'규칙 {count}개 · 감시 중'**
  String homeRulesSummary(int count);

  /// No description provided for @previewTitle.
  ///
  /// In ko, this message translates to:
  /// **'정리 미리보기'**
  String get previewTitle;

  /// No description provided for @previewNoRules.
  ///
  /// In ko, this message translates to:
  /// **'켜져 있는 규칙이 없습니다. 규칙을 추가하면 여기서 결과를 미리 볼 수 있습니다.'**
  String get previewNoRules;

  /// No description provided for @previewNothing.
  ///
  /// In ko, this message translates to:
  /// **'지금 정리할 파일이 없습니다.'**
  String get previewNothing;

  /// No description provided for @previewWaiting.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 파일은 받는 중이거나 방금 바뀌어서 이번에는 건너뜁니다.'**
  String previewWaiting(int count);

  /// No description provided for @previewSummary.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 파일을 정리합니다'**
  String previewSummary(int count);

  /// No description provided for @previewRun.
  ///
  /// In ko, this message translates to:
  /// **'정리 실행 ({count})'**
  String previewRun(int count);

  /// No description provided for @actionMoveTo.
  ///
  /// In ko, this message translates to:
  /// **'→ {folder}'**
  String actionMoveTo(String folder);

  /// No description provided for @actionTrash.
  ///
  /// In ko, this message translates to:
  /// **'휴지통으로'**
  String get actionTrash;

  /// No description provided for @historyTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 기록'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 정리한 파일이 없습니다.'**
  String get historyEmpty;

  /// No description provided for @historyUndo.
  ///
  /// In ko, this message translates to:
  /// **'되돌리기'**
  String get historyUndo;

  /// No description provided for @historyUndone.
  ///
  /// In ko, this message translates to:
  /// **'되돌림'**
  String get historyUndone;

  /// No description provided for @historyFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get historyFailed;

  /// No description provided for @historyUndoUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'휴지통 위치를 알 수 없어 되돌릴 수 없습니다. 휴지통에서 직접 복원해 주세요.'**
  String get historyUndoUnavailable;

  /// No description provided for @tidyDone.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 파일을 정리했습니다'**
  String tidyDone(int count);

  /// No description provided for @tidyDonePartial.
  ///
  /// In ko, this message translates to:
  /// **'{done}개 정리, {failed}개 실패'**
  String tidyDonePartial(int done, int failed);

  /// No description provided for @undoDone.
  ///
  /// In ko, this message translates to:
  /// **'원래 위치로 되돌렸습니다'**
  String get undoDone;

  /// No description provided for @undoFailed.
  ///
  /// In ko, this message translates to:
  /// **'되돌리지 못했습니다: {error}'**
  String undoFailed(String error);

  /// No description provided for @watchErrorTitle.
  ///
  /// In ko, this message translates to:
  /// **'폴더를 읽지 못했습니다'**
  String get watchErrorTitle;

  /// No description provided for @watchErrorHint.
  ///
  /// In ko, this message translates to:
  /// **'폴더가 있는지, 시스템 설정의 개인정보 보호 및 보안에서 Stevedore의 파일 및 폴더 접근이 허용돼 있는지 확인하세요.'**
  String get watchErrorHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
