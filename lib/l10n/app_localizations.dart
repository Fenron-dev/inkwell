import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Inkwell'**
  String get appTitle;

  /// Onboarding welcome screen title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Inkwell'**
  String get welcomeTitle;

  /// Onboarding welcome screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Your private journal, stored on your device.'**
  String get welcomeSubtitle;

  /// Navigation label for daily notes
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navDaily;

  /// Navigation label for calendar view
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// Navigation label for search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// Navigation label for settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Placeholder text in the editor
  ///
  /// In en, this message translates to:
  /// **'Start writing...'**
  String get editorPlaceholder;

  /// Label for preview mode toggle
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get editorPreview;

  /// Label for edit mode toggle
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editorEdit;

  /// Label for split view mode
  ///
  /// In en, this message translates to:
  /// **'Split View'**
  String get editorSplitView;

  /// Search field hint text
  ///
  /// In en, this message translates to:
  /// **'Search entries...'**
  String get searchHint;

  /// Shown when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No entries found.'**
  String get searchNoResults;

  /// Status while the search index is being built
  String get searchIndexing;

  /// Status when the search index is current
  String get searchIndexReady;

  /// Status after incremental reindex
  String searchIndexUpdated(int count);

  /// Label for today in calendar
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// Entry count display
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No entries} =1{1 entry} other{{count} entries}}'**
  String calendarEntries(int count);

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Label for vault path setting
  ///
  /// In en, this message translates to:
  /// **'Vault Path'**
  String get settingsVaultPath;

  /// Label for theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Label for font setting
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get settingsFont;

  /// Label for editor text color setting
  ///
  /// In en, this message translates to:
  /// **'Editor Text Color'**
  String get settingsEditorColor;

  /// Auto (follows theme) editor color option
  String get settingsEditorColorAuto;

  /// Off-white editor color option
  String get settingsEditorColorOffWhite;

  /// Amber editor color option
  String get settingsEditorColorAmber;

  /// Mint green editor color option
  String get settingsEditorColorMint;

  /// Label for language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Button to create a new vault
  ///
  /// In en, this message translates to:
  /// **'Create New Vault'**
  String get vaultCreate;

  /// Button to open an existing vault folder
  ///
  /// In en, this message translates to:
  /// **'Open Existing Folder'**
  String get vaultOpen;

  /// Prompt to choose vault location
  ///
  /// In en, this message translates to:
  /// **'Choose a location for your journal'**
  String get vaultChooseLocation;

  /// Label for mood property
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get frontmatterMood;

  /// Label for energy property
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get frontmatterEnergy;

  /// Label for sleep property
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get frontmatterSleep;

  /// Label for tags property
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get frontmatterTags;

  /// Label for location property
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get frontmatterLocation;

  /// Button to export vault as ZIP
  ///
  /// In en, this message translates to:
  /// **'Export as ZIP'**
  String get exportZip;

  /// Generic cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Generic OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
