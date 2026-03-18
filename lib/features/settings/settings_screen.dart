import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../../core/settings/settings_provider.dart';
import '../../theme/app_theme.dart';

/// Settings screen for theme, font, language, and vault configuration.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: settings.when(
        data: (s) => ListView(
          children: [
            // Theme
            ListTile(
              leading: const Icon(Icons.palette),
              title: Text(l10n.settingsTheme),
              trailing: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.settingsThemeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.settingsThemeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.settingsThemeDark),
                  ),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (modes) {
                  ref.read(settingsProvider.notifier).setThemeMode(modes.first);
                },
              ),
            ),
            const Divider(),
            // Font
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: Text(l10n.settingsFont),
              trailing: DropdownButton<InkwellFont>(
                value: s.font,
                underline: const SizedBox.shrink(),
                onChanged: (font) {
                  if (font != null) {
                    ref.read(settingsProvider.notifier).setFont(font);
                  }
                },
                items: InkwellFont.values
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.displayName),
                        ))
                    .toList(),
              ),
            ),
            const Divider(),
            // Language
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.settingsLanguage),
              trailing: DropdownButton<Locale>(
                value: s.locale,
                underline: const SizedBox.shrink(),
                onChanged: (locale) {
                  if (locale != null) {
                    ref.read(settingsProvider.notifier).setLocale(locale);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: Locale('en'),
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: Locale('de'),
                    child: Text('Deutsch'),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
