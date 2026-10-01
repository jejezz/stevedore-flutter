// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get aboutTooltip => '정보';

  @override
  String aboutVersion(String version, String build) {
    return '버전 $version (빌드 $build)';
  }

  @override
  String get aboutOpenSourceLicenses => '오픈소스 라이선스';

  @override
  String get aboutRepository => 'GitHub';

  @override
  String get commonClose => '닫기';

  @override
  String aboutMenuItem(String appName) {
    return '$appName 정보';
  }

  @override
  String get themeMenuTooltip => '테마';

  @override
  String get themeSystem => '시스템 설정 따르기';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get languageMenuTooltip => '언어';

  @override
  String get languageSystem => '시스템 설정 따르기 / System';

  @override
  String get languageSystemShort => '시스템';

  @override
  String get aboutTagline => '다운로드 폴더를 규칙대로 알아서 정리합니다';

  @override
  String get aboutDescription =>
      'Stevedore는 다운로드 폴더 같은 곳에 생긴 파일을 확장자, 이름, 크기, 오래된 정도에 따라 자동으로 분류하고 정리합니다. 상주하며 바로 처리하거나, 원할 때 \"지금 정리\"로 직접 실행할 수 있습니다.';

  @override
  String get homeEmptyTitle => '아직 정리 규칙이 없습니다. 규칙을 추가해 다운로드 폴더 정리를 시작하세요';

  @override
  String get homeEmptyAction => '규칙 추가';

  @override
  String get trayOpen => 'Stevedore 열기';

  @override
  String get trayTidyNow => '지금 정리';

  @override
  String get trayQuit => '종료';

  @override
  String get commonCancel => '취소';

  @override
  String get commonCopy => '복사';

  @override
  String get tidyNow => '지금 정리';

  @override
  String homeRulesSummary(int count) {
    return '규칙 $count개 · 감시 중';
  }

  @override
  String get previewTitle => '정리 미리보기';

  @override
  String get previewNoRules => '켜져 있는 규칙이 없습니다. 규칙을 추가하면 여기서 결과를 미리 볼 수 있습니다.';

  @override
  String get previewNothing => '지금 정리할 파일이 없습니다.';

  @override
  String previewWaiting(int count) {
    return '$count개 파일은 받는 중이거나 방금 바뀌어서 이번에는 건너뜁니다.';
  }

  @override
  String previewSummary(int count) {
    return '$count개 파일을 정리합니다';
  }

  @override
  String previewRun(int count) {
    return '정리 실행 ($count)';
  }

  @override
  String actionMoveTo(String folder) {
    return '→ $folder';
  }

  @override
  String get actionTrash => '휴지통으로';

  @override
  String get historyTitle => '최근 기록';

  @override
  String get historyEmpty => '아직 정리한 파일이 없습니다.';

  @override
  String get historyUndo => '되돌리기';

  @override
  String get historyUndone => '되돌림';

  @override
  String get historyFailed => '실패';

  @override
  String get historyUndoUnavailable =>
      '휴지통 위치를 알 수 없어 되돌릴 수 없습니다. 휴지통에서 직접 복원해 주세요.';

  @override
  String tidyDone(int count) {
    return '$count개 파일을 정리했습니다';
  }

  @override
  String tidyDonePartial(int done, int failed) {
    return '$done개 정리, $failed개 실패';
  }

  @override
  String get undoDone => '원래 위치로 되돌렸습니다';

  @override
  String undoFailed(String error) {
    return '되돌리지 못했습니다: $error';
  }

  @override
  String get watchErrorTitle => '폴더를 읽지 못했습니다';

  @override
  String get watchErrorHint =>
      '폴더가 있는지, 시스템 설정의 개인정보 보호 및 보안에서 Stevedore의 파일 및 폴더 접근이 허용돼 있는지 확인하세요.';
}
