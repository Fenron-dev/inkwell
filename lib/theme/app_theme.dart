import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Preset editor text colors the user can choose from.
enum InkwellEditorColor {
  /// Follow the active theme (white in dark mode, dark in light mode).
  auto,

  /// Off-white — comfortable on dark backgrounds.
  offWhite,

  /// Warm amber — vintage terminal feel.
  amber,

  /// Soft green — classic green-screen aesthetic.
  mint;

  /// Returns the actual [Color] to use, or null for [auto] (theme default).
  Color? toColor() => switch (this) {
        InkwellEditorColor.auto => null,
        InkwellEditorColor.offWhite => const Color(0xFFEEEAD8),
        InkwellEditorColor.amber => const Color(0xFFFFBF47),
        InkwellEditorColor.mint => const Color(0xFF9CF0B4),
      };
}

/// Available editor fonts the user can choose from.
enum InkwellFont {
  inter('Inter'),
  merriweather('Merriweather'),
  jetBrainsMono('JetBrains Mono'),
  lora('Lora'),
  openDyslexic('OpenDyslexic');

  final String displayName;
  const InkwellFont(this.displayName);
}

class AppTheme {
  static const _seedColor = Color(0xFF3D5A80);

  static ThemeData light({InkwellFont font = InkwellFont.inter}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return _buildTheme(colorScheme, font);
  }

  static ThemeData dark({InkwellFont font = InkwellFont.inter}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return _buildTheme(colorScheme, font);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, InkwellFont font) {
    // Pass the correct brightness base so Google Fonts only changes the
    // typeface while the theme-appropriate text colors are preserved.
    final baseTextTheme = colorScheme.brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textThemeFor(font, baseTextTheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        indicatorColor: colorScheme.primaryContainer,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.primaryContainer,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
      ),
    );
  }

  /// Returns the correct TextTheme for a given font by calling the
  /// specific google_fonts method — avoids passing internal asset paths
  /// to getTextTheme() which would throw an exception.
  static TextTheme _textThemeFor(InkwellFont font, TextTheme base) =>
      switch (font) {
        InkwellFont.inter => GoogleFonts.interTextTheme(base),
        InkwellFont.merriweather => GoogleFonts.merriweatherTextTheme(base),
        InkwellFont.jetBrainsMono => GoogleFonts.jetBrainsMonoTextTheme(base),
        InkwellFont.lora => GoogleFonts.loraTextTheme(base),
        InkwellFont.openDyslexic => base, // not a Google Font — keep base colors
      };
}
