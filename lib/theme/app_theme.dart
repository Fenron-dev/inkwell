import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textThemeFor(font),
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
  static TextTheme _textThemeFor(InkwellFont font) => switch (font) {
        InkwellFont.inter => GoogleFonts.interTextTheme(),
        InkwellFont.merriweather => GoogleFonts.merriweatherTextTheme(),
        InkwellFont.jetBrainsMono => GoogleFonts.jetBrainsMonoTextTheme(),
        InkwellFont.lora => GoogleFonts.loraTextTheme(),
        InkwellFont.openDyslexic =>
          const TextTheme(), // OpenDyslexic is not a Google Font — use system font
      };
}
