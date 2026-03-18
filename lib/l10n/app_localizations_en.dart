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
  String get searchHint => 'Search entries...';

  @override
  String get searchNoResults => 'No entries found.';

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
  String get frontmatterLocation => 'Location';

  @override
  String get exportZip => 'Export as ZIP';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';
}
