import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/paths.dart';
import '../engine/tidy_service.dart';
import '../l10n/app_localizations.dart';
import '../rules/rule.dart';
import '../theme/app_theme.dart';
import 'rule_formatting.dart';

/// 규칙을 새로 만들거나([rule]이 null) 고친다. 저장하면 새 [Rule]을 돌려주고,
/// 저장은 부른 쪽이 한다. 취소하면 null.
Future<Rule?> showRuleEditor(BuildContext context, TidyService service, {Rule? rule}) =>
    showDialog<Rule>(context: context, builder: (_) => RuleEditorDialog(service: service, rule: rule));

const _sizeUnits = [('KB', 1024), ('MB', 1024 * 1024), ('GB', 1024 * 1024 * 1024)];

class RuleEditorDialog extends StatefulWidget {
  const RuleEditorDialog({super.key, required this.service, this.rule});

  final TidyService service;
  final Rule? rule;

  @override
  State<RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends State<RuleEditorDialog> {
  late final _name = TextEditingController(text: widget.rule?.name ?? '');
  late final _folder = TextEditingController(text: widget.rule?.watchedFolder ?? '~/Downloads');
  late final _extensions = TextEditingController(text: widget.rule?.condition.extensions.join(', ') ?? '');
  late final _nameContains = TextEditingController(text: widget.rule?.condition.nameContains ?? '');
  late final _olderThan = TextEditingController(text: widget.rule?.condition.olderThanDays?.toString() ?? '');
  late final _destination = TextEditingController(
    text: switch (widget.rule?.action) {
      MoveAction(:final destination) => destination,
      _ => '',
    },
  );
  late final _minSize = _SizeField(widget.rule?.condition.minSizeBytes);
  late final _maxSize = _SizeField(widget.rule?.condition.maxSizeBytes);
  late bool _trash = widget.rule?.action is TrashAction;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _folder, _extensions, _nameContains, _olderThan, _destination]) {
      c.dispose();
    }
    _minSize.dispose();
    _maxSize.dispose();
    super.dispose();
  }

  /// 입력값에서 규칙을 만든다. 잘못됐으면 안내 문구를 [_error]에 두고 null.
  Rule? _build({bool forPreview = false}) {
    final l10n = AppLocalizations.of(context);
    Rule? fail(String message) {
      setState(() => _error = message);
      return null;
    }

    final name = _name.text.trim();
    final folder = _folder.text.trim();
    if (!forPreview && name.isEmpty) return fail(l10n.ruleErrName);
    if (folder.isEmpty) return fail(l10n.ruleErrFolder);

    final extensions = {
      for (final e in _extensions.text.split(RegExp(r'[,\s]+'))) if (RuleCondition.normalizeExtension(e).isNotEmpty) RuleCondition.normalizeExtension(e),
    }.toList();
    final olderText = _olderThan.text.trim();
    final olderThan = olderText.isEmpty ? null : int.tryParse(olderText);
    if (olderText.isNotEmpty && (olderThan == null || olderThan < 0)) return fail(l10n.ruleErrNumber);
    final min = _minSize.parse();
    final max = _maxSize.parse();
    if (min.invalid || max.invalid) return fail(l10n.ruleErrNumber);
    if (min.bytes != null && max.bytes != null && min.bytes! > max.bytes!) return fail(l10n.ruleErrSizeRange);

    final condition = RuleCondition(
      extensions: extensions,
      nameContains: _nameContains.text.trim().isEmpty ? null : _nameContains.text.trim(),
      minSizeBytes: min.bytes,
      maxSizeBytes: max.bytes,
      olderThanDays: olderThan,
    );
    if (condition.isEmpty) return fail(l10n.ruleErrCondition);

    final RuleAction action;
    if (_trash) {
      action = const TrashAction();
    } else {
      final destination = _destination.text.trim();
      if (destination.isEmpty) return fail(l10n.ruleErrDestination);
      // 같은 폴더로 "이동"하면 이름만 바뀌며 끝없이 되풀이된다.
      if (expandPath(destination) == expandPath(folder)) return fail(l10n.ruleErrSameFolder);
      action = MoveAction(destination);
    }
    setState(() => _error = null);
    return Rule(
      id: widget.rule?.id ?? widget.service.newRuleId(),
      name: name.isEmpty ? '…' : name,
      enabled: widget.rule?.enabled ?? true,
      watchedFolder: folder,
      condition: condition,
      action: action,
    );
  }

  Future<void> _pick(TextEditingController controller) async {
    final path = await getDirectoryPath(initialDirectory: expandPath(controller.text));
    if (path != null) setState(() => controller.text = abbreviateHome(path));
  }

  Future<void> _preview() async {
    final rule = _build(forPreview: true);
    if (rule == null) return;
    final plan = await widget.service.previewRule(rule);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rulePreviewTitle),
        content: SizedBox(
          width: 480,
          height: 300,
          child: plan.actions.isEmpty
              ? Center(child: Text(l10n.rulePreviewNone))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.rulePreviewCount(plan.actions.length)),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final a in plan.actions)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(a.facts.name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.userContent),
                              trailing: Text(formatBytes(a.facts.sizeBytes)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        actions: [TextButton(autofocus: true, onPressed: () => Navigator.pop(context), child: Text(l10n.commonClose))],
      ),
    );
  }

  Widget _folderField(TextEditingController controller, String label) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
            style: AppFonts.userContent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: l10n.ruleChooseFolder,
          icon: const Icon(Icons.folder_open_rounded),
          onPressed: () => _pick(controller),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const gap = SizedBox(height: AppSpacing.md);
    return AlertDialog(
      title: Text(widget.rule == null ? l10n.ruleEditorNewTitle : l10n.ruleEditorEditTitle),
      scrollable: true,
      content: SizedBox(
        width: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.rule == null,
              decoration: InputDecoration(labelText: l10n.ruleFieldName),
              style: AppFonts.userContent,
            ),
            gap,
            _folderField(_folder, l10n.ruleFieldFolder),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.ruleSectionCondition, style: theme.textTheme.titleSmall),
            gap,
            TextField(
              controller: _extensions,
              decoration: InputDecoration(labelText: l10n.ruleFieldExtensions, hintText: l10n.ruleFieldExtensionsHint),
            ),
            gap,
            TextField(
              controller: _nameContains,
              decoration: InputDecoration(labelText: l10n.ruleFieldNameContains),
              style: AppFonts.userContent,
            ),
            gap,
            Row(children: [
              Expanded(child: _minSize.build(context, l10n.ruleFieldMinSize, () => setState(() {}))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _maxSize.build(context, l10n.ruleFieldMaxSize, () => setState(() {}))),
            ]),
            gap,
            TextField(
              controller: _olderThan,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l10n.ruleFieldOlderThan, suffixText: l10n.ruleOlderThanSuffix),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.ruleSectionAction, style: theme.textTheme.titleSmall),
            gap,
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l10n.ruleActionMove)),
                ButtonSegment(value: true, label: Text(l10n.ruleActionTrash)),
              ],
              selected: {_trash},
              onSelectionChanged: (s) => setState(() => _trash = s.first),
            ),
            gap,
            if (_trash)
              Text(l10n.ruleTrashNote, style: theme.textTheme.bodySmall)
            else
              _folderField(_destination, l10n.ruleFieldDestination),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
        OutlinedButton(onPressed: _preview, child: Text(l10n.rulePreview)),
        FilledButton(
          onPressed: () {
            final rule = _build();
            if (rule != null) Navigator.pop(context, rule);
          },
          child: Text(l10n.ruleSave),
        ),
      ],
    );
  }
}

/// 숫자 입력칸과 단위(KB/MB/GB) 선택. 비워 두면 조건 없음.
class _SizeField {
  _SizeField(int? bytes) {
    if (bytes != null) {
      var unit = 0;
      for (var i = _sizeUnits.length - 1; i >= 0; i--) {
        if (bytes >= _sizeUnits[i].$2 && bytes % _sizeUnits[i].$2 == 0) {
          unit = i;
          break;
        }
      }
      _unit = unit;
      final value = bytes / _sizeUnits[unit].$2;
      controller.text = value == value.roundToDouble() ? value.round().toString() : value.toString();
    }
  }

  final controller = TextEditingController();
  int _unit = 1; // MB

  void dispose() => controller.dispose();

  ({int? bytes, bool invalid}) parse() {
    final text = controller.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return (bytes: null, invalid: false);
    final value = double.tryParse(text);
    if (value == null || value < 0) return (bytes: null, invalid: true);
    return (bytes: (value * _sizeUnits[_unit].$2).round(), invalid: false);
  }

  Widget build(BuildContext context, String label, VoidCallback onChanged) => Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: InputDecoration(labelText: label),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          DropdownButton<int>(
            value: _unit,
            underline: const SizedBox.shrink(),
            items: [for (var i = 0; i < _sizeUnits.length; i++) DropdownMenuItem(value: i, child: Text(_sizeUnits[i].$1))],
            onChanged: (v) {
              _unit = v ?? _unit;
              onChanged();
            },
          ),
        ],
      );
}
