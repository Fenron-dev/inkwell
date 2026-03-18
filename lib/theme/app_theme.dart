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

  TextStyle get textStyle => switch (this) {
        InkwellFont.inter => GoogleFonts.inter(),
        InkwellFont.merriweather => GoogleFonts.merriweather(),
        InkwellFont.jetBrainsMono => GoogleFonts.jetBrainsMono(),
        InkwellFont.lora => GoogleFonts.lora(),
        InkwellFont.openDyslexic => GoogleFonts.openSans(), // Placeholder — bundle OpenDyslexic as asset later
      };
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
    final baseTextTheme = font.textStyle.fontFamily != null
        ? GoogleFonts.getTextTheme(font.textStyle.fontFamily!)
        : const TextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: baseTextTheme,
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
}
