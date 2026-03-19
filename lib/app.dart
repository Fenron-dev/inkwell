import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkwell/l10n/app_localizations.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'app_router.dart';
import 'core/security/lock_provider.dart';
import 'core/settings/settings_provider.dart';
import 'core/sharing/sharing_provider.dart';
import 'core/utils/url_utils.dart';
import 'theme/app_theme.dart';

class InkwellApp extends ConsumerStatefulWidget {
  const InkwellApp({super.key});

  @override
  ConsumerState<InkwellApp> createState() => _InkwellAppState();
}

class _InkwellAppState extends ConsumerState<InkwellApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: () => ref.read(lockProvider.notifier).lock(),
      onDetach: () => ref.read(lockProvider.notifier).lock(),
    );

    if (Platform.isAndroid || Platform.isIOS) {
      _initShareIntent();
    }
  }

  void _initShareIntent() {
    // Handle URLs shared while app is already running.
    ReceiveSharingIntent.instance.getMediaStream().listen((items) {
      final text = items
          .where((i) => i.type == SharedMediaType.text)
          .map((i) => i.path)
          .firstOrNull;
      if (text != null) _handleSharedText(text);
    });

    // Handle the URL that launched the app via share.
    ReceiveSharingIntent.instance.getInitialMedia().then((items) {
      final text = items
          .where((i) => i.type == SharedMediaType.text)
          .map((i) => i.path)
          .firstOrNull;
      if (text != null) _handleSharedText(text);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _handleSharedText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // If the shared text contains a URL use that; otherwise pass raw text.
    final urls = extractUrls(trimmed);
    final payload = urls.isNotEmpty ? urls.first : trimmed;
    ref.read(pendingShareProvider.notifier).state = payload;
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
