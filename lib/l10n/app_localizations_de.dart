// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Inkwell';

  @override
  String get welcomeTitle => 'Willkommen bei Inkwell';

  @override
  String get welcomeSubtitle =>
      'Dein privates Journal, gespeichert auf deinem Gerät.';

  @override
  String get navDaily => 'Heute';

  @override
  String get navCalendar => 'Kalender';

  @override
  String get navSearch => 'Suche';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get editorPlaceholder => 'Fang an zu schreiben...';

  @override
  String get editorPreview => 'Vorschau';

  @override
  String get editorEdit => 'Bearbeiten';

  @override
  String get editorSplitView => 'Geteilte Ansicht';

  @override
  String get searchHint => 'Einträge durchsuchen...';

  @override
  String get searchNoResults => 'Keine Einträge gefunden.';

  @override
  String get calendarToday => 'Heute';

  @override
  String calendarEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
      zero: 'Keine Einträge',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsVaultPath => 'Vault-Pfad';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsFont => 'Schriftart';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get vaultCreate => 'Neuen Vault erstellen';

  @override
  String get vaultOpen => 'Bestehenden Ordner öffnen';

  @override
  String get vaultChooseLocation => 'Wähle einen Speicherort für dein Journal';

  @override
  String get frontmatterMood => 'Stimmung';

  @override
  String get frontmatterEnergy => 'Energie';

  @override
  String get frontmatterSleep => 'Schlaf';

  @override
  String get frontmatterTags => 'Tags';

  @override
  String get frontmatterLocation => 'Ort';

  @override
  String get exportZip => 'Als ZIP exportieren';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get ok => 'OK';
}
