import 'package:flutter/material.dart';

import '../engine/tidy_service.dart';
import '../l10n/app_localizations.dart';
import '../rules/presets.dart';
import '../rules/rule.dart';
import '../theme/app_theme.dart';

String presetLabel(AppLocalizations l10n, RulePreset p) => switch (p) {
      RulePreset.oldInstallers => l10n.presetOldInstallers,
      RulePreset.documents => l10n.presetDocuments,
      RulePreset.images => l10n.presetImages,
      RulePreset.installers => l10n.presetInstallers,
      RulePreset.archives => l10n.presetArchives,
    };

/// 추천 규칙을 골라 추가한다. 추가했으면 true.
Future<bool> showPresetsDialog(BuildContext context, TidyService service) async =>
    await showDialog<bool>(context: context, builder: (_) => _PresetsDialog(service: service)) ?? false;

class _PresetsDialog extends StatefulWidget {
  const _PresetsDialog({required this.service});

  final TidyService service;

  @override
  State<_PresetsDialog> createState() => _PresetsDialogState();
}

class _PresetsDialogState extends State<_PresetsDialog> {
  late final Set<RulePreset> _selected = {...RulePreset.values.where((p) => !p.trash)};
  final Map<RulePreset, int> _counts = {};
  bool _built = false;

  late final AppLocalizations _l10n = AppLocalizations.of(context);

  Rule _rule(RulePreset p, {String? id}) => p.build(
        id: id ?? p.name,
        name: presetLabel(_l10n, p),
        folderName: presetLabel(_l10n, p),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_built) return;
    _built = true;
    // 각 추천 규칙이 지금 Downloads의 몇 개 파일에 해당하는지 미리 센다.
    for (final p in RulePreset.values) {
      widget.service.previewRule(_rule(p)).then((plan) {
        if (mounted) setState(() => _counts[p] = plan.actions.length);
      });
    }
  }

  bool _exists(RulePreset p) => widget.service.rules.any((r) => r.name == presetLabel(_l10n, p));

  Future<void> _add() async {
    final rules = [
      for (final p in RulePreset.values)
        if (_selected.contains(p) && !_exists(p)) _rule(p, id: '${widget.service.newRuleId()}-${p.name}'),
    ];
    await widget.service.addRules(rules);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chosen = _selected.where((p) => !_exists(p)).length;
    return AlertDialog(
      title: Text(_l10n.presetsTitle),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_l10n.presetsIntro, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            for (final p in RulePreset.values)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _selected.contains(p) && !_exists(p),
                onChanged: _exists(p) ? null : (v) => setState(() => v! ? _selected.add(p) : _selected.remove(p)),
                title: Text(presetLabel(_l10n, p)),
                subtitle: Text(
                  p.extensions.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                secondary: Text(
                  _exists(p)
                      ? _l10n.presetsAlready
                      : _counts[p] == null
                          ? ''
                          : _l10n.presetCount(_counts[p]!),
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: Text(_l10n.commonCancel)),
        FilledButton(onPressed: chosen == 0 ? null : _add, child: Text(_l10n.presetsAdd(chosen))),
      ],
    );
  }
}
