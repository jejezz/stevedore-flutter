import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../rules/rule.dart';
import '../theme/app_theme.dart';
import 'rule_formatting.dart';

/// 규칙 목록. 끌어서 순서(우선순위)를 바꾸고, 스위치로 켜고 끄고, 메뉴로 수정·삭제한다.
class RulesList extends StatelessWidget {
  const RulesList({
    super.key,
    required this.rules,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
  });

  final List<Rule> rules;
  final void Function(Rule rule, bool enabled) onToggle;
  final void Function(Rule rule) onEdit;
  final void Function(Rule rule) onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (rules.isEmpty) {
      return Center(child: Text(l10n.rulesEmpty, style: theme.textTheme.bodySmall, textAlign: TextAlign.center));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: rules.length,
            onReorderItem: onReorder,
            itemBuilder: (context, i) {
              final r = rules[i];
              return ListTile(
                key: ValueKey(r.id),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: ReorderableDragStartListener(
                  index: i,
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Icon(Icons.drag_indicator_rounded, size: 22),
                  ),
                ),
                title: Text(r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.userContent.copyWith(color: r.enabled ? null : theme.disabledColor)),
                subtitle: Text(describeRule(l10n, r),
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.userContent),
                onTap: () => onEdit(r),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(value: r.enabled, onChanged: (v) => onToggle(r, v)),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 18),
                      onSelected: (v) => v == 'edit' ? onEdit(r) : onDelete(r),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.ruleEdit)),
                        PopupMenuItem(value: 'delete', child: Text(l10n.ruleDelete)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.rulesOrderHint, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
