import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../settings/app_settings.dart';

/// 정리 동작에 걸리는 전역 옵션 메뉴. 지금은 "비게 된 폴더 지우기" 하나.
class CleanupOptionsButton extends StatelessWidget {
  const CleanupOptionsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<bool>(
      tooltip: l10n.cleanupOptionsTooltip,
      icon: const Icon(Icons.tune_rounded),
      onSelected: settings.setRemoveEmptyFolders,
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: !settings.removeEmptyFolders,
          checked: settings.removeEmptyFolders,
          child: Text(l10n.optionRemoveEmptyFolders),
        ),
      ],
    );
  }
}
