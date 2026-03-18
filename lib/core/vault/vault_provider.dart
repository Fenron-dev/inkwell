import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/vault_config.dart';
import 'vault_service.dart';

/// Provides the VaultService singleton.
final vaultServiceProvider = Provider<VaultService>((ref) => VaultService());

/// Persists and loads the last-used vault path.
class _VaultStorage {
  static Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/inkwell_vault.json');
  }

  static Future<String?> loadLastVaultPath() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        return json['lastVaultPath'] as String?;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> saveLastVaultPath(String path) async {
    final file = await _file;
    await file.writeAsString(jsonEncode({'lastVaultPath': path}));
  }
}

/// Manages the current vault state.
///
/// States: null (no vault) → VaultConfig (vault open).
class VaultNotifier extends AsyncNotifier<VaultConfig?> {
  @override
  Future<VaultConfig?> build() async {
    final lastPath = await _VaultStorage.loadLastVaultPath();
    if (lastPath == null) return null;

    final service = ref.read(vaultServiceProvider);
    return service.openVault(lastPath);
  }

  Future<VaultConfig> createVault(String path, String name) async {
    state = const AsyncLoading();
    final service = ref.read(vaultServiceProvider);
    final config = await service.createVault(path, name);
    await _VaultStorage.saveLastVaultPath(path);
    state = AsyncData(config);
    return config;
  }

  Future<VaultConfig?> openVault(String path) async {
    state = const AsyncLoading();
    final service = ref.read(vaultServiceProvider);
    final config = await service.openVault(path);
    if (config != null) {
      await _VaultStorage.saveLastVaultPath(path);
    }
    state = AsyncData(config);
    return config;
  }

  void closeVault() {
    state = const AsyncData(null);
  }
}

final vaultProvider =
    AsyncNotifierProvider<VaultNotifier, VaultConfig?>(VaultNotifier.new);
