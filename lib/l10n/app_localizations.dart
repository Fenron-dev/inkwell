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

  /// Tooltip for the properties panel toggle button
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get propertiesToggle;

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
  ///
  /// In en, this message translates to:
  /// **'Indexing entries…'**
  String get searchIndexing;

  /// Status when the search index is current
  ///
  /// In en, this message translates to:
  /// **'Index up to date'**
  String get searchIndexReady;

  /// Status after incremental reindex
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry indexed} other{{count} entries indexed}}'**
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
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsEditorColorAuto;

  /// Off-white editor color option
  ///
  /// In en, this message translates to:
  /// **'Off-white'**
  String get settingsEditorColorOffWhite;

  /// Amber editor color option
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get settingsEditorColorAmber;

  /// Mint green editor color option
  ///
  /// In en, this message translates to:
  /// **'Mint'**
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

  /// Hint text for the tag input field
  ///
  /// In en, this message translates to:
  /// **'Add tag…'**
  String get tagAddHint;

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

  /// Shown while the ZIP is being created
  ///
  /// In en, this message translates to:
  /// **'Creating ZIP archive…'**
  String get exportRunning;

  /// Snackbar shown after a successful export
  ///
  /// In en, this message translates to:
  /// **'Saved: {path}'**
  String exportDone(String path);

  /// Shown when user cancels the save dialog
  ///
  /// In en, this message translates to:
  /// **'Export cancelled.'**
  String get exportCancelled;

  /// Shown when the export throws an error
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportError(String error);

  /// Prompt on lock screen
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get lockEnterPIN;

  /// Reason string shown by the OS biometric dialog
  ///
  /// In en, this message translates to:
  /// **'Unlock Inkwell'**
  String get lockBiometricReason;

  /// Hint shown below the fingerprint icon on the biometric lock screen
  ///
  /// In en, this message translates to:
  /// **'Touch the sensor to unlock'**
  String get lockBiometricHint;

  /// Error shown after wrong PIN entry
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get lockWrongPIN;

  /// Title for PIN setup screen
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get lockSetupTitle;

  /// Prompt for entering a new PIN
  ///
  /// In en, this message translates to:
  /// **'Enter new PIN'**
  String get lockSetupEnterNew;

  /// Prompt to re-enter the PIN for confirmation
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get lockSetupConfirm;

  /// Error when the two PINs differ
  ///
  /// In en, this message translates to:
  /// **'PINs don\'t match'**
  String get lockSetupNoMatch;

  /// Snackbar after PIN is saved
  ///
  /// In en, this message translates to:
  /// **'PIN saved'**
  String get lockSetupDone;

  /// Button to change the PIN
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get lockChangePIN;

  /// Button to remove the PIN
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get lockRemovePIN;

  /// Hint on remove-PIN step
  ///
  /// In en, this message translates to:
  /// **'Enter current PIN to remove'**
  String get lockRemoveCurrentHint;

  /// Snackbar after PIN is removed
  ///
  /// In en, this message translates to:
  /// **'PIN removed'**
  String get lockRemoveDone;

  /// Error when wrong PIN entered during remove
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN — could not remove'**
  String get lockRemoveWrong;

  /// Settings section title for App Lock
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get settingsLock;

  /// Tile to enable PIN lock
  ///
  /// In en, this message translates to:
  /// **'Enable PIN lock'**
  String get settingsLockEnable;

  /// Status label when PIN is set
  ///
  /// In en, this message translates to:
  /// **'PIN active'**
  String get settingsLockActive;

  /// Toggle for biometric unlock
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get settingsLockBiometrics;

  /// Subtitle for biometrics toggle
  ///
  /// In en, this message translates to:
  /// **'Fingerprint / Face ID'**
  String get settingsLockBiometricsHint;

  /// Title for the folder picker dialog when changing the vault
  ///
  /// In en, this message translates to:
  /// **'Choose vault folder'**
  String get settingsVaultPickTitle;

  /// Button label to change the vault folder
  ///
  /// In en, this message translates to:
  /// **'Change vault'**
  String get settingsVaultChange;

  /// Error snackbar when vault change fails
  ///
  /// In en, this message translates to:
  /// **'Could not open this folder as a vault.'**
  String get settingsVaultChangeFailed;

  /// Confirmation dialog title for deleting an entry
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get deleteEntryTitle;

  /// Warning text in delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteEntryHint;

  /// Tooltip for the delete entry icon button
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntryTooltip;

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

  /// AppBar title for the template editor screen
  ///
  /// In en, this message translates to:
  /// **'Edit Template'**
  String get templateEditorTitle;

  /// Hint text in the template editor
  ///
  /// In en, this message translates to:
  /// **'Write your daily template here…'**
  String get templateEditorHint;

  /// Snackbar after the template is saved
  ///
  /// In en, this message translates to:
  /// **'Template saved'**
  String get templateSaved;

  /// Header for the 'On This Day' memories banner
  ///
  /// In en, this message translates to:
  /// **'On This Day'**
  String get onThisDayTitle;

  /// Label showing how many years ago a past entry was written
  ///
  /// In en, this message translates to:
  /// **'{years, plural, =1{1 year ago} other{{years} years ago}}'**
  String onThisDayYearsAgo(int years);

  /// Title for the writing prompts panel
  ///
  /// In en, this message translates to:
  /// **'Writing Prompts'**
  String get promptsTitle;

  /// Button to insert a writing prompt into the editor
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get promptsInsert;

  /// Button to show a different writing prompt
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get promptsShuffle;

  /// Writing prompt category: general
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get promptsCategoryGeneral;

  /// Writing prompt category: reflection
  ///
  /// In en, this message translates to:
  /// **'Reflection'**
  String get promptsCategoryReflection;

  /// Writing prompt category: gratitude
  ///
  /// In en, this message translates to:
  /// **'Gratitude'**
  String get promptsCategoryGratitude;

  /// Writing prompt category: creativity
  ///
  /// In en, this message translates to:
  /// **'Creativity'**
  String get promptsCategoryCreativity;

  /// Tooltip for the insert image toolbar button
  ///
  /// In en, this message translates to:
  /// **'Insert image'**
  String get insertImage;

  /// Tooltip for the voice dictation toolbar button
  ///
  /// In en, this message translates to:
  /// **'Dictate'**
  String get sttDictate;

  /// Status text shown while STT is active
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get sttListening;

  /// Error shown when STT is unavailable
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is not available on this device'**
  String get sttNotAvailable;

  /// Title for the quick capture dialog
  ///
  /// In en, this message translates to:
  /// **'Quick Capture'**
  String get quickCaptureTitle;

  /// Placeholder in the quick capture text field
  ///
  /// In en, this message translates to:
  /// **'Add a quick note…'**
  String get quickCaptureHint;

  /// Button in quick capture dialog
  ///
  /// In en, this message translates to:
  /// **'Append to Today'**
  String get quickCaptureSave;

  /// Snackbar after quick capture is saved
  ///
  /// In en, this message translates to:
  /// **'Appended to today\'s entry'**
  String get quickCaptureSaved;

  /// Tooltip for the quick capture FAB
  ///
  /// In en, this message translates to:
  /// **'Quick capture'**
  String get quickCaptureTooltip;

  /// Button in quick capture dialog to open OCR scanner
  ///
  /// In en, this message translates to:
  /// **'Scan URL from camera'**
  String get quickCaptureScanUrl;

  /// AppBar title for the OCR scanner screen
  ///
  /// In en, this message translates to:
  /// **'Scan URL'**
  String get ocrTitle;

  /// Instruction shown on the OCR scanner screen
  ///
  /// In en, this message translates to:
  /// **'Aim camera at the URL in the address bar, then tap Scan'**
  String get ocrScanHint;

  /// Button that triggers OCR capture
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get ocrScanButton;

  /// Label while OCR is processing
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get ocrScanning;

  /// Instruction to pick from detected URLs
  ///
  /// In en, this message translates to:
  /// **'Tap a URL to use it'**
  String get ocrSelectUrl;

  /// Shown when OCR finds no URLs
  ///
  /// In en, this message translates to:
  /// **'No URLs detected — try again'**
  String get ocrNoUrlsYet;

  /// Error when no camera is found
  ///
  /// In en, this message translates to:
  /// **'Camera not available on this device'**
  String get ocrNoCameraError;

  /// Label for the bookmark title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get bookmarkTitleLabel;

  /// Shown while fetching the page title
  ///
  /// In en, this message translates to:
  /// **'Fetching title…'**
  String get bookmarkTitleFetching;

  /// Save button in bookmark mode
  ///
  /// In en, this message translates to:
  /// **'Save Bookmark'**
  String get bookmarkSave;
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
