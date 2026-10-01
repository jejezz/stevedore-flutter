import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_identity.dart';
import '../engine/history.dart';
import '../engine/tidy_service.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings_menus.dart';
import '../theme/app_theme.dart';
import 'history_list.dart';
import 'preview_dialog.dart';

/// 메인 화면: 규칙 요약 + "지금 정리" + 최근 기록. 규칙도 기록도 없으면 빈 상태 (ui-ux.md §6).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onAbout, required this.service});

  final VoidCallback onAbout;
  final TidyService service;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  /// 트레이 메뉴의 "지금 정리"도 이 경로로 들어온다.
  Future<void> tidyNow() async {
    final results = await showTidyPreview(context, widget.service);
    if (!mounted || results == null || results.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final failed = results.where((r) => !r.succeeded).length;
    _toast(failed == 0 ? l10n.tidyDone(results.length) : l10n.tidyDonePartial(results.length - failed, failed));
  }

  Future<void> _undo(HistoryEntry entry) async {
    final l10n = AppLocalizations.of(context);
    try {
      await widget.service.undo(entry);
      if (mounted) _toast(l10n.undoDone);
    } on Object catch (e) {
      if (mounted) _toast(l10n.undoFailed('$e'), copyable: '$e');
    }
  }

  void _toast(String message, {String? copyable}) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: copyable == null
            ? null
            : SnackBarAction(label: l10n.commonCopy, onPressed: () => Clipboard.setData(ClipboardData(text: copyable))),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        final service = widget.service;
        final empty = service.rules.isEmpty && service.history.isEmpty;
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppIdentity.displayName),
            actions: [
              const ThemeMenuButton(),
              const LanguageMenuButton(),
              IconButton(
                tooltip: l10n.aboutTooltip,
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: widget.onAbout,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          body: empty ? _emptyState(context) : _content(context),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppIdentity.iconAsset, width: 48, height: 48),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.homeEmptyTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          // 규칙 편집기가 들어오면 주 행동을 연결한다. 그 전까지는 비활성.
          FilledButton(onPressed: null, child: Text(l10n.homeEmptyAction)),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final service = widget.service;
    final error = service.watchError;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null) ...[
            MaterialBanner(
              leading: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              content: Text('${l10n.watchErrorTitle}\n${l10n.watchErrorHint}\n$error',
                  style: AppFonts.userContent),
              actions: [TextButton(onPressed: service.dismissWatchError, child: Text(l10n.commonClose))],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Row(
            children: [
              Expanded(
                child: Text(l10n.homeRulesSummary(service.rules.where((r) => r.enabled).length),
                    style: theme.textTheme.titleMedium),
              ),
              FilledButton.icon(
                onPressed: tidyNow,
                icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                label: Text(l10n.tidyNow),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.historyTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: HistoryList(entries: service.history, onUndo: _undo)),
        ],
      ),
    );
  }
}
