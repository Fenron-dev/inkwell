import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import 'package:file_picker/file_picker.dart';

import '../../core/export/export_service.dart';
import '../../core/export/import_service.dart';
import '../../core/security/lock_provider.dart';
import '../../core/settings/settings_provider.dart';
import '../../core/vault/vault_path_helper.dart';
import '../../core/vault/vault_provider.dart';
import '../../theme/app_theme.dart';
import '../lock/pin_setup_screen.dart';
import 'template_editor_screen.dart';

/// Settings screen for theme, font, language, vault configuration and export.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _exporting = false;
  bool _importing = false;
  bool _changingVault = false;

  Future<void> _changeVault(AppLocalizations l10n) async {
    if (!VaultPathHelper.canPickDirectory) return;
    final picked = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.settingsVaultPickTitle,
    );
    if (picked == null || !mounted) return;

    setState(() => _changingVault = true);
    try {
      final config = await ref.read(vaultProvider.notifier).openVault(picked);
      if (!mounted) return;
      if (config == null) {
        _showSnackbar(l10n.settingsVaultChangeFailed);
      }
    } catch (e) {
      if (mounted) _showSnackbar(l10n.settingsVaultChangeFailed);
    } finally {
      if (mounted) setState(() => _changingVault = false);
    }
  }

  Future<void> _runImport(AppLocalizations l10n) async {
    setState(() => _importing = true);
    try {
      final result = await ImportService().importZip();
      if (!mounted) return;
      if (result == null) {
        _showSnackbar(l10n.importCancelled);
      } else {
        await ref.read(vaultProvider.notifier).openVault(result.vaultPath);
        ref.invalidate(recentVaultsProvider);
        if (mounted) _showSnackbar(l10n.importDone(result.vaultPath));
      }
    } catch (e) {
      if (mounted) _showSnackbar(l10n.importError(e.toString()));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

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
    final recentVaults = ref.watch(recentVaultsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: settings.when(
        data: (s) => ListView(
          children: [
            // Vault path
            if (vault != null)
              ListTile(
                leading: _changingVault
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_outlined),
                title: Text(l10n.settingsVaultPath),
                subtitle: Text(
                  vault.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: VaultPathHelper.canPickDirectory && !_changingVault
                    ? TextButton(
                        onPressed: () => _changeVault(l10n),
                        child: Text(l10n.settingsVaultChange),
                      )
                    : null,
              ),

            // Recent vaults
            recentVaults.when(
              data: (recents) {
                // Filter out the currently open vault
                final others = recents
                    .where((p) => vault == null || p != vault.path)
                    .toList();
                if (others.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        l10n.settingsRecentVaults,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                    ...others.map((path) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.folder_open_outlined),
                          title: Text(
                            path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: TextButton(
                            onPressed: () async {
                              setState(() => _changingVault = true);
                              try {
                                final config = await ref
                                    .read(vaultProvider.notifier)
                                    .openVault(path);
                                if (mounted && config == null) {
                                  _showSnackbar(
                                      l10n.settingsVaultChangeFailed);
                                }
                              } catch (_) {
                                if (mounted) {
                                  _showSnackbar(
                                      l10n.settingsVaultChangeFailed);
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _changingVault = false);
                                }
                              }
                            },
                            child: Text(l10n.settingsVaultSwitch),
                          ),
                        )),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const Divider(),

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

            // App Lock
            _AppLockSection(),
            const Divider(),

            // Template editor
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.templateEditorTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const TemplateEditorScreen()),
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
                title: Text(_exporting ? l10n.exportRunning : l10n.exportZip),
                trailing: _exporting ? null : const Icon(Icons.chevron_right),
                onTap: _exporting ? null : () => _runExport(l10n),
              ),

            // Import
            ListTile(
              leading: _importing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.unarchive_outlined),
              title: Text(_importing ? l10n.importRunning : l10n.importZip),
              trailing: _importing ? null : const Icon(Icons.chevron_right),
              onTap: _importing ? null : () => _runImport(l10n),
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
// App Lock section
// ---------------------------------------------------------------------------

class _AppLockSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lock = ref.watch(lockProvider);

    void pushSetup(PinSetupMode mode) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PinSetupScreen(mode: mode)),
      );
    }

    if (!lock.hasPIN) {
      return ListTile(
        leading: const Icon(Icons.lock_outline),
        title: Text(l10n.settingsLock),
        subtitle: Text(l10n.settingsLockEnable),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => pushSetup(PinSetupMode.setup),
      );
    }

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.lock),
          title: Text(l10n.settingsLock),
          subtitle: Text(l10n.settingsLockActive),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => pushSetup(PinSetupMode.change),
                child: Text(l10n.lockChangePIN),
              ),
              TextButton(
                onPressed: () => pushSetup(PinSetupMode.remove),
                child: Text(
                  l10n.lockRemovePIN,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ),
        if (lock.biometricsAvailable)
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: Text(l10n.settingsLockBiometrics),
            subtitle: Text(l10n.settingsLockBiometricsHint),
            value: lock.biometricsEnabled,
            onChanged: (v) =>
                ref.read(lockProvider.notifier).setBiometricsEnabled(v),
          ),
      ],
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
