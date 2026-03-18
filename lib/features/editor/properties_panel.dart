import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../../models/frontmatter.dart';

/// Collapsible properties panel shown above the editor.
///
/// Displays mood and energy as 5-dot ratings, sleep as a decimal hour field,
/// and tags as dismissible chips with a live-add input.
class PropertiesPanel extends StatefulWidget {
  final Frontmatter frontmatter;
  final void Function(Frontmatter) onChanged;

  const PropertiesPanel({
    super.key,
    required this.frontmatter,
    required this.onChanged,
  });

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel> {
  late TextEditingController _sleepCtrl;
  final TextEditingController _tagCtrl = TextEditingController();
  final FocusNode _tagFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _sleepCtrl = TextEditingController(
      text: widget.frontmatter.sleep != null
          ? _formatSleep(widget.frontmatter.sleep!)
          : '',
    );
  }

  @override
  void didUpdateWidget(PropertiesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync sleep field only when frontmatter changes from outside (e.g. file
    // reload), but not while the user is actively editing.
    if (!_sleepCtrl.value.composing.isValid) {
      final newText = widget.frontmatter.sleep != null
          ? _formatSleep(widget.frontmatter.sleep!)
          : '';
      if (_sleepCtrl.text != newText) _sleepCtrl.text = newText;
    }
  }

  @override
  void dispose() {
    _sleepCtrl.dispose();
    _tagCtrl.dispose();
    _tagFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Change handlers
  // ---------------------------------------------------------------------------

  void _setMood(int? v) =>
      widget.onChanged(widget.frontmatter.copyWith(mood: v));

  void _setEnergy(int? v) =>
      widget.onChanged(widget.frontmatter.copyWith(energy: v));

  void _onSleepChanged(String text) {
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    if (v != null && v != widget.frontmatter.sleep) {
      widget.onChanged(widget.frontmatter.copyWith(sleep: v));
    }
  }

  void _addTag(String text) {
    final tag = text.trim().toLowerCase();
    if (tag.isEmpty || widget.frontmatter.tags.contains(tag)) {
      _tagCtrl.clear();
      return;
    }
    widget.onChanged(
      widget.frontmatter
          .copyWith(tags: [...widget.frontmatter.tags, tag]),
    );
    _tagCtrl.clear();
  }

  void _removeTag(String tag) {
    widget.onChanged(
      widget.frontmatter.copyWith(
        tags: widget.frontmatter.tags.where((t) => t != tag).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: Mood · Energy · Sleep ──────────────────────────────
          Wrap(
            spacing: 24,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _LabelledRow(
                icon: Icons.mood_outlined,
                label: l10n.frontmatterMood,
                child: _DotRating(
                  value: widget.frontmatter.mood,
                  onChanged: _setMood,
                ),
              ),
              _LabelledRow(
                icon: Icons.bolt_outlined,
                label: l10n.frontmatterEnergy,
                child: _DotRating(
                  value: widget.frontmatter.energy,
                  onChanged: _setEnergy,
                ),
              ),
              _LabelledRow(
                icon: Icons.bedtime_outlined,
                label: l10n.frontmatterSleep,
                child: SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _sleepCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                    ],
                    textAlign: TextAlign.center,
                    style: tt.bodySmall,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 6),
                      suffixText: 'h',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: _onSleepChanged,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Row 2: Tags ───────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed label
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _LabelledRow(
                  icon: Icons.label_outline,
                  label: l10n.frontmatterTags,
                  child: const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 4),
              // Chips + input
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...widget.frontmatter.tags.map(
                      (tag) => InputChip(
                        label: Text(tag),
                        labelStyle: tt.labelSmall,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 0),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onDeleted: () => _removeTag(tag),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: TextField(
                        controller: _tagCtrl,
                        focusNode: _tagFocus,
                        style: tt.bodySmall,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: l10n.tagAddHint,
                          hintStyle: tt.bodySmall
                              ?.copyWith(color: cs.outline),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: _addTag,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatSleep(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

/// A small icon + label combination used as a row prefix.
class _LabelledRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _LabelledRow(
      {required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: cs.outline),
        const SizedBox(width: 3),
        Text(label,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(width: 8),
        child,
      ],
    );
  }
}

/// Five tappable dots representing a 1–5 integer rating (null = not set).
class _DotRating extends StatelessWidget {
  final int? value;
  final void Function(int?) onChanged;

  const _DotRating({this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final dotVal = i + 1;
        final filled = value != null && dotVal <= value!;
        return GestureDetector(
          onTap: () => onChanged(dotVal == value ? null : dotVal),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              filled ? Icons.circle : Icons.circle_outlined,
              size: 16,
              color: filled ? cs.primary : cs.outlineVariant,
            ),
          ),
        );
      }),
    );
  }
}
