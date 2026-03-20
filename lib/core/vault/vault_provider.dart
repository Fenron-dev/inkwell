import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/vault_config.dart';
import 'vault_service.dart';

/// Provides the VaultService singleton.
final vaultServiceProvider = Provider<VaultService>((ref) => VaultService());

/// Persists and loads the last-used vault path and the recent-vaults list.
class _VaultStorage {
  static const _maxRecent = 5;

  static Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/inkwell_vault.json');
  }

  static Future<Map<String, dynamic>> _load() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}
    return {};
  }

  static Future<void> _save(Map<String, dynamic> data) async {
    final file = await _file;
    await file.writeAsString(jsonEncode(data));
  }

  static Future<String?> loadLastVaultPath() async {
    final data = await _load();
    return data['lastVaultPath'] as String?;
  }

  static Future<List<String>> loadRecentVaults() async {
    final data = await _load();
    final raw = data['recentVaults'];
    if (raw is List) return raw.cast<String>();
    return [];
  }

  static Future<void> saveLastVaultPath(String path) async {
    final data = await _load();
    final recent = List<String>.from(
      (data['recentVaults'] as List? ?? []).cast<String>(),
    )
      ..remove(path)
      ..insert(0, path);
    if (recent.length > _maxRecent) recent.length = _maxRecent;
    data['lastVaultPath'] = path;
    data['recentVaults'] = recent;
    await _save(data);
  }
}

/// Manages the current vault state.
///
/// States: null (no vault) → VaultConfig (vault open).
class VaultNotifier extends AsyncNotifier<VaultConfig?> {
  @override
  Future<VaultConfig?> build() async {
    final lastPath = await _VaultStorage.loadLastVaultPath();
    if (lastPath == null || lastPath.isEmpty) return null;

    final service = ref.read(vaultServiceProvider);
    try {
      return await service.openVault(lastPath);
    } catch (_) {
      // Saved path is no longer valid (e.g. permissions changed, path removed).
      // Clear it so the setup screen is shown instead of crashing.
      await _VaultStorage.saveLastVaultPath('');
      return null;
    }
  }

  Future<VaultConfig> createVault(String path, String name) async {
    state = const AsyncLoading();
    try {
      final service = ref.read(vaultServiceProvider);
      final config = await service.createVault(path, name);
      await _VaultStorage.saveLastVaultPath(path);
      state = AsyncData(config);
      return config;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<VaultConfig?> openVault(String path) async {
    state = const AsyncLoading();
    try {
      final service = ref.read(vaultServiceProvider);
      final config = await service.openVault(path);
      if (config != null) {
        await _VaultStorage.saveLastVaultPath(path);
      }
      state = AsyncData(config);
      return config;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  void closeVault() {
    state = const AsyncData(null);
  }
}

final vaultProvider =
    AsyncNotifierProvider<VaultNotifier, VaultConfig?>(VaultNotifier.new);

/// Ordered list of recently opened vault paths (most recent first, max 5).
final recentVaultsProvider = FutureProvider<List<String>>(
  (_) => _VaultStorage.loadRecentVaults(),
);
