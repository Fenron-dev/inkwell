import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lock_service.dart';

class LockState {
  final bool isLocked;
  final bool hasPIN;
  final bool biometricsAvailable;
  final bool biometricsEnabled;

  const LockState({
    required this.isLocked,
    required this.hasPIN,
    required this.biometricsAvailable,
    required this.biometricsEnabled,
  });

  LockState copyWith({
    bool? isLocked,
    bool? hasPIN,
    bool? biometricsAvailable,
    bool? biometricsEnabled,
  }) =>
      LockState(
        isLocked: isLocked ?? this.isLocked,
        hasPIN: hasPIN ?? this.hasPIN,
        biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
        biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      );
}

class LockNotifier extends Notifier<LockState> {
  final _service = LockService();

  @override
  LockState build() {
    _init();
    return const LockState(
      isLocked: false,
      hasPIN: false,
      biometricsAvailable: false,
      biometricsEnabled: false,
    );
  }

  Future<void> _init() async {
    final hasPIN = await _service.hasPIN();
    final bioAvailable = await _service.biometricsAvailable();
    final bioEnabled = bioAvailable && await _service.biometricsEnabled();
    state = LockState(
      isLocked: hasPIN,
      hasPIN: hasPIN,
      biometricsAvailable: bioAvailable,
      biometricsEnabled: bioEnabled,
    );
  }

  /// Lock the app (only has effect when a PIN is set).
  void lock() {
    if (state.hasPIN) state = state.copyWith(isLocked: true);
  }

  /// Mark the app as unlocked.
  void unlock() => state = state.copyWith(isLocked: false);

  /// Try unlocking with [pin]. Returns true if correct.
  Future<bool> tryPIN(String pin) async {
    final ok = await _service.checkPIN(pin);
    if (ok) unlock();
    return ok;
  }

  /// Try unlocking with biometrics. Returns true on success.
  Future<bool> tryBiometrics(String localizedReason) async {
    final ok = await _service.authenticateWithBiometrics(localizedReason);
    if (ok) unlock();
    return ok;
  }

  /// Set up a new PIN (replaces any existing one).
  Future<void> setupPIN(String pin) async {
    await _service.setPIN(pin);
    state = state.copyWith(hasPIN: true, isLocked: false);
  }

  /// Verify current PIN, then remove it. Returns false if pin is wrong.
  Future<bool> removePIN(String currentPin) async {
    if (!await _service.checkPIN(currentPin)) return false;
    await _service.removePIN();
    state = state.copyWith(
      hasPIN: false,
      isLocked: false,
      biometricsEnabled: false,
    );
    return true;
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _service.setBiometricsEnabled(enabled);
    state = state.copyWith(biometricsEnabled: enabled);
  }
}

final lockProvider =
    NotifierProvider<LockNotifier, LockState>(LockNotifier.new);
