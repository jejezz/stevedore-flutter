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

  @override
  String get rulesTitle => 'Rules';

  @override
  String get rulesAdd => 'Add rule';

  @override
  String get rulesEmpty => 'No rules yet. Add one to start tidying.';

  @override
  String get rulesOrderHint => 'Rules higher up are applied first.';

  @override
  String get ruleEdit => 'Edit';

  @override
  String get ruleDelete => 'Delete';

  @override
  String get ruleDeleteTitle => 'Delete this rule?';

  @override
  String ruleDeleteBody(String name) {
    return 'The rule “$name” will be deleted. Your activity history is kept.';
  }

  @override
  String get ruleEditorNewTitle => 'New rule';

  @override
  String get ruleEditorEditTitle => 'Edit rule';

  @override
  String get ruleFieldName => 'Rule name';

  @override
  String get ruleFieldFolder => 'Watched folder';

  @override
  String get ruleChooseFolder => 'Choose folder';

  @override
  String get ruleSectionCondition => 'Conditions (all must match)';

  @override
  String get ruleFieldExtensions => 'Extensions';

  @override
  String get ruleFieldExtensionsHint => 'pdf, docx, zip';

  @override
  String get ruleFieldNameContains => 'Name contains';

  @override
  String get ruleFieldMinSize => 'Min size';

  @override
  String get ruleFieldMaxSize => 'Max size';

  @override
  String get ruleFieldOlderThan => 'Age';

  @override
  String get ruleOlderThanSuffix => 'days or older';

  @override
  String get ruleSectionAction => 'Action';

  @override
  String get ruleActionMove => 'Move to folder';

  @override
  String get ruleActionTrash => 'Move to Trash';

  @override
  String get ruleFieldDestination => 'Destination folder';

  @override
  String get ruleTrashNote =>
      'Files go to the Trash. Nothing is deleted permanently.';

  @override
  String get ruleSave => 'Save';

  @override
  String get rulePreview => 'Preview';

  @override
  String get ruleErrName => 'Enter a rule name';

  @override
  String get ruleErrFolder => 'Enter a folder to watch';

  @override
  String get ruleErrCondition => 'Set at least one condition';

  @override
  String get ruleErrDestination => 'Enter a destination folder';

  @override
  String get ruleErrSameFolder =>
      'The destination is the same as the watched folder';

  @override
  String get ruleErrNumber => 'Enter a number, 0 or more';

  @override
  String get ruleErrSizeRange => 'Min size is larger than max size';

  @override
  String get rulePreviewTitle => 'Files matching this rule';

  @override
  String rulePreviewCount(int count) {
    return '$count files match right now';
  }

  @override
  String get rulePreviewNone => 'No files match right now.';

  @override
  String condNameContains(String text) {
    return 'name contains “$text”';
  }

  @override
  String condMinSize(String size) {
    return '$size or larger';
  }

  @override
  String condMaxSize(String size) {
    return '$size or smaller';
  }

  @override
  String condOlderThan(int days) {
    return '$days days or older';
  }

  @override
  String get loginItemLabel => 'Launch at login';

  @override
  String loginItemFailed(String error) {
    return 'Couldn\'t change the launch-at-login setting: $error';
  }

  @override
  String get presetsStart => 'Start with suggested rules';

  @override
  String get presetsTitle => 'Suggested rules';

  @override
  String get presetsIntro =>
      'The rules you pick apply to your Downloads folder. Files already there are tidied right away, and you can undo from Recent activity.';

  @override
  String presetsAdd(int count) {
    return 'Add ($count)';
  }

  @override
  String get presetsAlready => 'Already added';

  @override
  String presetCount(int count) {
    return '$count now';
  }

  @override
  String get presetDocuments => 'Documents';

  @override
  String get presetImages => 'Images';

  @override
  String get presetInstallers => 'Installers';

  @override
  String get presetArchives => 'Archives';

  @override
  String get presetOldInstallers => 'Installers older than 30 days';

  @override
  String get trayLoginItem => 'Launch at login';
}
