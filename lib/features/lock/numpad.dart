import 'package:flutter/material.dart';

/// Circular digit button for PIN numpad.
class NumpadDigitKey extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;
  const NumpadDigitKey({super.key, required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(shape: const CircleBorder()),
        child: Text(digit, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

/// Circular icon button for PIN numpad (biometrics, backspace, etc.).
class NumpadIconKey extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const NumpadIconKey({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: IconButton(
        onPressed: onTap,
        iconSize: 28,
        icon: Icon(icon),
      ),
    );
  }
}
