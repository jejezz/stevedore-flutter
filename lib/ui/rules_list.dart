import 'package:flutter/material.dart';

import '../engine/paths.dart';
import '../l10n/app_localizations.dart';
import '../rules/rule.dart';
import '../theme/app_theme.dart';
import 'rule_formatting.dart';

/// 규칙 목록. 감시 폴더별로 묶어 보여주고, 폴더 그룹은 접고 펼 수 있다. 끌어서 같은 그룹 안의
/// 순서(우선순위)를 바꾸고, 스위치로 켜고 끄고, 메뉴로 수정·삭제한다.
///
/// [onReorder]의 인덱스는 그룹이 아니라 전체 [rules] 기준이다.
class RulesList extends StatelessWidget {
  const RulesList({
    super.key,
    required this.rules,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
    required this.collapsedFolders,
    required this.onToggleFolder,
  });

  final List<Rule> rules;
  final void Function(Rule rule, bool enabled) onToggle;
  final void Function(Rule rule) onEdit;
  final void Function(Rule rule) onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;

  /// 접어 둔 그룹의 폴더 경로(정규화한 값).
  final Set<String> collapsedFolders;
  final void Function(String folder, bool collapsed) onToggleFolder;

  /// 폴더(정규화한 경로)별로 규칙의 전체 인덱스를 모은다. 그룹은 처음 나온 순서를 따른다.
  Map<String, List<int>> _groups() {
    final groups = <String, List<int>>{};
    for (var i = 0; i < rules.length; i++) {
      groups.putIfAbsent(expandPath(rules[i].watchedFolder), () => []).add(i);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (rules.isEmpty) {
      return Center(child: Text(l10n.rulesEmpty, style: theme.textTheme.bodySmall, textAlign: TextAlign.center));
    }
    final groups = _groups().entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, g) => _group(context, groups[g].key, groups[g].value),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.rulesOrderHint, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _group(BuildContext context, String folder, List<int> indices) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final expanded = !collapsedFolders.contains(folder);
    final enabledCount = indices.where((i) => rules[i].enabled).length;
    return Column(
      key: ValueKey(folder),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onToggleFolder(folder, expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(expanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded, size: 20),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.folder_outlined, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(abbreviateHome(folder),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.userContent.copyWith(fontWeight: FontWeight.w600)),
                ),
                Text(l10n.rulesGroupCount(enabledCount, indices.length), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        if (expanded)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: indices.length,
            // 그룹 안의 위치를 전체 목록의 위치로 바꿔 넘긴다.
            onReorderItem: (oldIndex, newIndex) => onReorder(indices[oldIndex], indices[newIndex]),
            itemBuilder: (context, i) => _tile(context, rules[indices[i]], i),
          ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _tile(BuildContext context, Rule r, int indexInGroup) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListTile(
      key: ValueKey(r.id),
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: ReorderableDragStartListener(
        index: indexInGroup,
        child: const MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Icon(Icons.drag_indicator_rounded, size: 22),
        ),
      ),
      title: Text(r.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.userContent.copyWith(color: r.enabled ? null : theme.disabledColor)),
      subtitle: Text(describeRule(l10n, r), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.userContent),
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
  }
}
