import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../engine/history.dart';
import '../engine/paths.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class HistoryList extends StatelessWidget {
  const HistoryList({super.key, required this.entries, required this.onUndo});

  final List<HistoryEntry> entries;
  final void Function(HistoryEntry entry) onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Center(child: Text(l10n.historyEmpty, style: theme.textTheme.bodySmall));
    }
    final timeFormat = DateFormat.Md(Localizations.localeOf(context).toString()).add_Hm();
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final e = entries[i];
        final failed = !e.succeeded;
        final where = failed
            ? '${l10n.historyFailed}: ${e.error}'
            : e.kind == HistoryKind.trash
                ? l10n.actionTrash
                : l10n.actionMoveTo(abbreviateHome(_parentOf(e.resultPath ?? '')));
        return ListTile(
          dense: true,
          leading: Icon(
            failed
                ? Icons.error_outline_rounded
                : e.kind == HistoryKind.trash
                    ? Icons.delete_outline_rounded
                    : Icons.drive_file_move_rounded,
            size: 22,
            color: failed ? theme.colorScheme.error : null,
          ),
          title: Text(e.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.userContent.copyWith(
                decoration: e.undone ? TextDecoration.lineThrough : null,
              )),
          subtitle: Text(
            '${timeFormat.format(e.time)} · ${e.ruleName} · $where',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.userContent,
          ),
          trailing: _trailing(context, e, l10n),
        );
      },
    );
  }

  Widget? _trailing(BuildContext context, HistoryEntry e, AppLocalizations l10n) {
    if (!e.succeeded) return null;
    if (e.undone) return Text(l10n.historyUndone, style: Theme.of(context).textTheme.bodySmall);
    if (e.canUndo) return TextButton(onPressed: () => onUndo(e), child: Text(l10n.historyUndo));
    return Tooltip(
      message: l10n.historyUndoUnavailable,
      child: const Icon(Icons.info_outline_rounded, size: 18),
    );
  }

  static String _parentOf(String path) {
    final i = path.lastIndexOf(RegExp(r'[/\\]'));
    return i > 0 ? path.substring(0, i) : path;
  }
}
