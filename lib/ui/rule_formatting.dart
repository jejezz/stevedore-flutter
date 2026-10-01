import '../l10n/app_localizations.dart';
import '../rules/rule.dart';
import 'preview_dialog.dart';

String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = value >= 10 || value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}

/// "pdf, docx · 이름에 "invoice" 포함 · 1 MB 이상 · 30일 이상 지남"
String describeCondition(AppLocalizations l10n, RuleCondition c) => [
      if (c.extensions.isNotEmpty) c.extensions.join(', '),
      if (c.nameContains != null && c.nameContains!.isNotEmpty) l10n.condNameContains(c.nameContains!),
      if (c.minSizeBytes != null) l10n.condMinSize(formatBytes(c.minSizeBytes!)),
      if (c.maxSizeBytes != null) l10n.condMaxSize(formatBytes(c.maxSizeBytes!)),
      if (c.olderThanDays != null) l10n.condOlderThan(c.olderThanDays!),
    ].join(' · ');

/// 규칙 목록의 둘째 줄: "~/Downloads · pdf → ~/Documents".
String describeRule(AppLocalizations l10n, Rule r) =>
    '${r.watchedFolder} · ${describeCondition(l10n, r.condition)} ${describeAction(l10n, r.action)}';
