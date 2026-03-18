import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../theme/app_theme.dart';

/// App-level settings (theme, font, locale, etc.)
class AppSettings {
  final ThemeMode themeMode;
  final InkwellFont font;
  final Locale locale;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.font = InkwellFont.inter,
    this.locale = const Locale('en'),
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    InkwellFont? font,
    Locale? locale,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      font: font ?? this.font,
      locale: locale ?? this.locale,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.index,
        'font': font.name,
        'locale': locale.languageCode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
      font: InkwellFont.values.firstWhere(
        (f) => f.name == json['font'],
        orElse: () => InkwellFont.inter,
      ),
      locale: Locale(json['locale'] as String? ?? 'en'),
    );
  }
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    return _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/inkwell_settings.json');
  }

  Future<AppSettings> _load() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        return AppSettings.fromJson(json as Map<String, dynamic>);
      }
    } catch (_) {}
    return const AppSettings();
  }

  Future<void> _save(AppSettings settings) async {
    final file = await _file;
    await file.writeAsString(jsonEncode(settings.toJson()));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(themeMode: mode);
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> setFont(InkwellFont font) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(font: font);
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> setLocale(Locale locale) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(locale: locale);
    state = AsyncData(updated);
    await _save(updated);
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
