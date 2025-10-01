import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MacetoApp'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'MacetoApp'**
  String get homeTitle;

  /// No description provided for @addPlant.
  ///
  /// In en, this message translates to:
  /// **'Add plant'**
  String get addPlant;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, species or location'**
  String get searchHint;

  /// No description provided for @emptyList.
  ///
  /// In en, this message translates to:
  /// **'Add your first plant 🌱'**
  String get emptyList;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @orderBy.
  ///
  /// In en, this message translates to:
  /// **'Order by'**
  String get orderBy;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @species.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get species;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @nameAZ.
  ///
  /// In en, this message translates to:
  /// **'Name (A→Z)'**
  String get nameAZ;

  /// No description provided for @nameZA.
  ///
  /// In en, this message translates to:
  /// **'Name (Z→A)'**
  String get nameZA;

  /// No description provided for @dateNewest.
  ///
  /// In en, this message translates to:
  /// **'Planting date (newest first)'**
  String get dateNewest;

  /// No description provided for @dateOldest.
  ///
  /// In en, this message translates to:
  /// **'Planting date (oldest first)'**
  String get dateOldest;

  /// No description provided for @plantNew.
  ///
  /// In en, this message translates to:
  /// **'New plant'**
  String get plantNew;

  /// No description provided for @plantEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit plant'**
  String get plantEdit;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get nameLabel;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @speciesLabel.
  ///
  /// In en, this message translates to:
  /// **'Species/Variety'**
  String get speciesLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @plantedLabel.
  ///
  /// In en, this message translates to:
  /// **'Planted'**
  String get plantedLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @createPlant.
  ///
  /// In en, this message translates to:
  /// **'Create plant'**
  String get createPlant;

  /// No description provided for @deletePlantTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete plant'**
  String get deletePlantTitle;

  /// No description provided for @deletePlantMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete it? This action cannot be undone.'**
  String get deletePlantMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @speciesVariety.
  ///
  /// In en, this message translates to:
  /// **'Species/Variety'**
  String get speciesVariety;

  /// No description provided for @plantedDate.
  ///
  /// In en, this message translates to:
  /// **'Planted'**
  String get plantedDate;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @themeToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get themeToggleTooltip;

  /// No description provided for @plantCreated.
  ///
  /// In en, this message translates to:
  /// **'Plant added'**
  String get plantCreated;

  /// No description provided for @plantDeleted.
  ///
  /// In en, this message translates to:
  /// **'Plant deleted'**
  String get plantDeleted;

  /// No description provided for @plantUpdated.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get plantUpdated;

  /// No description provided for @watering.
  ///
  /// In en, this message translates to:
  /// **'Watering'**
  String get watering;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @intervalDays.
  ///
  /// In en, this message translates to:
  /// **'Interval (days)'**
  String get intervalDays;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @lastWatered.
  ///
  /// In en, this message translates to:
  /// **'Last watered'**
  String get lastWatered;

  /// No description provided for @noWaterData.
  ///
  /// In en, this message translates to:
  /// **'No record yet'**
  String get noWaterData;

  /// No description provided for @nextWatering.
  ///
  /// In en, this message translates to:
  /// **'Next watering'**
  String get nextWatering;

  /// No description provided for @registerWatering.
  ///
  /// In en, this message translates to:
  /// **'Log watering'**
  String get registerWatering;

  /// No description provided for @wateringLogged.
  ///
  /// In en, this message translates to:
  /// **'Watering logged'**
  String get wateringLogged;

  /// No description provided for @globallyPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get globallyPaused;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @plantCreatedWithName.
  ///
  /// In en, this message translates to:
  /// **'Plant \"{name}\" added'**
  String plantCreatedWithName(Object name);

  /// No description provided for @plantDeletedWithName.
  ///
  /// In en, this message translates to:
  /// **'Plant \"{name}\" deleted'**
  String plantDeletedWithName(Object name);

  /// No description provided for @plantUpdatedWithName.
  ///
  /// In en, this message translates to:
  /// **'Changes saved for \"{name}\"'**
  String plantUpdatedWithName(Object name);

  /// No description provided for @needsWaterSoon.
  ///
  /// In en, this message translates to:
  /// **'Water soon'**
  String get needsWaterSoon;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
