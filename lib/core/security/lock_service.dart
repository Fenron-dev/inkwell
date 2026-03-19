import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Handles PIN storage (SHA-256 hashed) and biometric authentication.
class LockService {
  static const _pinKey = 'inkwell_pin_hash';
  static const _bioKey = 'inkwell_bio_enabled';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final _auth = LocalAuthentication();

  Future<bool> hasPIN() => _storage.containsKey(key: _pinKey);

  Future<void> setPIN(String pin) =>
      _storage.write(key: _pinKey, value: _hash(pin));

  Future<bool> checkPIN(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null && stored == _hash(pin);
  }

  Future<void> removePIN() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _bioKey);
  }

  Future<bool> biometricsAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> biometricsEnabled() async {
    final val = await _storage.read(key: _bioKey);
    return val == 'true';
  }

  Future<void> setBiometricsEnabled(bool enabled) =>
      _storage.write(key: _bioKey, value: enabled.toString());

  Future<bool> authenticateWithBiometrics(String localizedReason) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (_) {
      return false;
    }
  }

  static String _hash(String pin) =>
      sha256.convert(utf8.encode(pin)).toString();
}
