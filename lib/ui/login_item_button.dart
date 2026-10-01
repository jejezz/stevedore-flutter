import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../system/login_item.dart';

/// 앱 바의 "로그인 시 자동 실행" 켜기/끄기. 테마·언어 메뉴처럼 체크 표시가 있는 팝업 메뉴다.
class LoginItemMenuButton extends StatelessWidget {
  const LoginItemMenuButton({super.key, required this.controller});

  final LoginItemController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.supported) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => PopupMenuButton<bool>(
        tooltip: l10n.loginItemLabel,
        icon: Icon(controller.enabled ? Icons.power_settings_new_rounded : Icons.power_off_rounded),
        onSelected: (value) async {
          try {
            await controller.setEnabled(value);
          } on Object catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.loginItemFailed('$e'))));
            }
          }
        },
        itemBuilder: (_) => [
          CheckedPopupMenuItem(value: !controller.enabled, checked: controller.enabled, child: Text(l10n.loginItemLabel)),
        ],
      ),
    );
  }
}
