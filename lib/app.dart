import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import 'app_router.dart';
import 'core/settings/settings_provider.dart';
import 'theme/app_theme.dart';

class InkwellApp extends ConsumerWidget {
  const InkwellApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    final themeMode = settings.valueOrNull?.themeMode ?? ThemeMode.system;
    final font = settings.valueOrNull?.font ?? InkwellFont.inter;
    final locale = settings.valueOrNull?.locale ?? const Locale('de');

    return MaterialApp.router(
      title: 'Inkwell',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(font: font),
      darkTheme: AppTheme.dark(font: font),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
