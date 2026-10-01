// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutTooltip => 'About';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String get aboutOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get aboutRepository => 'GitHub';

  @override
  String get commonClose => 'Close';

  @override
  String aboutMenuItem(String appName) {
    return 'About $appName';
  }

  @override
  String get themeMenuTooltip => 'Theme';

  @override
  String get themeSystem => 'Follow System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageMenuTooltip => 'Language';

  @override
  String get languageSystem => 'System / 시스템 설정 따르기';

  @override
  String get languageSystemShort => 'System';

  @override
  String get aboutTagline => 'Keeps your Downloads folder tidy, by your rules';

  @override
  String get aboutDescription =>
      'Stevedore sorts and cleans up files that land in folders like Downloads, by extension, name, size and age. Let it run in the background, or tidy up on demand with \"Tidy now\".';

  @override
  String get homeEmptyTitle =>
      'No rules yet. Add a rule to start tidying your Downloads folder';

  @override
  String get homeEmptyAction => 'Add rule';

  @override
  String get trayOpen => 'Open Stevedore';

  @override
  String get trayTidyNow => 'Tidy now';

  @override
  String get trayQuit => 'Quit';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonCopy => 'Copy';

  @override
  String get tidyNow => 'Tidy now';

  @override
  String homeRulesSummary(int count) {
    return '$count rules · watching';
  }

  @override
  String get previewTitle => 'Tidy preview';

  @override
  String get previewNoRules =>
      'No rules are turned on. Add a rule to preview what it would do.';

  @override
  String get previewNothing => 'Nothing to tidy right now.';

  @override
  String previewWaiting(int count) {
    return '$count files are still downloading or just changed, so they are skipped this time.';
  }

  @override
  String previewSummary(int count) {
    return '$count files will be tidied';
  }

  @override
  String previewRun(int count) {
    return 'Tidy ($count)';
  }

  @override
  String actionMoveTo(String folder) {
    return '→ $folder';
  }

  @override
  String get actionTrash => 'To Trash';

  @override
  String get historyTitle => 'Recent activity';

  @override
  String get historyEmpty => 'No files tidied yet.';

  @override
  String get historyUndo => 'Undo';

  @override
  String get historyUndone => 'Undone';

  @override
  String get historyFailed => 'Failed';

  @override
  String get historyUndoUnavailable =>
      'Can\'t tell where the file is in the Trash, so it can\'t be undone here. Restore it from the Trash yourself.';

  @override
  String tidyDone(int count) {
    return 'Tidied $count files';
  }

  @override
  String tidyDonePartial(int done, int failed) {
    return '$done tidied, $failed failed';
  }

  @override
  String get undoDone => 'Put back where it was';

  @override
  String undoFailed(String error) {
    return 'Couldn\'t undo: $error';
  }

  @override
  String get watchErrorTitle => 'Couldn\'t read a folder';

  @override
  String get watchErrorHint =>
      'Check that the folder exists and that Stevedore is allowed to access files and folders in System Settings › Privacy & Security.';
}
