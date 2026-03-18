import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../../core/vault/vault_path_helper.dart';
import '../../core/vault/vault_provider.dart';

/// First-run screen shown when no vault is configured.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _createNewVault() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String vaultPath;

      if (VaultPathHelper.canPickDirectory) {
        // Desktop: let user choose where to create the vault
        final picked = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Ordner für neuen Vault wählen',
        );
        if (picked == null) {
          setState(() => _loading = false);
          return;
        }
        vaultPath = picked;
      } else {
        // Mobile: use a safe, always-writable default path
        vaultPath = await VaultPathHelper.defaultVaultPath();
      }

      await ref.read(vaultProvider.notifier).createVault(vaultPath, 'Mein Journal');
      if (mounted) context.go('/daily');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openExistingVault() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String? vaultPath;

      if (VaultPathHelper.canPickDirectory) {
        vaultPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Vault-Ordner öffnen',
        );
        if (vaultPath == null) {
          setState(() => _loading = false);
          return;
        }
      } else {
        // Mobile: try the default path if it already exists
        vaultPath = await VaultPathHelper.defaultVaultPath();
      }

      final config = await ref.read(vaultProvider.notifier).openVault(vaultPath);
      if (mounted) {
        if (config != null) {
          context.go('/daily');
        } else {
          setState(() {
            _error = 'Ordner konnte nicht als Vault geöffnet werden.';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canPick = VaultPathHelper.canPickDirectory;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.auto_stories,
                          size: 72,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n?.welcomeTitle ?? 'Willkommen bei Inkwell',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n?.welcomeSubtitle ??
                              'Dein privates Journal, gespeichert auf deinem Gerät.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        FilledButton.icon(
                          icon: Icon(canPick
                              ? Icons.create_new_folder_outlined
                              : Icons.add_circle_outline),
                          label: Text(l10n?.vaultCreate ?? 'Neuen Vault erstellen'),
                          onPressed: _createNewVault,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.folder_open),
                          label: Text(l10n?.vaultOpen ?? 'Bestehenden Vault öffnen'),
                          onPressed: _openExistingVault,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _error!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
