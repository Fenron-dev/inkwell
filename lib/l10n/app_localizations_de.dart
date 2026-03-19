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
  String get propertiesToggle => 'Eigenschaften';

  @override
  String get searchHint => 'Einträge durchsuchen...';

  @override
  String get searchNoResults => 'Keine Einträge gefunden.';

  @override
  String get searchIndexing => 'Einträge werden indiziert…';

  @override
  String get searchIndexReady => 'Index aktuell';

  @override
  String searchIndexUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge indiziert',
      one: '1 Eintrag indiziert',
    );
    return '$_temp0';
  }

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
  String get settingsEditorColor => 'Editor-Schriftfarbe';

  @override
  String get settingsEditorColorAuto => 'Automatisch';

  @override
  String get settingsEditorColorOffWhite => 'Cremeweiß';

  @override
  String get settingsEditorColorAmber => 'Bernstein';

  @override
  String get settingsEditorColorMint => 'Mint';

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
  String get tagAddHint => 'Tag hinzufügen…';

  @override
  String get frontmatterLocation => 'Ort';

  @override
  String get exportZip => 'Als ZIP exportieren';

  @override
  String get exportRunning => 'ZIP-Archiv wird erstellt…';

  @override
  String exportDone(String path) {
    return 'Gespeichert: $path';
  }

  @override
  String get exportCancelled => 'Export abgebrochen.';

  @override
  String exportError(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get lockEnterPIN => 'PIN eingeben';

  @override
  String get lockBiometricReason => 'Inkwell entsperren';

  @override
  String get lockWrongPIN => 'Falscher PIN';

  @override
  String get lockSetupTitle => 'PIN einrichten';

  @override
  String get lockSetupEnterNew => 'Neuen PIN eingeben';

  @override
  String get lockSetupConfirm => 'PIN bestätigen';

  @override
  String get lockSetupNoMatch => 'PINs stimmen nicht überein';

  @override
  String get lockSetupDone => 'PIN gespeichert';

  @override
  String get lockChangePIN => 'PIN ändern';

  @override
  String get lockRemovePIN => 'PIN entfernen';

  @override
  String get lockRemoveCurrentHint => 'Aktuellen PIN eingeben zum Entfernen';

  @override
  String get lockRemoveDone => 'PIN entfernt';

  @override
  String get lockRemoveWrong => 'Falscher PIN — konnte nicht entfernen';

  @override
  String get settingsLock => 'App-Sperre';

  @override
  String get settingsLockEnable => 'PIN-Sperre aktivieren';

  @override
  String get settingsLockActive => 'PIN aktiv';

  @override
  String get settingsLockBiometrics => 'Biometrie nutzen';

  @override
  String get settingsLockBiometricsHint => 'Fingerabdruck / Face ID';

  @override
  String get settingsVaultPickTitle => 'Vault-Ordner wählen';

  @override
  String get settingsVaultChange => 'Vault wechseln';

  @override
  String get settingsVaultChangeFailed =>
      'Ordner konnte nicht als Vault geöffnet werden.';

  @override
  String get deleteEntryTitle => 'Eintrag löschen?';

  @override
  String get deleteEntryHint =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get deleteEntryTooltip => 'Eintrag löschen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get ok => 'OK';

  @override
  String get templateEditorTitle => 'Vorlage bearbeiten';

  @override
  String get templateEditorHint => 'Schreibe hier deine tägliche Vorlage…';

  @override
  String get templateSaved => 'Vorlage gespeichert';
}
