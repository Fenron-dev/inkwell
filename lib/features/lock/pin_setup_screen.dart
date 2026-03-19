import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../../core/security/lock_provider.dart';
import 'numpad.dart';

enum PinSetupMode { setup, change, remove }

/// Full-screen PIN entry for setting up, changing, or removing a PIN.
///
/// Push this on top of the current route via [Navigator.push].
class PinSetupScreen extends ConsumerStatefulWidget {
  final PinSetupMode mode;
  const PinSetupScreen({super.key, required this.mode});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  static const _pinLength = 4;

  // For setup/change: step 0 = enter new, step 1 = confirm.
  // For remove: step 0 = enter current.
  // For change: step -1 = verify current first.
  int _step = 0;
  String _pin = '';
  String _firstPin = '';
  bool _error = false;

  @override
  void initState() {
    super.initState();
    // change mode starts by verifying the current PIN
    if (widget.mode == PinSetupMode.change) _step = -1;
  }

  String _prompt(AppLocalizations l10n) {
    if (widget.mode == PinSetupMode.remove) return l10n.lockRemoveCurrentHint;
    if (widget.mode == PinSetupMode.change && _step == -1) {
      return l10n.lockRemoveCurrentHint;
    }
    return _step == 0 ? l10n.lockSetupEnterNew : l10n.lockSetupConfirm;
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
    final l10n = AppLocalizations.of(context)!;

    // --- Remove PIN ---
    if (widget.mode == PinSetupMode.remove) {
      final ok = await ref.read(lockProvider.notifier).removePIN(_pin);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.lockRemoveDone)));
      } else {
        setState(() {
          _pin = '';
          _error = true;
        });
      }
      return;
    }

    // --- Change PIN: verify current ---
    if (widget.mode == PinSetupMode.change && _step == -1) {
      final ok = await ref.read(lockProvider.notifier).tryPIN(_pin);
      // tryPIN calls unlock() on success — lock again so we stay in setup.
      if (ok) ref.read(lockProvider.notifier).lock();
      if (!mounted) return;
      if (ok) {
        setState(() {
          _step = 0;
          _pin = '';
          _error = false;
        });
      } else {
        setState(() {
          _pin = '';
          _error = true;
        });
      }
      return;
    }

    // --- Setup / change: enter new PIN ---
    if (_step == 0) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _step = 1;
      });
      return;
    }

    // --- Confirm PIN ---
    if (_pin == _firstPin) {
      await ref.read(lockProvider.notifier).setupPIN(_pin);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.lockSetupDone)));
    } else {
      setState(() {
        _step = 0;
        _pin = '';
        _firstPin = '';
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == PinSetupMode.remove
            ? l10n.lockRemovePIN
            : widget.mode == PinSetupMode.change
                ? l10n.lockChangePIN
                : l10n.lockSetupTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text(_prompt(l10n),
                style: Theme.of(context).textTheme.titleMedium),
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
                widget.mode == PinSetupMode.remove ||
                        (widget.mode == PinSetupMode.change && _step == -1)
                    ? l10n.lockRemoveWrong
                    : l10n.lockSetupNoMatch,
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
                          .map((d) =>
                              NumpadDigitKey(digit: d, onTap: () => _onDigit(d)))
                          .toList(),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 72, height: 72),
                      NumpadDigitKey(digit: '0', onTap: () => _onDigit('0')),
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
