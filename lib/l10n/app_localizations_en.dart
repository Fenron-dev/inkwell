// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Inkwell';

  @override
  String get welcomeTitle => 'Welcome to Inkwell';

  @override
  String get welcomeSubtitle => 'Your private journal, stored on your device.';

  @override
  String get navDaily => 'Today';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navSearch => 'Search';

  @override
  String get navSettings => 'Settings';

  @override
  String get editorPlaceholder => 'Start writing...';

  @override
  String get editorPreview => 'Preview';

  @override
  String get editorEdit => 'Edit';

  @override
  String get editorSplitView => 'Split View';

  @override
  String get propertiesToggle => 'Properties';

  @override
  String get searchHint => 'Search entries...';

  @override
  String get searchNoResults => 'No entries found.';

  @override
  String get searchIndexing => 'Indexing entries…';

  @override
  String get searchIndexReady => 'Index up to date';

  @override
  String searchIndexUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries indexed',
      one: '1 entry indexed',
    );
    return '$_temp0';
  }

  @override
  String get calendarToday => 'Today';

  @override
  String calendarEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'No entries',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsVaultPath => 'Vault Path';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsFont => 'Font';

  @override
  String get settingsEditorColor => 'Editor Text Color';

  @override
  String get settingsEditorColorAuto => 'Auto';

  @override
  String get settingsEditorColorOffWhite => 'Off-white';

  @override
  String get settingsEditorColorAmber => 'Amber';

  @override
  String get settingsEditorColorMint => 'Mint';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get vaultCreate => 'Create New Vault';

  @override
  String get vaultOpen => 'Open Existing Folder';

  @override
  String get vaultChooseLocation => 'Choose a location for your journal';

  @override
  String get frontmatterMood => 'Mood';

  @override
  String get frontmatterEnergy => 'Energy';

  @override
  String get frontmatterSleep => 'Sleep';

  @override
  String get frontmatterTags => 'Tags';

  @override
  String get tagAddHint => 'Add tag…';

  @override
  String get frontmatterLocation => 'Location';

  @override
  String get exportZip => 'Export as ZIP';

  @override
  String get exportRunning => 'Creating ZIP archive…';

  @override
  String exportDone(String path) {
    return 'Saved: $path';
  }

  @override
  String get exportCancelled => 'Export cancelled.';

  @override
  String exportError(String error) {
    return 'Export failed: $error';
  }

  @override
  String get lockEnterPIN => 'Enter PIN';

  @override
  String get lockBiometricReason => 'Unlock Inkwell';

  @override
  String get lockWrongPIN => 'Wrong PIN';

  @override
  String get lockSetupTitle => 'Set PIN';

  @override
  String get lockSetupEnterNew => 'Enter new PIN';

  @override
  String get lockSetupConfirm => 'Confirm PIN';

  @override
  String get lockSetupNoMatch => "PINs don't match";

  @override
  String get lockSetupDone => 'PIN saved';

  @override
  String get lockChangePIN => 'Change PIN';

  @override
  String get lockRemovePIN => 'Remove PIN';

  @override
  String get lockRemoveCurrentHint => 'Enter current PIN to remove';

  @override
  String get lockRemoveDone => 'PIN removed';

  @override
  String get lockRemoveWrong => 'Wrong PIN — could not remove';

  @override
  String get settingsLock => 'App Lock';

  @override
  String get settingsLockEnable => 'Enable PIN lock';

  @override
  String get settingsLockActive => 'PIN active';

  @override
  String get settingsLockBiometrics => 'Use biometrics';

  @override
  String get settingsLockBiometricsHint => 'Fingerprint / Face ID';

  @override
  String get deleteEntryTitle => 'Delete entry?';

  @override
  String get deleteEntryHint => 'This cannot be undone.';

  @override
  String get deleteEntryTooltip => 'Delete entry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';
}
