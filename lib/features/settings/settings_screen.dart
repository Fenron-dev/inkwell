import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../../core/export/export_service.dart';
import '../../core/settings/settings_provider.dart';
import '../../core/vault/vault_provider.dart';
import '../../theme/app_theme.dart';

/// Settings screen for theme, font, language, vault configuration and export.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _exporting = false;

  Future<void> _runExport(AppLocalizations l10n) async {
    final vault = ref.read(vaultProvider).valueOrNull;
    if (vault == null) return;

    setState(() => _exporting = true);

    try {
      final result = await ExportService().export(vault);
      if (!mounted) return;

      if (result == null) {
        _showSnackbar(l10n.exportCancelled);
      } else {
        _showSnackbar(l10n.exportDone(result.path), duration: 6);
      }
    } catch (e) {
      if (mounted) _showSnackbar(l10n.exportError(e.toString()));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showSnackbar(String message, {int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: duration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final vault = ref.watch(vaultProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: settings.when(
        data: (s) => ListView(
          children: [
            // Theme
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(l10n.settingsTheme),
              trailing: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.settingsThemeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.settingsThemeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.settingsThemeDark),
                  ),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (modes) => ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(modes.first),
              ),
            ),
            const Divider(),

            // Font
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: Text(l10n.settingsFont),
              trailing: DropdownButton<InkwellFont>(
                value: s.font,
                underline: const SizedBox.shrink(),
                onChanged: (font) {
                  if (font != null) {
                    ref.read(settingsProvider.notifier).setFont(font);
                  }
                },
                items: InkwellFont.values
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.displayName),
                        ))
                    .toList(),
              ),
            ),
            const Divider(),

            // Editor text color
            _EditorColorTile(current: s.editorTextColor),
            const Divider(),

            // Language
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.settingsLanguage),
              trailing: DropdownButton<Locale>(
                value: s.locale,
                underline: const SizedBox.shrink(),
                onChanged: (locale) {
                  if (locale != null) {
                    ref.read(settingsProvider.notifier).setLocale(locale);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: Locale('en'),
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: Locale('de'),
                    child: Text('Deutsch'),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Export
            if (vault != null)
              ListTile(
                leading: _exporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.archive_outlined),
                title: Text(_exporting
                    ? l10n.exportRunning
                    : l10n.exportZip),
                trailing: _exporting
                    ? null
                    : const Icon(Icons.chevron_right),
                onTap: _exporting ? null : () => _runExport(l10n),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editor color picker tile
// ---------------------------------------------------------------------------

class _EditorColorTile extends ConsumerWidget {
  final InkwellEditorColor current;
  const _EditorColorTile({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final options = [
      (InkwellEditorColor.auto, l10n.settingsEditorColorAuto),
      (InkwellEditorColor.offWhite, l10n.settingsEditorColorOffWhite),
      (InkwellEditorColor.amber, l10n.settingsEditorColorAmber),
      (InkwellEditorColor.mint, l10n.settingsEditorColorMint),
    ];

    return ListTile(
      leading: const Icon(Icons.color_lens_outlined),
      title: Text(l10n.settingsEditorColor),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.map((opt) {
            final (color, label) = opt;
            final selected = color == current;
            return _ColorChip(
              color: color,
              label: label,
              selected: selected,
              onTap: () => ref
                  .read(settingsProvider.notifier)
                  .setEditorTextColor(color),
            );
          }).toList(),
        ),
      ),
      isThreeLine: true,
    );
  }
}

class _ColorChip extends StatelessWidget {
  final InkwellEditorColor color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedColor = color.toColor();

    final Widget swatch = resolvedColor != null
        ? CircleAvatar(radius: 10, backgroundColor: resolvedColor)
        : CircleAvatar(
            radius: 10,
            backgroundColor: Colors.white,
            child: CircleAvatar(radius: 7, backgroundColor: Colors.black87),
          );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch,
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
