import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../../core/security/lock_provider.dart';
import 'numpad.dart';

/// Full-screen PIN entry shown when the app is locked.
///
/// If biometrics are enabled the fingerprint screen is shown first;
/// the PIN pad is only revealed when biometrics fail or the user
/// explicitly requests it ("Enter PIN" button).
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  static const _pinLength = 4;

  String _pin = '';
  bool _error = false;

  /// `true` while the biometric prompt should be shown instead of the numpad.
  bool _biometricsPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lock = ref.read(lockProvider);
      if (lock.biometricsEnabled) {
        setState(() => _biometricsPending = true);
        _tryBiometrics();
      }
    });
  }

  Future<void> _tryBiometrics() async {
    if (!mounted) return;
    setState(() => _biometricsPending = true);
    final l10n = AppLocalizations.of(context)!;
    final success = await ref
        .read(lockProvider.notifier)
        .tryBiometrics(l10n.lockBiometricReason);
    // On success GoRouter redirect fires automatically.
    // On failure / cancel → fall back to PIN pad.
    if (!success && mounted) {
      setState(() => _biometricsPending = false);
    }
  }

  void _onDigit(String digit) {
    if (_pin.length >= _pinLength) return;
    setState(() {
      _pin += digit;
      _error = false;
    });
    if (_pin.length == _pinLength) _submit();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    final ok = await ref.read(lockProvider.notifier).tryPIN(_pin);
    if (!ok && mounted) {
      setState(() {
        _pin = '';
        _error = true;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lock = ref.watch(lockProvider);
    final scheme = Theme.of(context).colorScheme;

    if (_biometricsPending) {
      return _buildBiometricScreen(context, l10n, scheme);
    }
    return _buildPinScreen(context, l10n, lock, scheme);
  }

  // ---------------------------------------------------------------------------
  // Biometric waiting screen
  // ---------------------------------------------------------------------------

  Widget _buildBiometricScreen(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme scheme,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Icon(Icons.lock_outline, size: 52, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              l10n.lockBiometricReason,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 48),
            IconButton(
              iconSize: 80,
              icon: Icon(Icons.fingerprint, color: scheme.primary),
              tooltip: l10n.lockBiometricReason,
              onPressed: _tryBiometrics,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.lockBiometricHint,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.outline),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _biometricsPending = false),
              child: Text(l10n.lockEnterPIN),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PIN pad screen
  // ---------------------------------------------------------------------------

  Widget _buildPinScreen(
    BuildContext context,
    AppLocalizations l10n,
    LockState lock,
    ColorScheme scheme,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Icon(Icons.lock_outline, size: 52, color: scheme.primary),
            const SizedBox(height: 16),
            Text(l10n.lockEnterPIN,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 32),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final filled = i < _pin.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _error
                          ? scheme.error
                          : filled
                              ? scheme.primary
                              : Colors.transparent,
                      border: Border.all(
                        color: _error ? scheme.error : scheme.outline,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }),
            ),

            if (_error) ...[
              const SizedBox(height: 14),
              Text(
                l10n.lockWrongPIN,
                style: TextStyle(color: scheme.error),
              ),
            ],

            const Spacer(),

            // Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: row
                          .map((d) => NumpadDigitKey(
                              digit: d, onTap: () => _onDigit(d)))
                          .toList(),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      lock.biometricsEnabled
                          ? NumpadIconKey(
                              icon: Icons.fingerprint,
                              onTap: _tryBiometrics,
                            )
                          : const SizedBox(width: 72, height: 72),
                      NumpadDigitKey(
                          digit: '0', onTap: () => _onDigit('0')),
                      NumpadIconKey(
                        icon: Icons.backspace_outlined,
                        onTap: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
