import 'package:flutter/material.dart';

import '../engine/tidy_engine.dart';
import '../engine/tidy_service.dart';
import '../l10n/app_localizations.dart';
import '../rules/rule.dart';
import '../theme/app_theme.dart';

/// "지금 정리"의 미리보기. 파일을 건드리기 전에 무엇을 어떻게 할지 보여주고,
/// 확인하면 실행한 결과 목록을 돌려준다 (취소하면 null).
Future<List<ActionResult>?> showTidyPreview(BuildContext context, TidyService service) =>
    showDialog<List<ActionResult>>(
      context: context,
      builder: (_) => _PreviewDialog(service: service),
    );

class _PreviewDialog extends StatefulWidget {
  const _PreviewDialog({required this.service});

  final TidyService service;

  @override
  State<_PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<_PreviewDialog> {
  late final Future<PlanResult> _plan = widget.service.preview();
  bool _running = false;

  Future<void> _run(PlanResult plan) async {
    setState(() => _running = true);
    final results = await widget.service.run(plan);
    if (mounted) Navigator.of(context).pop(results);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return FutureBuilder<PlanResult>(
      future: _plan,
      builder: (context, snapshot) {
        final plan = snapshot.data;
        final hasRules = widget.service.rules.any((r) => r.enabled);
        return AlertDialog(
          title: Text(l10n.previewTitle),
          content: SizedBox(
            width: 560,
            height: 360,
            child: plan == null
                ? const Center(child: CircularProgressIndicator())
                : _body(context, plan, hasRules: hasRules),
          ),
          actions: [
            TextButton(
              autofocus: true, // 기본 포커스는 취소 (ui-ux.md §6)
              onPressed: _running ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: plan == null || plan.actions.isEmpty || _running ? null : () => _run(plan),
              child: Text(l10n.previewRun(plan?.actions.length ?? 0)),
            ),
          ],
          titleTextStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        );
      },
    );
  }

  Widget _body(BuildContext context, PlanResult plan, {required bool hasRules}) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (plan.actions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hasRules ? l10n.previewNothing : l10n.previewNoRules,
                textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (plan.waiting > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Text(l10n.previewWaiting(plan.waiting), style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.previewSummary(plan.actions.length), style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView.separated(
            itemCount: plan.actions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final a = plan.actions[i];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  a.action is TrashAction ? Icons.delete_outline_rounded : Icons.drive_file_move_rounded,
                  size: 22,
                ),
                title: Text(a.facts.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.userContent),
                subtitle: Text(
                  '${a.rule.name} · ${describeAction(l10n, a.action)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.userContent,
                ),
              );
            },
          ),
        ),
        if (plan.waiting > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.previewWaiting(plan.waiting), style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

String describeAction(AppLocalizations l10n, RuleAction action) => switch (action) {
      MoveAction(:final destination) => l10n.actionMoveTo(destination),
      TrashAction() => l10n.actionTrash,
    };
