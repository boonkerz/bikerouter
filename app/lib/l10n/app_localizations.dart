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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In de, this message translates to:
  /// **'Wegwiesel'**
  String get appName;

  /// No description provided for @commonCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get commonDelete;

  /// No description provided for @commonOk.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonClose.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get commonClose;

  /// No description provided for @commonShare.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get commonShare;

  /// No description provided for @commonLoading.
  ///
  /// In de, this message translates to:
  /// **'Lädt…'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In de, this message translates to:
  /// **'Fehler'**
  String get commonError;

  /// No description provided for @commonYes.
  ///
  /// In de, this message translates to:
  /// **'Ja'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In de, this message translates to:
  /// **'Nein'**
  String get commonNo;

  /// No description provided for @commonKm.
  ///
  /// In de, this message translates to:
  /// **'km'**
  String get commonKm;

  /// No description provided for @commonM.
  ///
  /// In de, this message translates to:
  /// **'m'**
  String get commonM;

  /// No description provided for @commonMin.
  ///
  /// In de, this message translates to:
  /// **'min'**
  String get commonMin;

  /// No description provided for @commonH.
  ///
  /// In de, this message translates to:
  /// **'h'**
  String get commonH;

  /// No description provided for @commonSearch.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get commonSearch;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen & Info'**
  String get settingsTitle;

  /// No description provided for @settingsSectionLegal.
  ///
  /// In de, this message translates to:
  /// **'Rechtliches'**
  String get settingsSectionLegal;

  /// No description provided for @settingsSectionFeedback.
  ///
  /// In de, this message translates to:
  /// **'Feedback'**
  String get settingsSectionFeedback;

  /// No description provided for @settingsSectionPersonal.
  ///
  /// In de, this message translates to:
  /// **'Persönlich'**
  String get settingsSectionPersonal;

  /// No description provided for @settingsSectionEnergy.
  ///
  /// In de, this message translates to:
  /// **'Energie & Akku'**
  String get settingsSectionEnergy;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In de, this message translates to:
  /// **'Über'**
  String get settingsSectionAbout;

  /// No description provided for @settingsBodyWeight.
  ///
  /// In de, this message translates to:
  /// **'Körpergewicht'**
  String get settingsBodyWeight;

  /// No description provided for @settingsBodyWeightEdit.
  ///
  /// In de, this message translates to:
  /// **'Körpergewicht setzen'**
  String get settingsBodyWeightEdit;

  /// No description provided for @settingsImpressum.
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get settingsImpressum;

  /// No description provided for @settingsPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get settingsPrivacy;

  /// No description provided for @settingsFeedbackForm.
  ///
  /// In de, this message translates to:
  /// **'Feedback & Feature-Wünsche'**
  String get settingsFeedbackForm;

  /// No description provided for @settingsFeedbackFormSub.
  ///
  /// In de, this message translates to:
  /// **'Vorschläge posten und upvoten'**
  String get settingsFeedbackFormSub;

  /// No description provided for @settingsContactMail.
  ///
  /// In de, this message translates to:
  /// **'Kontakt per E-Mail'**
  String get settingsContactMail;

  /// No description provided for @settingsVersion.
  ///
  /// In de, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsLicenses.
  ///
  /// In de, this message translates to:
  /// **'Open-Source-Lizenzen'**
  String get settingsLicenses;

  /// No description provided for @settingsLegalese.
  ///
  /// In de, this message translates to:
  /// **'© 2026 Thomas Peterson\nPrivates, nicht-kommerzielles Projekt'**
  String get settingsLegalese;

  /// No description provided for @settingsAbout.
  ///
  /// In de, this message translates to:
  /// **'Wegwiesel ist ein privates, nicht-kommerzielles Projekt, um bikerouter.de besser auf mobilen Plattformen nutzbar zu machen. Routing basiert auf BRouter, Karten auf OpenStreetMap.'**
  String get settingsAbout;

  /// No description provided for @menuSaveRoute.
  ///
  /// In de, this message translates to:
  /// **'Route speichern'**
  String get menuSaveRoute;

  /// No description provided for @menuSavedRoutes.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Routen'**
  String get menuSavedRoutes;

  /// No description provided for @menuSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get menuSettings;

  /// No description provided for @savedRoutesTitle.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Routen'**
  String get savedRoutesTitle;

  /// No description provided for @savedRoutesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Routen gespeichert.'**
  String get savedRoutesEmpty;

  /// No description provided for @savedRoutesLoad.
  ///
  /// In de, this message translates to:
  /// **'Laden'**
  String get savedRoutesLoad;

  /// No description provided for @savedRoutesDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get savedRoutesDelete;

  /// No description provided for @savedRoutesDeleteConfirm.
  ///
  /// In de, this message translates to:
  /// **'Diese Route wirklich löschen?'**
  String get savedRoutesDeleteConfirm;

  /// No description provided for @savedRouteSavePrompt.
  ///
  /// In de, this message translates to:
  /// **'Name der Route'**
  String get savedRouteSavePrompt;

  /// No description provided for @savedRouteSaveDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Route speichern'**
  String get savedRouteSaveDialogTitle;

  /// No description provided for @savedRouteSaved.
  ///
  /// In de, this message translates to:
  /// **'Route gespeichert'**
  String get savedRouteSaved;

  /// No description provided for @savedRouteDeleted.
  ///
  /// In de, this message translates to:
  /// **'Route gelöscht'**
  String get savedRouteDeleted;

  /// No description provided for @savedRouteDefaultName.
  ///
  /// In de, this message translates to:
  /// **'Route {day}.{month}.'**
  String savedRouteDefaultName(int day, int month);

  /// No description provided for @actionSights.
  ///
  /// In de, this message translates to:
  /// **'POIs'**
  String get actionSights;

  /// No description provided for @actionFilter.
  ///
  /// In de, this message translates to:
  /// **'Filter'**
  String get actionFilter;

  /// No description provided for @actionWeather.
  ///
  /// In de, this message translates to:
  /// **'Wetter'**
  String get actionWeather;

  /// No description provided for @actionAccommodation.
  ///
  /// In de, this message translates to:
  /// **'Unterkunft'**
  String get actionAccommodation;

  /// No description provided for @actionStages.
  ///
  /// In de, this message translates to:
  /// **'Etappen'**
  String get actionStages;

  /// No description provided for @actionShare.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get actionShare;

  /// No description provided for @actionGpx.
  ///
  /// In de, this message translates to:
  /// **'GPX'**
  String get actionGpx;

  /// No description provided for @actionInfo.
  ///
  /// In de, this message translates to:
  /// **'Info'**
  String get actionInfo;

  /// No description provided for @statsDistance.
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get statsDistance;

  /// No description provided for @statsAscent.
  ///
  /// In de, this message translates to:
  /// **'Aufstieg'**
  String get statsAscent;

  /// No description provided for @statsDescent.
  ///
  /// In de, this message translates to:
  /// **'Abstieg'**
  String get statsDescent;

  /// No description provided for @statsTime.
  ///
  /// In de, this message translates to:
  /// **'Zeit'**
  String get statsTime;

  /// No description provided for @statsSpeed.
  ///
  /// In de, this message translates to:
  /// **'Ø km/h'**
  String get statsSpeed;

  /// No description provided for @routeLoading.
  ///
  /// In de, this message translates to:
  /// **'Route wird berechnet…'**
  String get routeLoading;

  /// No description provided for @routeError.
  ///
  /// In de, this message translates to:
  /// **'Route konnte nicht berechnet werden'**
  String get routeError;

  /// No description provided for @routeNoPoints.
  ///
  /// In de, this message translates to:
  /// **'Bitte Start- und Zielpunkt setzen'**
  String get routeNoPoints;

  /// No description provided for @routeClear.
  ///
  /// In de, this message translates to:
  /// **'Route löschen'**
  String get routeClear;

  /// No description provided for @routeClearConfirm.
  ///
  /// In de, this message translates to:
  /// **'Route und alle Wegpunkte entfernen?'**
  String get routeClearConfirm;

  /// No description provided for @gpsPermissionDenied.
  ///
  /// In de, this message translates to:
  /// **'Standortzugriff verweigert'**
  String get gpsPermissionDenied;

  /// No description provided for @gpsUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Standort nicht verfügbar'**
  String get gpsUnavailable;

  /// No description provided for @searchHint.
  ///
  /// In de, this message translates to:
  /// **'Adresse oder Ort suchen…'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In de, this message translates to:
  /// **'Keine Ergebnisse'**
  String get searchNoResults;

  /// No description provided for @searchPrompt.
  ///
  /// In de, this message translates to:
  /// **'Tippe eine Adresse ein'**
  String get searchPrompt;

  /// No description provided for @profileTitle.
  ///
  /// In de, this message translates to:
  /// **'Radtyp'**
  String get profileTitle;

  /// No description provided for @profileCategoryRoad.
  ///
  /// In de, this message translates to:
  /// **'Rennrad'**
  String get profileCategoryRoad;

  /// No description provided for @profileCategoryGravel.
  ///
  /// In de, this message translates to:
  /// **'Gravel'**
  String get profileCategoryGravel;

  /// No description provided for @profileCategoryTrekking.
  ///
  /// In de, this message translates to:
  /// **'Trekking'**
  String get profileCategoryTrekking;

  /// No description provided for @profileCategoryMtb.
  ///
  /// In de, this message translates to:
  /// **'MTB'**
  String get profileCategoryMtb;

  /// No description provided for @profileCategoryCar.
  ///
  /// In de, this message translates to:
  /// **'Auto'**
  String get profileCategoryCar;

  /// No description provided for @profileCategoryEbike.
  ///
  /// In de, this message translates to:
  /// **'E-Bike'**
  String get profileCategoryEbike;

  /// No description provided for @profileCategoryOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstige'**
  String get profileCategoryOther;

  /// No description provided for @profileFastbike.
  ///
  /// In de, this message translates to:
  /// **'Rennrad'**
  String get profileFastbike;

  /// No description provided for @profileFastbikeLowTraffic.
  ///
  /// In de, this message translates to:
  /// **'Rennrad (weniger Verkehr)'**
  String get profileFastbikeLowTraffic;

  /// No description provided for @profileFastbikeVeryLowTraffic.
  ///
  /// In de, this message translates to:
  /// **'Rennrad (sehr wenig Verkehr)'**
  String get profileFastbikeVeryLowTraffic;

  /// No description provided for @profileRandonneur.
  ///
  /// In de, this message translates to:
  /// **'Randonneur'**
  String get profileRandonneur;

  /// No description provided for @profileGravelM11n.
  ///
  /// In de, this message translates to:
  /// **'Gravel „m11n“ (mehr offroad)'**
  String get profileGravelM11n;

  /// No description provided for @profileGravelQuaelnix.
  ///
  /// In de, this message translates to:
  /// **'Gravel „quaelnix“ (wenig Verkehr)'**
  String get profileGravelQuaelnix;

  /// No description provided for @profileGravelCxb.
  ///
  /// In de, this message translates to:
  /// **'Gravel „CXB“ (mehr offroad)'**
  String get profileGravelCxb;

  /// No description provided for @profileTrekking.
  ///
  /// In de, this message translates to:
  /// **'Trekkingrad'**
  String get profileTrekking;

  /// No description provided for @profileSafety.
  ///
  /// In de, this message translates to:
  /// **'Sicherste Route'**
  String get profileSafety;

  /// No description provided for @profileMtbZossebart.
  ///
  /// In de, this message translates to:
  /// **'MTB „Zossebart“'**
  String get profileMtbZossebart;

  /// No description provided for @profileMtbZossebartHard.
  ///
  /// In de, this message translates to:
  /// **'MTB „Zossebart“ (hart)'**
  String get profileMtbZossebartHard;

  /// No description provided for @profileHiking.
  ///
  /// In de, this message translates to:
  /// **'Wandern'**
  String get profileHiking;

  /// No description provided for @profileRunning.
  ///
  /// In de, this message translates to:
  /// **'Laufen'**
  String get profileRunning;

  /// No description provided for @profileShortest.
  ///
  /// In de, this message translates to:
  /// **'Kürzeste Route'**
  String get profileShortest;

  /// No description provided for @profileCar.
  ///
  /// In de, this message translates to:
  /// **'Auto'**
  String get profileCar;

  /// No description provided for @profileCarTrailer.
  ///
  /// In de, this message translates to:
  /// **'Auto mit Anhänger'**
  String get profileCarTrailer;

  /// No description provided for @profileEbike.
  ///
  /// In de, this message translates to:
  /// **'E-Bike'**
  String get profileEbike;

  /// No description provided for @profileEbikeMtb.
  ///
  /// In de, this message translates to:
  /// **'E-MTB'**
  String get profileEbikeMtb;

  /// No description provided for @roundtripTitle.
  ///
  /// In de, this message translates to:
  /// **'Rundtour'**
  String get roundtripTitle;

  /// No description provided for @roundtripDistance.
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get roundtripDistance;

  /// No description provided for @roundtripTime.
  ///
  /// In de, this message translates to:
  /// **'Zeit'**
  String get roundtripTime;

  /// No description provided for @roundtripDirection.
  ///
  /// In de, this message translates to:
  /// **'Richtung'**
  String get roundtripDirection;

  /// No description provided for @roundtripGenerate.
  ///
  /// In de, this message translates to:
  /// **'Rundtour berechnen'**
  String get roundtripGenerate;

  /// No description provided for @roundtripAlternative.
  ///
  /// In de, this message translates to:
  /// **'Andere Variante'**
  String get roundtripAlternative;

  /// No description provided for @roundtripWindOptimized.
  ///
  /// In de, this message translates to:
  /// **'Wind-optimiert'**
  String get roundtripWindOptimized;

  /// No description provided for @roundtripWindCalm.
  ///
  /// In de, this message translates to:
  /// **'Kaum Wind – normale Rundtour erzeugt'**
  String get roundtripWindCalm;

  /// No description provided for @roundtripWindHint.
  ///
  /// In de, this message translates to:
  /// **'Gegenwind raus, Rückenwind heim · Wind aus {dir}, {kmh} km/h'**
  String roundtripWindHint(String dir, int kmh);

  /// No description provided for @roundtripNeedStart.
  ///
  /// In de, this message translates to:
  /// **'Startpunkt auf Karte tippen'**
  String get roundtripNeedStart;

  /// No description provided for @roundtripApproxAt.
  ///
  /// In de, this message translates to:
  /// **'~{km} km bei ~{speed} km/h'**
  String roundtripApproxAt(int km, int speed);

  /// No description provided for @roundtripTimeMinutes.
  ///
  /// In de, this message translates to:
  /// **'Zeit: {min} min'**
  String roundtripTimeMinutes(int min);

  /// No description provided for @roundtripTimeHours.
  ///
  /// In de, this message translates to:
  /// **'Zeit: {h}h'**
  String roundtripTimeHours(int h);

  /// No description provided for @roundtripTimeHoursMinutes.
  ///
  /// In de, this message translates to:
  /// **'Zeit: {h}h {min}min'**
  String roundtripTimeHoursMinutes(int h, int min);

  /// No description provided for @roundtripDirectionLabel.
  ///
  /// In de, this message translates to:
  /// **'Richtung: {deg}°'**
  String roundtripDirectionLabel(int deg);

  /// No description provided for @roundtripDistanceLabel.
  ///
  /// In de, this message translates to:
  /// **'Distanz: {km} km'**
  String roundtripDistanceLabel(int km);

  /// No description provided for @roundtripCompassN.
  ///
  /// In de, this message translates to:
  /// **'N'**
  String get roundtripCompassN;

  /// No description provided for @roundtripCompassE.
  ///
  /// In de, this message translates to:
  /// **'O'**
  String get roundtripCompassE;

  /// No description provided for @roundtripCompassS.
  ///
  /// In de, this message translates to:
  /// **'S'**
  String get roundtripCompassS;

  /// No description provided for @roundtripCompassW.
  ///
  /// In de, this message translates to:
  /// **'W'**
  String get roundtripCompassW;

  /// No description provided for @weatherTitle.
  ///
  /// In de, this message translates to:
  /// **'Wetter entlang der Route'**
  String get weatherTitle;

  /// No description provided for @weatherDay.
  ///
  /// In de, this message translates to:
  /// **'Tag'**
  String get weatherDay;

  /// No description provided for @weatherLoading.
  ///
  /// In de, this message translates to:
  /// **'Wetter wird geladen…'**
  String get weatherLoading;

  /// No description provided for @weatherError.
  ///
  /// In de, this message translates to:
  /// **'Wetter-Abruf fehlgeschlagen'**
  String get weatherError;

  /// No description provided for @weatherEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Wetterdaten'**
  String get weatherEmpty;

  /// No description provided for @weatherToday.
  ///
  /// In de, this message translates to:
  /// **'Heute {hm}'**
  String weatherToday(String hm);

  /// No description provided for @weatherTomorrow.
  ///
  /// In de, this message translates to:
  /// **'Morgen {hm}'**
  String weatherTomorrow(String hm);

  /// No description provided for @weatherTemperature.
  ///
  /// In de, this message translates to:
  /// **'Temperatur'**
  String get weatherTemperature;

  /// No description provided for @weatherWind.
  ///
  /// In de, this message translates to:
  /// **'Wind'**
  String get weatherWind;

  /// No description provided for @weatherPrecipitation.
  ///
  /// In de, this message translates to:
  /// **'Niederschlag'**
  String get weatherPrecipitation;

  /// No description provided for @stagesTitle.
  ///
  /// In de, this message translates to:
  /// **'Etappenplaner'**
  String get stagesTitle;

  /// No description provided for @stagesPerDay.
  ///
  /// In de, this message translates to:
  /// **'km/Tag'**
  String get stagesPerDay;

  /// No description provided for @stagesTotalKm.
  ///
  /// In de, this message translates to:
  /// **'{km} km gesamt'**
  String stagesTotalKm(String km);

  /// No description provided for @stagesTargetLabel.
  ///
  /// In de, this message translates to:
  /// **'Tagesziel'**
  String get stagesTargetLabel;

  /// No description provided for @stagesByKm.
  ///
  /// In de, this message translates to:
  /// **'km/Tag'**
  String get stagesByKm;

  /// No description provided for @stagesByDays.
  ///
  /// In de, this message translates to:
  /// **'Tage'**
  String get stagesByDays;

  /// No description provided for @stagesDaysValue.
  ///
  /// In de, this message translates to:
  /// **'{days} Tage'**
  String stagesDaysValue(int days);

  /// No description provided for @stagesPlanSummary.
  ///
  /// In de, this message translates to:
  /// **'{count} Etappen · Ø {km} km'**
  String stagesPlanSummary(int count, int km);

  /// No description provided for @stagesDaylightOver.
  ///
  /// In de, this message translates to:
  /// **'länger als Tageslicht'**
  String get stagesDaylightOver;

  /// No description provided for @stagesDaylightTight.
  ///
  /// In de, this message translates to:
  /// **'knapp vor Sonnenuntergang'**
  String get stagesDaylightTight;

  /// No description provided for @stagesBatteryOver.
  ///
  /// In de, this message translates to:
  /// **'Akku reicht nicht'**
  String get stagesBatteryOver;

  /// No description provided for @stagesDays.
  ///
  /// In de, this message translates to:
  /// **'{count} Tage'**
  String stagesDays(int count);

  /// No description provided for @stagesCreating.
  ///
  /// In de, this message translates to:
  /// **'Etappen werden berechnet…'**
  String get stagesCreating;

  /// No description provided for @stagesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Etappen'**
  String get stagesEmpty;

  /// No description provided for @stagesError.
  ///
  /// In de, this message translates to:
  /// **'Etappen konnten nicht berechnet werden'**
  String get stagesError;

  /// No description provided for @stagesShowOnMap.
  ///
  /// In de, this message translates to:
  /// **'Etappen auf Karte zeigen'**
  String get stagesShowOnMap;

  /// No description provided for @stagesDefault.
  ///
  /// In de, this message translates to:
  /// **'Etappe {n}'**
  String stagesDefault(int n);

  /// No description provided for @stagesRowSummary.
  ///
  /// In de, this message translates to:
  /// **'{km} km · {ascent} hm · bis {end} km'**
  String stagesRowSummary(String km, int ascent, String end);

  /// No description provided for @accommodationTitle.
  ///
  /// In de, this message translates to:
  /// **'Unterkünfte'**
  String get accommodationTitle;

  /// No description provided for @accommodationLoading.
  ///
  /// In de, this message translates to:
  /// **'Unterkünfte werden gesucht…'**
  String get accommodationLoading;

  /// No description provided for @accommodationNoResults.
  ///
  /// In de, this message translates to:
  /// **'Keine Unterkünfte gefunden'**
  String get accommodationNoResults;

  /// No description provided for @accommodationOpenInMaps.
  ///
  /// In de, this message translates to:
  /// **'In Karten öffnen'**
  String get accommodationOpenInMaps;

  /// No description provided for @accommodationRadius.
  ///
  /// In de, this message translates to:
  /// **'Umkreis'**
  String get accommodationRadius;

  /// No description provided for @accommodationHotel.
  ///
  /// In de, this message translates to:
  /// **'Hotel'**
  String get accommodationHotel;

  /// No description provided for @accommodationMotel.
  ///
  /// In de, this message translates to:
  /// **'Motel'**
  String get accommodationMotel;

  /// No description provided for @accommodationHostel.
  ///
  /// In de, this message translates to:
  /// **'Hostel'**
  String get accommodationHostel;

  /// No description provided for @accommodationGuesthouse.
  ///
  /// In de, this message translates to:
  /// **'Pension'**
  String get accommodationGuesthouse;

  /// No description provided for @accommodationBnb.
  ///
  /// In de, this message translates to:
  /// **'B&B'**
  String get accommodationBnb;

  /// No description provided for @accommodationApartment.
  ///
  /// In de, this message translates to:
  /// **'Ferienwohnung'**
  String get accommodationApartment;

  /// No description provided for @accommodationChalet.
  ///
  /// In de, this message translates to:
  /// **'Chalet'**
  String get accommodationChalet;

  /// No description provided for @accommodationAlpineHut.
  ///
  /// In de, this message translates to:
  /// **'Berghütte'**
  String get accommodationAlpineHut;

  /// No description provided for @accommodationWildernessHut.
  ///
  /// In de, this message translates to:
  /// **'Schutzhütte'**
  String get accommodationWildernessHut;

  /// No description provided for @accommodationCampsite.
  ///
  /// In de, this message translates to:
  /// **'Campingplatz'**
  String get accommodationCampsite;

  /// No description provided for @accommodationCaravanSite.
  ///
  /// In de, this message translates to:
  /// **'Wohnmobilplatz'**
  String get accommodationCaravanSite;

  /// No description provided for @sightsTitle.
  ///
  /// In de, this message translates to:
  /// **'Sehenswürdigkeiten'**
  String get sightsTitle;

  /// No description provided for @sightsLoading.
  ///
  /// In de, this message translates to:
  /// **'Sehenswürdigkeiten werden geladen…'**
  String get sightsLoading;

  /// No description provided for @sightsNoResults.
  ///
  /// In de, this message translates to:
  /// **'Nichts gefunden'**
  String get sightsNoResults;

  /// No description provided for @sightsCategoryAttraction.
  ///
  /// In de, this message translates to:
  /// **'Sehenswürdigkeit'**
  String get sightsCategoryAttraction;

  /// No description provided for @sightsCategoryViewpoint.
  ///
  /// In de, this message translates to:
  /// **'Aussichtspunkt'**
  String get sightsCategoryViewpoint;

  /// No description provided for @sightsCategoryMonument.
  ///
  /// In de, this message translates to:
  /// **'Denkmal'**
  String get sightsCategoryMonument;

  /// No description provided for @sightsCategoryMemorial.
  ///
  /// In de, this message translates to:
  /// **'Mahnmal'**
  String get sightsCategoryMemorial;

  /// No description provided for @sightsCategoryCastle.
  ///
  /// In de, this message translates to:
  /// **'Burg/Schloss'**
  String get sightsCategoryCastle;

  /// No description provided for @sightsCategoryRuins.
  ///
  /// In de, this message translates to:
  /// **'Ruine'**
  String get sightsCategoryRuins;

  /// No description provided for @sightsCategoryChurch.
  ///
  /// In de, this message translates to:
  /// **'Kirche'**
  String get sightsCategoryChurch;

  /// No description provided for @sightsCategoryMuseum.
  ///
  /// In de, this message translates to:
  /// **'Museum'**
  String get sightsCategoryMuseum;

  /// No description provided for @sightsCategoryArtwork.
  ///
  /// In de, this message translates to:
  /// **'Kunstwerk'**
  String get sightsCategoryArtwork;

  /// No description provided for @sightsCategoryWaterfall.
  ///
  /// In de, this message translates to:
  /// **'Wasserfall'**
  String get sightsCategoryWaterfall;

  /// No description provided for @sightsCategoryPeak.
  ///
  /// In de, this message translates to:
  /// **'Gipfel'**
  String get sightsCategoryPeak;

  /// No description provided for @sightsCategoryCave.
  ///
  /// In de, this message translates to:
  /// **'Höhle'**
  String get sightsCategoryCave;

  /// No description provided for @sightsCategoryWater.
  ///
  /// In de, this message translates to:
  /// **'Gewässer'**
  String get sightsCategoryWater;

  /// No description provided for @sightsCategorySpring.
  ///
  /// In de, this message translates to:
  /// **'Quelle'**
  String get sightsCategorySpring;

  /// No description provided for @sightsCategoryInformation.
  ///
  /// In de, this message translates to:
  /// **'Info-Tafel'**
  String get sightsCategoryInformation;

  /// No description provided for @sightsCategoryDrinkingWater.
  ///
  /// In de, this message translates to:
  /// **'Trinkwasser'**
  String get sightsCategoryDrinkingWater;

  /// No description provided for @sightsCategoryBench.
  ///
  /// In de, this message translates to:
  /// **'Rastplatz'**
  String get sightsCategoryBench;

  /// No description provided for @sightsCategoryShelter.
  ///
  /// In de, this message translates to:
  /// **'Unterstand'**
  String get sightsCategoryShelter;

  /// No description provided for @sightsCategoryCampsite.
  ///
  /// In de, this message translates to:
  /// **'Zeltplatz'**
  String get sightsCategoryCampsite;

  /// No description provided for @sightsCategoryPicnic.
  ///
  /// In de, this message translates to:
  /// **'Picknickplatz'**
  String get sightsCategoryPicnic;

  /// No description provided for @sightsCategoryBakery.
  ///
  /// In de, this message translates to:
  /// **'Bäckerei'**
  String get sightsCategoryBakery;

  /// No description provided for @sightsCategoryCafe.
  ///
  /// In de, this message translates to:
  /// **'Café'**
  String get sightsCategoryCafe;

  /// No description provided for @sightsCategoryRestaurant.
  ///
  /// In de, this message translates to:
  /// **'Restaurant'**
  String get sightsCategoryRestaurant;

  /// No description provided for @sightsCategorySupermarket.
  ///
  /// In de, this message translates to:
  /// **'Supermarkt'**
  String get sightsCategorySupermarket;

  /// No description provided for @sightsCategoryBicycleRepair.
  ///
  /// In de, this message translates to:
  /// **'Radwerkstatt'**
  String get sightsCategoryBicycleRepair;

  /// No description provided for @sightsCategoryBicycleShop.
  ///
  /// In de, this message translates to:
  /// **'Fahrradladen'**
  String get sightsCategoryBicycleShop;

  /// No description provided for @surfaceTitle.
  ///
  /// In de, this message translates to:
  /// **'Beschaffenheit'**
  String get surfaceTitle;

  /// No description provided for @surfaceCategoryAsphalt.
  ///
  /// In de, this message translates to:
  /// **'Asphalt'**
  String get surfaceCategoryAsphalt;

  /// No description provided for @surfaceCategoryPavingStones.
  ///
  /// In de, this message translates to:
  /// **'Pflaster'**
  String get surfaceCategoryPavingStones;

  /// No description provided for @surfaceCategoryGravel.
  ///
  /// In de, this message translates to:
  /// **'Schotter'**
  String get surfaceCategoryGravel;

  /// No description provided for @surfaceCategoryUnpaved.
  ///
  /// In de, this message translates to:
  /// **'Naturweg'**
  String get surfaceCategoryUnpaved;

  /// No description provided for @surfaceCategoryOffroad.
  ///
  /// In de, this message translates to:
  /// **'Waldweg'**
  String get surfaceCategoryOffroad;

  /// No description provided for @surfaceCategoryUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get surfaceCategoryUnknown;

  /// No description provided for @surfaceAsphalt.
  ///
  /// In de, this message translates to:
  /// **'Asphalt'**
  String get surfaceAsphalt;

  /// No description provided for @surfacePaved.
  ///
  /// In de, this message translates to:
  /// **'Befestigt'**
  String get surfacePaved;

  /// No description provided for @surfaceConcrete.
  ///
  /// In de, this message translates to:
  /// **'Beton'**
  String get surfaceConcrete;

  /// No description provided for @surfacePavingStones.
  ///
  /// In de, this message translates to:
  /// **'Pflastersteine'**
  String get surfacePavingStones;

  /// No description provided for @surfaceCobblestone.
  ///
  /// In de, this message translates to:
  /// **'Kopfsteinpflaster'**
  String get surfaceCobblestone;

  /// No description provided for @surfaceCompacted.
  ///
  /// In de, this message translates to:
  /// **'Wassergebunden'**
  String get surfaceCompacted;

  /// No description provided for @surfaceGravel.
  ///
  /// In de, this message translates to:
  /// **'Schotter'**
  String get surfaceGravel;

  /// No description provided for @surfaceFineGravel.
  ///
  /// In de, this message translates to:
  /// **'Feinschotter'**
  String get surfaceFineGravel;

  /// No description provided for @surfaceUnpaved.
  ///
  /// In de, this message translates to:
  /// **'Unbefestigt'**
  String get surfaceUnpaved;

  /// No description provided for @surfaceGround.
  ///
  /// In de, this message translates to:
  /// **'Erdweg'**
  String get surfaceGround;

  /// No description provided for @surfaceDirt.
  ///
  /// In de, this message translates to:
  /// **'Feldweg'**
  String get surfaceDirt;

  /// No description provided for @surfaceGrass.
  ///
  /// In de, this message translates to:
  /// **'Gras'**
  String get surfaceGrass;

  /// No description provided for @surfaceSand.
  ///
  /// In de, this message translates to:
  /// **'Sand'**
  String get surfaceSand;

  /// No description provided for @surfaceWood.
  ///
  /// In de, this message translates to:
  /// **'Holz'**
  String get surfaceWood;

  /// No description provided for @surfaceMetal.
  ///
  /// In de, this message translates to:
  /// **'Metall'**
  String get surfaceMetal;

  /// No description provided for @surfaceUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get surfaceUnknown;

  /// No description provided for @highwayCycleway.
  ///
  /// In de, this message translates to:
  /// **'Radweg'**
  String get highwayCycleway;

  /// No description provided for @highwayPath.
  ///
  /// In de, this message translates to:
  /// **'Pfad'**
  String get highwayPath;

  /// No description provided for @highwayTrack.
  ///
  /// In de, this message translates to:
  /// **'Wirtschaftsweg'**
  String get highwayTrack;

  /// No description provided for @highwayFootway.
  ///
  /// In de, this message translates to:
  /// **'Fußweg'**
  String get highwayFootway;

  /// No description provided for @highwayPedestrian.
  ///
  /// In de, this message translates to:
  /// **'Fußgängerzone'**
  String get highwayPedestrian;

  /// No description provided for @highwayLivingStreet.
  ///
  /// In de, this message translates to:
  /// **'Verkehrsberuhigt'**
  String get highwayLivingStreet;

  /// No description provided for @highwayResidential.
  ///
  /// In de, this message translates to:
  /// **'Wohnstraße'**
  String get highwayResidential;

  /// No description provided for @highwayService.
  ///
  /// In de, this message translates to:
  /// **'Erschließung'**
  String get highwayService;

  /// No description provided for @highwayUnclassified.
  ///
  /// In de, this message translates to:
  /// **'Nebenstraße'**
  String get highwayUnclassified;

  /// No description provided for @highwayTertiary.
  ///
  /// In de, this message translates to:
  /// **'Nebenstraße'**
  String get highwayTertiary;

  /// No description provided for @highwaySecondary.
  ///
  /// In de, this message translates to:
  /// **'Straße (mittel)'**
  String get highwaySecondary;

  /// No description provided for @highwayPrimary.
  ///
  /// In de, this message translates to:
  /// **'Haupt-/Bundesstraße'**
  String get highwayPrimary;

  /// No description provided for @highwayTrunk.
  ///
  /// In de, this message translates to:
  /// **'Kraftfahrstraße'**
  String get highwayTrunk;

  /// No description provided for @highwayMotorway.
  ///
  /// In de, this message translates to:
  /// **'Autobahn/Schnellstraße'**
  String get highwayMotorway;

  /// No description provided for @highwaySteps.
  ///
  /// In de, this message translates to:
  /// **'Treppen'**
  String get highwaySteps;

  /// No description provided for @highwayUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get highwayUnknown;

  /// No description provided for @shareDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Route teilen'**
  String get shareDialogTitle;

  /// No description provided for @shareLinkCopied.
  ///
  /// In de, this message translates to:
  /// **'Link kopiert'**
  String get shareLinkCopied;

  /// No description provided for @shareLinkCreating.
  ///
  /// In de, this message translates to:
  /// **'Link wird erstellt…'**
  String get shareLinkCreating;

  /// No description provided for @shareLinkError.
  ///
  /// In de, this message translates to:
  /// **'Link konnte nicht erstellt werden'**
  String get shareLinkError;

  /// No description provided for @gpxExportTitle.
  ///
  /// In de, this message translates to:
  /// **'GPX exportieren'**
  String get gpxExportTitle;

  /// No description provided for @gpxExportDone.
  ///
  /// In de, this message translates to:
  /// **'GPX gespeichert'**
  String get gpxExportDone;

  /// No description provided for @gpxExportError.
  ///
  /// In de, this message translates to:
  /// **'GPX-Export fehlgeschlagen'**
  String get gpxExportError;

  /// No description provided for @infoDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Route-Info'**
  String get infoDialogTitle;

  /// No description provided for @infoPoiCount.
  ///
  /// In de, this message translates to:
  /// **'{count} POIs'**
  String infoPoiCount(int count);

  /// No description provided for @elevationToggleShow.
  ///
  /// In de, this message translates to:
  /// **'Profil anzeigen'**
  String get elevationToggleShow;

  /// No description provided for @elevationToggleHide.
  ///
  /// In de, this message translates to:
  /// **'Profil ausblenden'**
  String get elevationToggleHide;

  /// No description provided for @addWaypoint.
  ///
  /// In de, this message translates to:
  /// **'Wegpunkt hinzufügen'**
  String get addWaypoint;

  /// No description provided for @removeWaypoint.
  ///
  /// In de, this message translates to:
  /// **'Wegpunkt entfernen'**
  String get removeWaypoint;

  /// No description provided for @setAsStart.
  ///
  /// In de, this message translates to:
  /// **'Als Start setzen'**
  String get setAsStart;

  /// No description provided for @setAsEnd.
  ///
  /// In de, this message translates to:
  /// **'Als Ziel setzen'**
  String get setAsEnd;

  /// No description provided for @modeAtoB.
  ///
  /// In de, this message translates to:
  /// **'A → B'**
  String get modeAtoB;

  /// No description provided for @modeRoundtrip.
  ///
  /// In de, this message translates to:
  /// **'Runde'**
  String get modeRoundtrip;

  /// No description provided for @tapRouteForInfo.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf eine Route, um Info zu sehen'**
  String get tapRouteForInfo;

  /// No description provided for @routeLinkCopied.
  ///
  /// In de, this message translates to:
  /// **'Link in die Zwischenablage kopiert'**
  String get routeLinkCopied;

  /// No description provided for @noRouteHere.
  ///
  /// In de, this message translates to:
  /// **'Keine Route an dieser Stelle gefunden'**
  String get noRouteHere;

  /// No description provided for @shareSheetTitle.
  ///
  /// In de, this message translates to:
  /// **'Route teilen'**
  String get shareSheetTitle;

  /// No description provided for @shareCopyLink.
  ///
  /// In de, this message translates to:
  /// **'Link kopieren'**
  String get shareCopyLink;

  /// No description provided for @shareCopyLinkSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Empfänger öffnet sie im Browser'**
  String get shareCopyLinkSubtitle;

  /// No description provided for @shareToGarmin.
  ///
  /// In de, this message translates to:
  /// **'An Garmin senden'**
  String get shareToGarmin;

  /// No description provided for @shareToGarminSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Code in der Garmin-Edge-App eingeben'**
  String get shareToGarminSubtitle;

  /// No description provided for @garminCodeTitle.
  ///
  /// In de, this message translates to:
  /// **'Code für deinen Garmin'**
  String get garminCodeTitle;

  /// No description provided for @garminCodeHint.
  ///
  /// In de, this message translates to:
  /// **'In der Wegwiesel-Sync-App auf der Edge eingeben. Gültig 7 Tage.'**
  String get garminCodeHint;

  /// No description provided for @garminCodeExpiresAt.
  ///
  /// In de, this message translates to:
  /// **'Gültig bis {date}'**
  String garminCodeExpiresAt(String date);

  /// No description provided for @garminCodeCopied.
  ///
  /// In de, this message translates to:
  /// **'Code kopiert'**
  String get garminCodeCopied;

  /// No description provided for @garminUploadFailed.
  ///
  /// In de, this message translates to:
  /// **'Senden fehlgeschlagen: {error}'**
  String garminUploadFailed(String error);

  /// No description provided for @garminUploading.
  ///
  /// In de, this message translates to:
  /// **'Wird hochgeladen…'**
  String get garminUploading;

  /// No description provided for @shareDirectToEdge.
  ///
  /// In de, this message translates to:
  /// **'Direkt an Edge schicken'**
  String get shareDirectToEdge;

  /// No description provided for @shareDirectToEdgeSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Per Bluetooth über Garmin Connect Mobile'**
  String get shareDirectToEdgeSubtitle;

  /// No description provided for @garminPickDevicesTitle.
  ///
  /// In de, this message translates to:
  /// **'Edge auswählen'**
  String get garminPickDevicesTitle;

  /// No description provided for @garminPickDevicesPrompt.
  ///
  /// In de, this message translates to:
  /// **'Bisher ist keine Edge mit Wegwiesel verknüpft. Du wirst gleich zu Garmin Connect Mobile geleitet, dort die Edge bestätigen und kommst dann zurück.'**
  String get garminPickDevicesPrompt;

  /// No description provided for @garminPickDevicesAction.
  ///
  /// In de, this message translates to:
  /// **'Garmin Connect Mobile öffnen'**
  String get garminPickDevicesAction;

  /// No description provided for @garminSendingTo.
  ///
  /// In de, this message translates to:
  /// **'Sende an {device}…'**
  String garminSendingTo(String device);

  /// No description provided for @garminSendSuccess.
  ///
  /// In de, this message translates to:
  /// **'Strecke an {device} geschickt'**
  String garminSendSuccess(String device);

  /// No description provided for @garminSendFailed.
  ///
  /// In de, this message translates to:
  /// **'Senden fehlgeschlagen: {error}'**
  String garminSendFailed(String error);

  /// No description provided for @garminNoDevicesAfterPick.
  ///
  /// In de, this message translates to:
  /// **'Keine Edge ausgewählt'**
  String get garminNoDevicesAfterPick;

  /// No description provided for @garminRepickDevices.
  ///
  /// In de, this message translates to:
  /// **'Edge neu auswählen'**
  String get garminRepickDevices;

  /// No description provided for @garminRepickDevicesSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Garmin Connect Mobile öffnen und Berechtigung erneuern'**
  String get garminRepickDevicesSubtitle;

  /// No description provided for @garminDeviceOffline.
  ///
  /// In de, this message translates to:
  /// **'{device} ist nicht erreichbar'**
  String garminDeviceOffline(String device);

  /// No description provided for @menuStartNavigation.
  ///
  /// In de, this message translates to:
  /// **'Navigation starten'**
  String get menuStartNavigation;

  /// No description provided for @menuReturnOneWay.
  ///
  /// In de, this message translates to:
  /// **'Nur Hinweg'**
  String get menuReturnOneWay;

  /// No description provided for @menuReturnSameWay.
  ///
  /// In de, this message translates to:
  /// **'Hin & zurück (gleicher Weg)'**
  String get menuReturnSameWay;

  /// No description provided for @menuReturnDifferentWay.
  ///
  /// In de, this message translates to:
  /// **'Hin & zurück (anderer Weg)'**
  String get menuReturnDifferentWay;

  /// No description provided for @navigateContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiterfahren'**
  String get navigateContinue;

  /// No description provided for @navigateTurnLeft.
  ///
  /// In de, this message translates to:
  /// **'links abbiegen'**
  String get navigateTurnLeft;

  /// No description provided for @navigateTurnRight.
  ///
  /// In de, this message translates to:
  /// **'rechts abbiegen'**
  String get navigateTurnRight;

  /// No description provided for @navigateKeepLeft.
  ///
  /// In de, this message translates to:
  /// **'links halten'**
  String get navigateKeepLeft;

  /// No description provided for @navigateKeepRight.
  ///
  /// In de, this message translates to:
  /// **'rechts halten'**
  String get navigateKeepRight;

  /// No description provided for @navigateStraight.
  ///
  /// In de, this message translates to:
  /// **'geradeaus'**
  String get navigateStraight;

  /// No description provided for @navigateUTurn.
  ///
  /// In de, this message translates to:
  /// **'wenden'**
  String get navigateUTurn;

  /// No description provided for @navigateExit.
  ///
  /// In de, this message translates to:
  /// **'Ausfahrt nehmen'**
  String get navigateExit;

  /// No description provided for @navigateRoundabout.
  ///
  /// In de, this message translates to:
  /// **'{n}. Ausfahrt im Kreisverkehr'**
  String navigateRoundabout(int n);

  /// No description provided for @navigateRemaining.
  ///
  /// In de, this message translates to:
  /// **'verbleibend'**
  String get navigateRemaining;

  /// No description provided for @navigateEta.
  ///
  /// In de, this message translates to:
  /// **'Ankunft'**
  String get navigateEta;

  /// No description provided for @navigateRerouting.
  ///
  /// In de, this message translates to:
  /// **'Neu berechnen…'**
  String get navigateRerouting;

  /// No description provided for @navigateArrived.
  ///
  /// In de, this message translates to:
  /// **'Angekommen'**
  String get navigateArrived;

  /// No description provided for @navigateStop.
  ///
  /// In de, this message translates to:
  /// **'Stopp'**
  String get navigateStop;

  /// No description provided for @navigateNorthUp.
  ///
  /// In de, this message translates to:
  /// **'Nach Norden'**
  String get navigateNorthUp;

  /// No description provided for @navigateHeadingUp.
  ///
  /// In de, this message translates to:
  /// **'In Fahrtrichtung'**
  String get navigateHeadingUp;

  /// No description provided for @navigateVoiceOn.
  ///
  /// In de, this message translates to:
  /// **'Sprachansage an'**
  String get navigateVoiceOn;

  /// No description provided for @navigateVoiceOff.
  ///
  /// In de, this message translates to:
  /// **'Sprachansage aus'**
  String get navigateVoiceOff;

  /// No description provided for @voiceInMeters.
  ///
  /// In de, this message translates to:
  /// **'In {n} Metern'**
  String voiceInMeters(int n);

  /// No description provided for @voiceNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt'**
  String get voiceNow;

  /// No description provided for @voiceRerouting.
  ///
  /// In de, this message translates to:
  /// **'Route wird neu berechnet'**
  String get voiceRerouting;

  /// No description provided for @voiceArrived.
  ///
  /// In de, this message translates to:
  /// **'Sie haben Ihr Ziel erreicht'**
  String get voiceArrived;

  /// No description provided for @altRoutePrimary.
  ///
  /// In de, this message translates to:
  /// **'Hauptroute'**
  String get altRoutePrimary;

  /// No description provided for @altRouteVariant.
  ///
  /// In de, this message translates to:
  /// **'Variante {n}'**
  String altRouteVariant(int n);

  /// No description provided for @altRouteCalculating.
  ///
  /// In de, this message translates to:
  /// **'wird berechnet…'**
  String get altRouteCalculating;

  /// No description provided for @altRouteShortest.
  ///
  /// In de, this message translates to:
  /// **'Kürzeste Route'**
  String get altRouteShortest;

  /// No description provided for @altRouteAvoidMotorways.
  ///
  /// In de, this message translates to:
  /// **'Autobahn vermeiden'**
  String get altRouteAvoidMotorways;

  /// No description provided for @mapStyleTitle.
  ///
  /// In de, this message translates to:
  /// **'Kartenstil'**
  String get mapStyleTitle;

  /// No description provided for @mapOverlayRoutes.
  ///
  /// In de, this message translates to:
  /// **'Overlay-Routen'**
  String get mapOverlayRoutes;

  /// No description provided for @mapRouteVizTitle.
  ///
  /// In de, this message translates to:
  /// **'Routen-Färbung'**
  String get mapRouteVizTitle;

  /// No description provided for @mapVizGradient.
  ///
  /// In de, this message translates to:
  /// **'Steigung'**
  String get mapVizGradient;

  /// No description provided for @gpsPermanentlyDenied.
  ///
  /// In de, this message translates to:
  /// **'Standort-Berechtigung dauerhaft verweigert. Bitte in den Einstellungen aktivieren.'**
  String get gpsPermanentlyDenied;

  /// No description provided for @gpsFetchFailed.
  ///
  /// In de, this message translates to:
  /// **'Standort konnte nicht ermittelt werden: {error}'**
  String gpsFetchFailed(String error);

  /// No description provided for @routingFailed.
  ///
  /// In de, this message translates to:
  /// **'Routing fehlgeschlagen: {error}'**
  String routingFailed(String error);

  /// No description provided for @roundtripFailed.
  ///
  /// In de, this message translates to:
  /// **'Rundtour fehlgeschlagen: {error}'**
  String roundtripFailed(String error);

  /// No description provided for @roundtripOffTarget.
  ///
  /// In de, this message translates to:
  /// **'Keine passende Rundtour gefunden (BRouter hat {actualKm} km geliefert). Bitte andere Richtung oder kürzere Distanz probieren.'**
  String roundtripOffTarget(String actualKm);

  /// No description provided for @exportFailed.
  ///
  /// In de, this message translates to:
  /// **'Export fehlgeschlagen: {error}'**
  String exportFailed(String error);

  /// No description provided for @overpassError.
  ///
  /// In de, this message translates to:
  /// **'Overpass-Fehler: {error}'**
  String overpassError(String error);

  /// No description provided for @poiAddTitle.
  ///
  /// In de, this message translates to:
  /// **'POI hinzufügen'**
  String get poiAddTitle;

  /// No description provided for @poiEditTitle.
  ///
  /// In de, this message translates to:
  /// **'POI bearbeiten'**
  String get poiEditTitle;

  /// No description provided for @poiCategoryLabel.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get poiCategoryLabel;

  /// No description provided for @poiNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get poiNameLabel;

  /// No description provided for @poiNoteLabel.
  ///
  /// In de, this message translates to:
  /// **'Notiz (optional)'**
  String get poiNoteLabel;

  /// No description provided for @poiTypesTitle.
  ///
  /// In de, this message translates to:
  /// **'POI-Typen'**
  String get poiTypesTitle;

  /// No description provided for @filterSelectAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get filterSelectAll;

  /// No description provided for @filterSelectNone.
  ///
  /// In de, this message translates to:
  /// **'Keine'**
  String get filterSelectNone;

  /// No description provided for @sightWikipedia.
  ///
  /// In de, this message translates to:
  /// **'Wikipedia'**
  String get sightWikipedia;

  /// No description provided for @sightWebsite.
  ///
  /// In de, this message translates to:
  /// **'Website'**
  String get sightWebsite;

  /// No description provided for @sightOsmRelation.
  ///
  /// In de, this message translates to:
  /// **'OSM-Relation'**
  String get sightOsmRelation;

  /// No description provided for @sightAsWaypoint.
  ///
  /// In de, this message translates to:
  /// **'Als Waypoint'**
  String get sightAsWaypoint;

  /// No description provided for @sightFeeYes.
  ///
  /// In de, this message translates to:
  /// **'Eintritt'**
  String get sightFeeYes;

  /// No description provided for @sightFeeNo.
  ///
  /// In de, this message translates to:
  /// **'Kostenlos'**
  String get sightFeeNo;

  /// No description provided for @sightAccessibleYes.
  ///
  /// In de, this message translates to:
  /// **'Barrierefrei'**
  String get sightAccessibleYes;

  /// No description provided for @sightAccessibleLimited.
  ///
  /// In de, this message translates to:
  /// **'Teilweise barrierefrei'**
  String get sightAccessibleLimited;

  /// No description provided for @sightAccessibleNo.
  ///
  /// In de, this message translates to:
  /// **'Nicht barrierefrei'**
  String get sightAccessibleNo;

  /// No description provided for @sightBuilt.
  ///
  /// In de, this message translates to:
  /// **'Erbaut {year}'**
  String sightBuilt(String year);

  /// No description provided for @sightHeritage.
  ///
  /// In de, this message translates to:
  /// **'Denkmalschutz'**
  String get sightHeritage;

  /// No description provided for @sightArtist.
  ///
  /// In de, this message translates to:
  /// **'Künstler: {name}'**
  String sightArtist(String name);

  /// No description provided for @sightsGroupTourism.
  ///
  /// In de, this message translates to:
  /// **'Tourismus'**
  String get sightsGroupTourism;

  /// No description provided for @sightsGroupHistoric.
  ///
  /// In de, this message translates to:
  /// **'Historisch'**
  String get sightsGroupHistoric;

  /// No description provided for @sightsGroupNatural.
  ///
  /// In de, this message translates to:
  /// **'Natur'**
  String get sightsGroupNatural;

  /// No description provided for @sightsGroupShop.
  ///
  /// In de, this message translates to:
  /// **'Einkauf'**
  String get sightsGroupShop;

  /// No description provided for @sightsGroupAmenity.
  ///
  /// In de, this message translates to:
  /// **'Versorgung'**
  String get sightsGroupAmenity;

  /// No description provided for @sightsGroupRailway.
  ///
  /// In de, this message translates to:
  /// **'Bahn'**
  String get sightsGroupRailway;

  /// No description provided for @sightSubAttraction.
  ///
  /// In de, this message translates to:
  /// **'Sehenswürdigkeit'**
  String get sightSubAttraction;

  /// No description provided for @sightSubViewpoint.
  ///
  /// In de, this message translates to:
  /// **'Aussichtspunkt'**
  String get sightSubViewpoint;

  /// No description provided for @sightSubMuseum.
  ///
  /// In de, this message translates to:
  /// **'Museum'**
  String get sightSubMuseum;

  /// No description provided for @sightSubArtwork.
  ///
  /// In de, this message translates to:
  /// **'Kunstwerk'**
  String get sightSubArtwork;

  /// No description provided for @sightSubPicnicSite.
  ///
  /// In de, this message translates to:
  /// **'Picknickplatz'**
  String get sightSubPicnicSite;

  /// No description provided for @sightSubInformation.
  ///
  /// In de, this message translates to:
  /// **'Touristen-Info'**
  String get sightSubInformation;

  /// No description provided for @sightSubHotel.
  ///
  /// In de, this message translates to:
  /// **'Hotel'**
  String get sightSubHotel;

  /// No description provided for @sightSubGuestHouse.
  ///
  /// In de, this message translates to:
  /// **'Pension'**
  String get sightSubGuestHouse;

  /// No description provided for @sightSubHostel.
  ///
  /// In de, this message translates to:
  /// **'Hostel'**
  String get sightSubHostel;

  /// No description provided for @sightSubCampSite.
  ///
  /// In de, this message translates to:
  /// **'Campingplatz'**
  String get sightSubCampSite;

  /// No description provided for @sightSubCastle.
  ///
  /// In de, this message translates to:
  /// **'Burg/Schloss'**
  String get sightSubCastle;

  /// No description provided for @sightSubMonument.
  ///
  /// In de, this message translates to:
  /// **'Denkmal'**
  String get sightSubMonument;

  /// No description provided for @sightSubMemorial.
  ///
  /// In de, this message translates to:
  /// **'Gedenkstätte'**
  String get sightSubMemorial;

  /// No description provided for @sightSubRuins.
  ///
  /// In de, this message translates to:
  /// **'Ruine'**
  String get sightSubRuins;

  /// No description provided for @sightSubArchaeological.
  ///
  /// In de, this message translates to:
  /// **'Archäologische Stätte'**
  String get sightSubArchaeological;

  /// No description provided for @sightSubPeak.
  ///
  /// In de, this message translates to:
  /// **'Gipfel'**
  String get sightSubPeak;

  /// No description provided for @sightSubWaterfall.
  ///
  /// In de, this message translates to:
  /// **'Wasserfall'**
  String get sightSubWaterfall;

  /// No description provided for @sightSubCave.
  ///
  /// In de, this message translates to:
  /// **'Höhle'**
  String get sightSubCave;

  /// No description provided for @sightSubSupermarket.
  ///
  /// In de, this message translates to:
  /// **'Supermarkt'**
  String get sightSubSupermarket;

  /// No description provided for @sightSubBakery.
  ///
  /// In de, this message translates to:
  /// **'Bäckerei'**
  String get sightSubBakery;

  /// No description provided for @sightSubConvenience.
  ///
  /// In de, this message translates to:
  /// **'Kiosk/Späti'**
  String get sightSubConvenience;

  /// No description provided for @sightSubBicycleShop.
  ///
  /// In de, this message translates to:
  /// **'Fahrradladen'**
  String get sightSubBicycleShop;

  /// No description provided for @sightSubRestaurant.
  ///
  /// In de, this message translates to:
  /// **'Restaurant'**
  String get sightSubRestaurant;

  /// No description provided for @sightSubCafe.
  ///
  /// In de, this message translates to:
  /// **'Café'**
  String get sightSubCafe;

  /// No description provided for @sightSubFastFood.
  ///
  /// In de, this message translates to:
  /// **'Imbiss'**
  String get sightSubFastFood;

  /// No description provided for @sightSubBiergarten.
  ///
  /// In de, this message translates to:
  /// **'Biergarten'**
  String get sightSubBiergarten;

  /// No description provided for @sightSubPub.
  ///
  /// In de, this message translates to:
  /// **'Kneipe'**
  String get sightSubPub;

  /// No description provided for @sightSubDrinkingWater.
  ///
  /// In de, this message translates to:
  /// **'Trinkwasser'**
  String get sightSubDrinkingWater;

  /// No description provided for @sightSubToilets.
  ///
  /// In de, this message translates to:
  /// **'Toilette'**
  String get sightSubToilets;

  /// No description provided for @sightSubPharmacy.
  ///
  /// In de, this message translates to:
  /// **'Apotheke'**
  String get sightSubPharmacy;

  /// No description provided for @sightSubAtm.
  ///
  /// In de, this message translates to:
  /// **'Geldautomat'**
  String get sightSubAtm;

  /// No description provided for @sightSubBicycleRepair.
  ///
  /// In de, this message translates to:
  /// **'Fahrrad-Reparaturstation'**
  String get sightSubBicycleRepair;

  /// No description provided for @sightSubBicycleRental.
  ///
  /// In de, this message translates to:
  /// **'Fahrradverleih'**
  String get sightSubBicycleRental;

  /// No description provided for @sightSubChargingStation.
  ///
  /// In de, this message translates to:
  /// **'Ladesäule'**
  String get sightSubChargingStation;

  /// No description provided for @sightSubStation.
  ///
  /// In de, this message translates to:
  /// **'Bahnhof'**
  String get sightSubStation;

  /// No description provided for @sightSubHalt.
  ///
  /// In de, this message translates to:
  /// **'Haltepunkt'**
  String get sightSubHalt;

  /// No description provided for @sightSubTramStop.
  ///
  /// In de, this message translates to:
  /// **'Straßenbahn-Halt'**
  String get sightSubTramStop;

  /// No description provided for @poiCatLodging.
  ///
  /// In de, this message translates to:
  /// **'Unterkunft'**
  String get poiCatLodging;

  /// No description provided for @poiCatFood.
  ///
  /// In de, this message translates to:
  /// **'Verpflegung'**
  String get poiCatFood;

  /// No description provided for @poiCatWater.
  ///
  /// In de, this message translates to:
  /// **'Trinkwasser'**
  String get poiCatWater;

  /// No description provided for @poiCatShop.
  ///
  /// In de, this message translates to:
  /// **'Einkauf'**
  String get poiCatShop;

  /// No description provided for @poiCatFuel.
  ///
  /// In de, this message translates to:
  /// **'Tankstelle'**
  String get poiCatFuel;

  /// No description provided for @poiCatCharging.
  ///
  /// In de, this message translates to:
  /// **'Ladestation'**
  String get poiCatCharging;

  /// No description provided for @poiCatSights.
  ///
  /// In de, this message translates to:
  /// **'Sehenswürdigkeiten'**
  String get poiCatSights;

  /// No description provided for @poiCatScenic.
  ///
  /// In de, this message translates to:
  /// **'Aussicht'**
  String get poiCatScenic;

  /// No description provided for @poiCatShelter.
  ///
  /// In de, this message translates to:
  /// **'Schutzhütte'**
  String get poiCatShelter;

  /// No description provided for @sacBadgePrefix.
  ///
  /// In de, this message translates to:
  /// **'Schwierigkeit:'**
  String get sacBadgePrefix;

  /// No description provided for @sacT1.
  ///
  /// In de, this message translates to:
  /// **'Wandern (T1)'**
  String get sacT1;

  /// No description provided for @sacT2.
  ///
  /// In de, this message translates to:
  /// **'Bergwandern (T2)'**
  String get sacT2;

  /// No description provided for @sacT3.
  ///
  /// In de, this message translates to:
  /// **'Anspruchsvolles Bergwandern (T3)'**
  String get sacT3;

  /// No description provided for @sacT4.
  ///
  /// In de, this message translates to:
  /// **'Alpinwandern (T4)'**
  String get sacT4;

  /// No description provided for @sacT5.
  ///
  /// In de, this message translates to:
  /// **'Anspruchsvolles Alpinwandern (T5)'**
  String get sacT5;

  /// No description provided for @sacT6.
  ///
  /// In de, this message translates to:
  /// **'Schwieriges Alpinwandern (T6)'**
  String get sacT6;

  /// No description provided for @preferHikingRoutesLabel.
  ///
  /// In de, this message translates to:
  /// **'Wanderwege bevorzugen'**
  String get preferHikingRoutesLabel;

  /// No description provided for @hikingPresetTitle.
  ///
  /// In de, this message translates to:
  /// **'Schwierigkeitsstufe'**
  String get hikingPresetTitle;

  /// No description provided for @hikingPresetComfortable.
  ///
  /// In de, this message translates to:
  /// **'Gemütlich'**
  String get hikingPresetComfortable;

  /// No description provided for @hikingPresetSporty.
  ///
  /// In de, this message translates to:
  /// **'Sportlich'**
  String get hikingPresetSporty;

  /// No description provided for @hikingPresetMountain.
  ///
  /// In de, this message translates to:
  /// **'Bergtour'**
  String get hikingPresetMountain;

  /// No description provided for @actionPauseRecommendations.
  ///
  /// In de, this message translates to:
  /// **'Pausen'**
  String get actionPauseRecommendations;

  /// No description provided for @pauseRecsTooShort.
  ///
  /// In de, this message translates to:
  /// **'Route ist zu kurz für Pausen-Empfehlungen (mind. 1.5 h).'**
  String get pauseRecsTooShort;

  /// No description provided for @pauseRecsNone.
  ///
  /// In de, this message translates to:
  /// **'Keine Pausenplätze in der Nähe der Route gefunden.'**
  String get pauseRecsNone;

  /// No description provided for @pauseRecsFailed.
  ///
  /// In de, this message translates to:
  /// **'Pausensuche fehlgeschlagen: {error}'**
  String pauseRecsFailed(String error);

  /// No description provided for @poiCatPicnic.
  ///
  /// In de, this message translates to:
  /// **'Picknickplatz'**
  String get poiCatPicnic;

  /// No description provided for @poiCatStation.
  ///
  /// In de, this message translates to:
  /// **'Bahnhof'**
  String get poiCatStation;

  /// No description provided for @settingsBikepackingMode.
  ///
  /// In de, this message translates to:
  /// **'Bikepacking-Modus'**
  String get settingsBikepackingMode;

  /// No description provided for @settingsBikepackingModeSub.
  ///
  /// In de, this message translates to:
  /// **'Priorisiert Camping, Wasser, Schutzhütten und Bahnhöfe in der POI-Suche'**
  String get settingsBikepackingModeSub;

  /// No description provided for @stagesStartDateLabel.
  ///
  /// In de, this message translates to:
  /// **'Starttag:'**
  String get stagesStartDateLabel;

  /// No description provided for @stagesOvernightUnnamed.
  ///
  /// In de, this message translates to:
  /// **'(Unbenannte Unterkunft)'**
  String get stagesOvernightUnnamed;

  /// No description provided for @rideRecoveredSnack.
  ///
  /// In de, this message translates to:
  /// **'Unterbrochene Aufzeichnung wiederhergestellt ({km} km). Findest du unter „Aufzeichnungen\".'**
  String rideRecoveredSnack(String km);

  /// No description provided for @wildCampDisclaimerTitle.
  ///
  /// In de, this message translates to:
  /// **'Wildcampen — bitte beachten'**
  String get wildCampDisclaimerTitle;

  /// No description provided for @wildCampDisclaimerBody.
  ///
  /// In de, this message translates to:
  /// **'Bikepacking-Modus zeigt auch informelle Zeltplätze (camp_pitch) in der POI-Suche.\n\nIn Deutschland ist Wildcampen außerhalb ausgewiesener Plätze meist verboten — die genauen Regeln hängen vom Bundesland und Forstrecht ab. In Schweden/Norwegen/Finnland gilt das Jedermannsrecht. Informiere dich vor jeder Übernachtung selbst — Wegwiesel übernimmt keine Haftung für die rechtliche Lage am gewählten Ort.'**
  String get wildCampDisclaimerBody;

  /// No description provided for @shareToWahoo.
  ///
  /// In de, this message translates to:
  /// **'An Wahoo senden'**
  String get shareToWahoo;

  /// No description provided for @shareToWahooSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wahoo Companion App öffnet die Route automatisch'**
  String get shareToWahooSubtitle;

  /// No description provided for @wahooSendFailed.
  ///
  /// In de, this message translates to:
  /// **'Senden an Wahoo fehlgeschlagen: {error}'**
  String wahooSendFailed(String error);

  /// No description provided for @wahooNotInstalledTitle.
  ///
  /// In de, this message translates to:
  /// **'Wahoo-App nicht gefunden'**
  String get wahooNotInstalledTitle;

  /// No description provided for @wahooNotInstalledBody.
  ///
  /// In de, this message translates to:
  /// **'Installiere die „Wahoo Companion\"- bzw. „Wahoo Fitness\"-App aus dem App Store / Play Store und versuche es erneut.'**
  String get wahooNotInstalledBody;

  /// No description provided for @menuFindFtpRoute.
  ///
  /// In de, this message translates to:
  /// **'Trainingsstrecke finden'**
  String get menuFindFtpRoute;

  /// No description provided for @ftpFinderTitle.
  ///
  /// In de, this message translates to:
  /// **'FTP-Test-Strecke finden'**
  String get ftpFinderTitle;

  /// No description provided for @ftpFinderTest20.
  ///
  /// In de, this message translates to:
  /// **'20-min'**
  String get ftpFinderTest20;

  /// No description provided for @ftpFinderTest8.
  ///
  /// In de, this message translates to:
  /// **'8-min (2×)'**
  String get ftpFinderTest8;

  /// No description provided for @ftpFinderTestRamp.
  ///
  /// In de, this message translates to:
  /// **'Stufentest'**
  String get ftpFinderTestRamp;

  /// No description provided for @ftpFinderTestSweetSpot.
  ///
  /// In de, this message translates to:
  /// **'Sweet Spot'**
  String get ftpFinderTestSweetSpot;

  /// No description provided for @ftpFinderModeFlat.
  ///
  /// In de, this message translates to:
  /// **'Flach'**
  String get ftpFinderModeFlat;

  /// No description provided for @ftpFinderModeClimb.
  ///
  /// In de, this message translates to:
  /// **'Bergauf'**
  String get ftpFinderModeClimb;

  /// No description provided for @ftpFinderModeEither.
  ///
  /// In de, this message translates to:
  /// **'Beides'**
  String get ftpFinderModeEither;

  /// No description provided for @ftpFinderRadius.
  ///
  /// In de, this message translates to:
  /// **'Umkreis: {km} km'**
  String ftpFinderRadius(int km);

  /// No description provided for @ftpFinderSearch.
  ///
  /// In de, this message translates to:
  /// **'Strecke suchen'**
  String get ftpFinderSearch;

  /// No description provided for @ftpFinderPickToSearch.
  ///
  /// In de, this message translates to:
  /// **'Test-Typ wählen und „Strecke suchen\" tippen.'**
  String get ftpFinderPickToSearch;

  /// No description provided for @ftpFinderEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine passende Strecke im Umkreis gefunden. Versuche einen größeren Radius oder einen anderen Test-Typ.'**
  String get ftpFinderEmpty;

  /// No description provided for @ftpFinderUnnamed.
  ///
  /// In de, this message translates to:
  /// **'Unbenannte Strecke'**
  String get ftpFinderUnnamed;

  /// No description provided for @ftpFinderPicked.
  ///
  /// In de, this message translates to:
  /// **'Strecke ausgewählt ({km} km). Schon mal aufwärmen?'**
  String ftpFinderPicked(String km);

  /// No description provided for @ftpFinderStartRecord.
  ///
  /// In de, this message translates to:
  /// **'Aufzeichnung starten'**
  String get ftpFinderStartRecord;

  /// No description provided for @ftpFinderOriginWaypoint.
  ///
  /// In de, this message translates to:
  /// **'Suche um den gesetzten Startpunkt.'**
  String get ftpFinderOriginWaypoint;

  /// No description provided for @ftpFinderOriginGps.
  ///
  /// In de, this message translates to:
  /// **'Suche um deine aktuelle GPS-Position.'**
  String get ftpFinderOriginGps;

  /// No description provided for @ftpFinderOriginMapView.
  ///
  /// In de, this message translates to:
  /// **'Suche um den Kartenmittelpunkt. Für ein besseres Ergebnis erst einen Punkt auf der Karte tippen oder GPS einschalten.'**
  String get ftpFinderOriginMapView;

  /// No description provided for @menuRouteSourcesTooltip.
  ///
  /// In de, this message translates to:
  /// **'Routen-Quellen'**
  String get menuRouteSourcesTooltip;

  /// No description provided for @poiCatCamping.
  ///
  /// In de, this message translates to:
  /// **'Camping'**
  String get poiCatCamping;

  /// No description provided for @poiCatInfo.
  ///
  /// In de, this message translates to:
  /// **'Information'**
  String get poiCatInfo;

  /// No description provided for @poiCatOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get poiCatOther;

  /// No description provided for @routePoiSearchTitle.
  ///
  /// In de, this message translates to:
  /// **'Auf der Route suchen'**
  String get routePoiSearchTitle;

  /// No description provided for @routePoiSearchEmpty.
  ///
  /// In de, this message translates to:
  /// **'Nichts entlang der Route gefunden'**
  String get routePoiSearchEmpty;

  /// No description provided for @routePoiSearchPickCategories.
  ///
  /// In de, this message translates to:
  /// **'Kategorien wählen'**
  String get routePoiSearchPickCategories;

  /// No description provided for @routePoiSearchAt.
  ///
  /// In de, this message translates to:
  /// **'bei {km} km'**
  String routePoiSearchAt(String km);

  /// No description provided for @routePoiSearchSide.
  ///
  /// In de, this message translates to:
  /// **'{m} m abseits'**
  String routePoiSearchSide(int m);

  /// No description provided for @routePoiSearchAdd.
  ///
  /// In de, this message translates to:
  /// **'Zur Route'**
  String get routePoiSearchAdd;

  /// No description provided for @menuSearchAlongRoute.
  ///
  /// In de, this message translates to:
  /// **'Auf der Route suchen'**
  String get menuSearchAlongRoute;

  /// No description provided for @defaultWaypoint.
  ///
  /// In de, this message translates to:
  /// **'Zielpunkt'**
  String get defaultWaypoint;

  /// No description provided for @defaultTourName.
  ///
  /// In de, this message translates to:
  /// **'Wegwiesel-Tour'**
  String get defaultTourName;

  /// No description provided for @roundtripTourName.
  ///
  /// In de, this message translates to:
  /// **'Rundtour {km}km'**
  String roundtripTourName(int km);

  /// No description provided for @stageTooltip.
  ///
  /// In de, this message translates to:
  /// **'Etappe {index}: {km} km'**
  String stageTooltip(int index, String km);

  /// No description provided for @osmRouteTypeBicycle.
  ///
  /// In de, this message translates to:
  /// **'Radroute'**
  String get osmRouteTypeBicycle;

  /// No description provided for @osmRouteTypeHiking.
  ///
  /// In de, this message translates to:
  /// **'Wanderweg'**
  String get osmRouteTypeHiking;

  /// No description provided for @osmRouteTypeMtb.
  ///
  /// In de, this message translates to:
  /// **'MTB-Route'**
  String get osmRouteTypeMtb;

  /// No description provided for @osmNetworkIcn.
  ///
  /// In de, this message translates to:
  /// **'International'**
  String get osmNetworkIcn;

  /// No description provided for @osmNetworkNcn.
  ///
  /// In de, this message translates to:
  /// **'National'**
  String get osmNetworkNcn;

  /// No description provided for @osmNetworkRcn.
  ///
  /// In de, this message translates to:
  /// **'Regional'**
  String get osmNetworkRcn;

  /// No description provided for @osmNetworkLcn.
  ///
  /// In de, this message translates to:
  /// **'Lokal'**
  String get osmNetworkLcn;

  /// No description provided for @osmNetworkIwn.
  ///
  /// In de, this message translates to:
  /// **'International (Wandern)'**
  String get osmNetworkIwn;

  /// No description provided for @osmNetworkNwn.
  ///
  /// In de, this message translates to:
  /// **'National (Wandern)'**
  String get osmNetworkNwn;

  /// No description provided for @osmNetworkRwn.
  ///
  /// In de, this message translates to:
  /// **'Regional (Wandern)'**
  String get osmNetworkRwn;

  /// No description provided for @osmNetworkLwn.
  ///
  /// In de, this message translates to:
  /// **'Lokal (Wandern)'**
  String get osmNetworkLwn;

  /// No description provided for @profileModeGradient.
  ///
  /// In de, this message translates to:
  /// **'Steigung'**
  String get profileModeGradient;

  /// No description provided for @profileModeSurface.
  ///
  /// In de, this message translates to:
  /// **'Oberfläche'**
  String get profileModeSurface;

  /// No description provided for @profileModeHighway.
  ///
  /// In de, this message translates to:
  /// **'Straßentyp'**
  String get profileModeHighway;

  /// No description provided for @profileModeSmoothness.
  ///
  /// In de, this message translates to:
  /// **'Rauheit'**
  String get profileModeSmoothness;

  /// No description provided for @profileModeMaxSpeed.
  ///
  /// In de, this message translates to:
  /// **'Tempolimit'**
  String get profileModeMaxSpeed;

  /// No description provided for @profileModeCost.
  ///
  /// In de, this message translates to:
  /// **'Routingkosten'**
  String get profileModeCost;

  /// No description provided for @profileZoomLocked.
  ///
  /// In de, this message translates to:
  /// **'Zoom gesperrt'**
  String get profileZoomLocked;

  /// No description provided for @profileZoomUnlocked.
  ///
  /// In de, this message translates to:
  /// **'Zoom frei'**
  String get profileZoomUnlocked;

  /// No description provided for @profileZoomReset.
  ///
  /// In de, this message translates to:
  /// **'Zoom zurücksetzen'**
  String get profileZoomReset;

  /// No description provided for @profileSimplifiedWarning.
  ///
  /// In de, this message translates to:
  /// **'Vereinfachte Darstellung — hineinzoomen für Details'**
  String get profileSimplifiedWarning;

  /// No description provided for @profileTooltipDistance.
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get profileTooltipDistance;

  /// No description provided for @profileTooltipElevation.
  ///
  /// In de, this message translates to:
  /// **'Höhe'**
  String get profileTooltipElevation;

  /// No description provided for @profileTooltipGradient.
  ///
  /// In de, this message translates to:
  /// **'Steigung'**
  String get profileTooltipGradient;

  /// No description provided for @profileTooltipAscent.
  ///
  /// In de, this message translates to:
  /// **'Anstieg'**
  String get profileTooltipAscent;

  /// No description provided for @profileTooltipHighway.
  ///
  /// In de, this message translates to:
  /// **'Straße'**
  String get profileTooltipHighway;

  /// No description provided for @profileTooltipSurface.
  ///
  /// In de, this message translates to:
  /// **'Oberfläche'**
  String get profileTooltipSurface;

  /// No description provided for @profileTooltipSmoothness.
  ///
  /// In de, this message translates to:
  /// **'Rauheit'**
  String get profileTooltipSmoothness;

  /// No description provided for @profileTooltipMaxSpeed.
  ///
  /// In de, this message translates to:
  /// **'Tempo'**
  String get profileTooltipMaxSpeed;

  /// No description provided for @profileTooltipCost.
  ///
  /// In de, this message translates to:
  /// **'Kosten'**
  String get profileTooltipCost;

  /// No description provided for @smoothnessExcellent.
  ///
  /// In de, this message translates to:
  /// **'Sehr gut'**
  String get smoothnessExcellent;

  /// No description provided for @smoothnessGood.
  ///
  /// In de, this message translates to:
  /// **'Gut'**
  String get smoothnessGood;

  /// No description provided for @smoothnessIntermediate.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get smoothnessIntermediate;

  /// No description provided for @smoothnessBad.
  ///
  /// In de, this message translates to:
  /// **'Schlecht'**
  String get smoothnessBad;

  /// No description provided for @smoothnessUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get smoothnessUnknown;

  /// No description provided for @mapStyleStandard.
  ///
  /// In de, this message translates to:
  /// **'Standard'**
  String get mapStyleStandard;

  /// No description provided for @mapStyleCycling.
  ///
  /// In de, this message translates to:
  /// **'Fahrrad'**
  String get mapStyleCycling;

  /// No description provided for @mapStyleTopo.
  ///
  /// In de, this message translates to:
  /// **'Topo'**
  String get mapStyleTopo;

  /// No description provided for @mapStyleSatellite.
  ///
  /// In de, this message translates to:
  /// **'Satellit'**
  String get mapStyleSatellite;

  /// No description provided for @routeOverlayCycling.
  ///
  /// In de, this message translates to:
  /// **'Radrouten'**
  String get routeOverlayCycling;

  /// No description provided for @routeOverlayHiking.
  ///
  /// In de, this message translates to:
  /// **'Wanderwege'**
  String get routeOverlayHiking;

  /// No description provided for @routeOverlayMtb.
  ///
  /// In de, this message translates to:
  /// **'MTB-Routen'**
  String get routeOverlayMtb;

  /// No description provided for @routeOverlayHillshade.
  ///
  /// In de, this message translates to:
  /// **'Höhenschummerung'**
  String get routeOverlayHillshade;

  /// No description provided for @routeOverlayHeatmap.
  ///
  /// In de, this message translates to:
  /// **'Wegwiesel-Heatmap'**
  String get routeOverlayHeatmap;

  /// No description provided for @gpxImportTitle.
  ///
  /// In de, this message translates to:
  /// **'GPX-Track importieren'**
  String get gpxImportTitle;

  /// No description provided for @gpxImportButton.
  ///
  /// In de, this message translates to:
  /// **'GPX-Datei wählen'**
  String get gpxImportButton;

  /// No description provided for @gpxImportFailed.
  ///
  /// In de, this message translates to:
  /// **'Import fehlgeschlagen: {error}'**
  String gpxImportFailed(String error);

  /// No description provided for @gpxImportSuccess.
  ///
  /// In de, this message translates to:
  /// **'Track geladen: {points} Punkte, {km} km'**
  String gpxImportSuccess(int points, String km);

  /// No description provided for @gpxImportEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Trackpunkte in der Datei gefunden'**
  String get gpxImportEmpty;

  /// No description provided for @gpxModeTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie soll der Track importiert werden?'**
  String get gpxModeTitle;

  /// No description provided for @gpxModeSummary.
  ///
  /// In de, this message translates to:
  /// **'{points} Punkte · {km} km'**
  String gpxModeSummary(int points, String km);

  /// No description provided for @gpxModeRerouteTitle.
  ///
  /// In de, this message translates to:
  /// **'Mit deinem Profil nachrouten'**
  String get gpxModeRerouteTitle;

  /// No description provided for @gpxModeRerouteBody.
  ///
  /// In de, this message translates to:
  /// **'Wegwiesel berechnet die Strecke mit dem aktuell gewählten Profil. Du bekommst Belag-Anzeige, Höhenprofil-Farben, Turn-by-Turn-Navigation und Sprachausgabe. Strecke kann leicht abweichen.'**
  String get gpxModeRerouteBody;

  /// No description provided for @gpxModeTrackTitle.
  ///
  /// In de, this message translates to:
  /// **'Track 1:1 übernehmen'**
  String get gpxModeTrackTitle;

  /// No description provided for @gpxModeTrackBody.
  ///
  /// In de, this message translates to:
  /// **'Original-Geometrie unverändert anzeigen. Keine Belag-Info, keine Sprach-Navigation — gut wenn die Tour exakt so gefahren werden soll.'**
  String get gpxModeTrackBody;

  /// No description provided for @urlImportTitle.
  ///
  /// In de, this message translates to:
  /// **'Tour-URL importieren'**
  String get urlImportTitle;

  /// No description provided for @urlImportHint.
  ///
  /// In de, this message translates to:
  /// **'Komoot-Link oder direkter GPX-Link'**
  String get urlImportHint;

  /// No description provided for @urlImportFetch.
  ///
  /// In de, this message translates to:
  /// **'Laden'**
  String get urlImportFetch;

  /// No description provided for @urlImportCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get urlImportCancel;

  /// No description provided for @urlImportLoading.
  ///
  /// In de, this message translates to:
  /// **'Tour wird geladen…'**
  String get urlImportLoading;

  /// No description provided for @urlImportErrEmpty.
  ///
  /// In de, this message translates to:
  /// **'Bitte URL eingeben'**
  String get urlImportErrEmpty;

  /// No description provided for @urlImportErrInvalid.
  ///
  /// In de, this message translates to:
  /// **'URL ist ungültig'**
  String get urlImportErrInvalid;

  /// No description provided for @urlImportErrNetwork.
  ///
  /// In de, this message translates to:
  /// **'Netzwerkfehler'**
  String get urlImportErrNetwork;

  /// No description provided for @urlImportErrForbidden.
  ///
  /// In de, this message translates to:
  /// **'Tour ist privat oder benötigt Login'**
  String get urlImportErrForbidden;

  /// No description provided for @urlImportErrNotFound.
  ///
  /// In de, this message translates to:
  /// **'Tour nicht gefunden'**
  String get urlImportErrNotFound;

  /// No description provided for @urlImportErrNotGpx.
  ///
  /// In de, this message translates to:
  /// **'Keine GPX-Daten unter der URL'**
  String get urlImportErrNotGpx;

  /// No description provided for @urlImportErrStravaLogin.
  ///
  /// In de, this message translates to:
  /// **'Strava-Routen können wegen Login-Pflicht nicht direkt importiert werden — bitte GPX manuell exportieren und über „GPX importieren\" öffnen'**
  String get urlImportErrStravaLogin;

  /// No description provided for @nogoTitle.
  ///
  /// In de, this message translates to:
  /// **'Sperrzonen'**
  String get nogoTitle;

  /// No description provided for @nogoEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Sperrzonen definiert'**
  String get nogoEmpty;

  /// No description provided for @nogoAdd.
  ///
  /// In de, this message translates to:
  /// **'Sperrzone hinzufügen'**
  String get nogoAdd;

  /// No description provided for @nogoAddHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf die Karte, um eine Sperrzone zu setzen'**
  String get nogoAddHint;

  /// No description provided for @nogoRadius.
  ///
  /// In de, this message translates to:
  /// **'Radius: {meters} m'**
  String nogoRadius(int meters);

  /// No description provided for @nogoDelete.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get nogoDelete;

  /// No description provided for @nogoConfirmCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get nogoConfirmCancel;

  /// No description provided for @nogoConfirmAdd.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get nogoConfirmAdd;

  /// No description provided for @menuImportGpx.
  ///
  /// In de, this message translates to:
  /// **'GPX importieren'**
  String get menuImportGpx;

  /// No description provided for @menuImportUrl.
  ///
  /// In de, this message translates to:
  /// **'Tour-URL importieren'**
  String get menuImportUrl;

  /// No description provided for @menuNogos.
  ///
  /// In de, this message translates to:
  /// **'Sperrzonen'**
  String get menuNogos;

  /// No description provided for @menuRecording.
  ///
  /// In de, this message translates to:
  /// **'Fahrt aufzeichnen'**
  String get menuRecording;

  /// No description provided for @menuRecordedRides.
  ///
  /// In de, this message translates to:
  /// **'Aufzeichnungen'**
  String get menuRecordedRides;

  /// No description provided for @menuLibrary.
  ///
  /// In de, this message translates to:
  /// **'Routen entdecken'**
  String get menuLibrary;

  /// No description provided for @menuPublishRoute.
  ///
  /// In de, this message translates to:
  /// **'Route veröffentlichen'**
  String get menuPublishRoute;

  /// No description provided for @menuOfflineMaps.
  ///
  /// In de, this message translates to:
  /// **'Offline-Karten'**
  String get menuOfflineMaps;

  /// No description provided for @offlineMapsTitle.
  ///
  /// In de, this message translates to:
  /// **'Offline-Karten'**
  String get offlineMapsTitle;

  /// No description provided for @offlineMapsCurrentSection.
  ///
  /// In de, this message translates to:
  /// **'Cache'**
  String get offlineMapsCurrentSection;

  /// No description provided for @offlineMapsDownloadSection.
  ///
  /// In de, this message translates to:
  /// **'Herunterladen'**
  String get offlineMapsDownloadSection;

  /// No description provided for @offlineMapsProgressSection.
  ///
  /// In de, this message translates to:
  /// **'Download läuft'**
  String get offlineMapsProgressSection;

  /// No description provided for @offlineMapsUsed.
  ///
  /// In de, this message translates to:
  /// **'Belegt'**
  String get offlineMapsUsed;

  /// No description provided for @offlineMapsLimit.
  ///
  /// In de, this message translates to:
  /// **'Speicher-Limit'**
  String get offlineMapsLimit;

  /// No description provided for @offlineMapsClearTitle.
  ///
  /// In de, this message translates to:
  /// **'Cache leeren'**
  String get offlineMapsClearTitle;

  /// No description provided for @offlineMapsClearSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Alle gecachten Kacheln entfernen'**
  String get offlineMapsClearSubtitle;

  /// No description provided for @offlineMapsClearBody.
  ///
  /// In de, this message translates to:
  /// **'Alle gespeicherten Kartenkacheln werden gelöscht. Sie werden bei der nächsten Online-Nutzung neu geladen.'**
  String get offlineMapsClearBody;

  /// No description provided for @offlineMapsDownloadCurrent.
  ///
  /// In de, this message translates to:
  /// **'Aktuellen Ausschnitt herunterladen'**
  String get offlineMapsDownloadCurrent;

  /// No description provided for @offlineMapsDownloadCurrentSub.
  ///
  /// In de, this message translates to:
  /// **'Karten-Kacheln Zoom 8–15 für den sichtbaren Bereich vorab laden'**
  String get offlineMapsDownloadCurrentSub;

  /// No description provided for @offlineMapsNoViewport.
  ///
  /// In de, this message translates to:
  /// **'Bitte zuerst den gewünschten Kartenausschnitt auf der Karte einstellen'**
  String get offlineMapsNoViewport;

  /// No description provided for @offlineMapsConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Region herunterladen?'**
  String get offlineMapsConfirmTitle;

  /// No description provided for @offlineMapsConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'Geschätzte Größe: ca. {mb} MB. Während des Downloads bitte die App offen lassen.'**
  String offlineMapsConfirmBody(int mb);

  /// No description provided for @offlineMapsStart.
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get offlineMapsStart;

  /// No description provided for @offlineMapsProgressLine.
  ///
  /// In de, this message translates to:
  /// **'{done} von {total} Kacheln'**
  String offlineMapsProgressLine(int done, int total);

  /// No description provided for @offlineMapsProgressDone.
  ///
  /// In de, this message translates to:
  /// **'{total} Kacheln offline verfügbar'**
  String offlineMapsProgressDone(int total);

  /// No description provided for @libraryTitle.
  ///
  /// In de, this message translates to:
  /// **'Routen entdecken'**
  String get libraryTitle;

  /// No description provided for @libraryEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine öffentlichen Routen in diesem Filter'**
  String get libraryEmpty;

  /// No description provided for @libraryFilterAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get libraryFilterAll;

  /// No description provided for @libraryFilterNear.
  ///
  /// In de, this message translates to:
  /// **'In meiner Nähe'**
  String get libraryFilterNear;

  /// No description provided for @libraryFilterShort.
  ///
  /// In de, this message translates to:
  /// **'kurz (< 30 km)'**
  String get libraryFilterShort;

  /// No description provided for @libraryFilterMedium.
  ///
  /// In de, this message translates to:
  /// **'mittel (30–80 km)'**
  String get libraryFilterMedium;

  /// No description provided for @libraryFilterLong.
  ///
  /// In de, this message translates to:
  /// **'lang (> 80 km)'**
  String get libraryFilterLong;

  /// No description provided for @libraryItemBy.
  ///
  /// In de, this message translates to:
  /// **'von Wegwiesel-User'**
  String get libraryItemBy;

  /// No description provided for @librarySearchHint.
  ///
  /// In de, this message translates to:
  /// **'Titel oder Beschreibung suchen…'**
  String get librarySearchHint;

  /// No description provided for @libraryLoadFailed.
  ///
  /// In de, this message translates to:
  /// **'Konnte Bibliothek nicht laden'**
  String get libraryLoadFailed;

  /// No description provided for @libraryOpenFailed.
  ///
  /// In de, this message translates to:
  /// **'Route konnte nicht geladen werden'**
  String get libraryOpenFailed;

  /// No description provided for @publishTitle.
  ///
  /// In de, this message translates to:
  /// **'Route veröffentlichen'**
  String get publishTitle;

  /// No description provided for @publishExplain.
  ///
  /// In de, this message translates to:
  /// **'Deine Route wird mit Titel und Beschreibung öffentlich sichtbar. Keine Account-Bindung, kein Tracking — nur du kannst sie über die Wegwiesel-App auf diesem Gerät wieder zurückziehen.'**
  String get publishExplain;

  /// No description provided for @publishNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get publishNameLabel;

  /// No description provided for @publishNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Rheinradweg von Mainz nach Koblenz'**
  String get publishNameHint;

  /// No description provided for @publishDescriptionLabel.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get publishDescriptionLabel;

  /// No description provided for @publishDescriptionHint.
  ///
  /// In de, this message translates to:
  /// **'Was macht diese Route besonders?'**
  String get publishDescriptionHint;

  /// No description provided for @publishConfirm.
  ///
  /// In de, this message translates to:
  /// **'Veröffentlichen'**
  String get publishConfirm;

  /// No description provided for @publishSuccess.
  ///
  /// In de, this message translates to:
  /// **'Route ist jetzt öffentlich'**
  String get publishSuccess;

  /// No description provided for @publishFailed.
  ///
  /// In de, this message translates to:
  /// **'Veröffentlichen fehlgeschlagen'**
  String get publishFailed;

  /// No description provided for @publishUnpublish.
  ///
  /// In de, this message translates to:
  /// **'Aus der Bibliothek entfernen'**
  String get publishUnpublish;

  /// No description provided for @publishUnpublished.
  ///
  /// In de, this message translates to:
  /// **'Route entfernt'**
  String get publishUnpublished;

  /// No description provided for @recordingTitle.
  ///
  /// In de, this message translates to:
  /// **'Aufzeichnung'**
  String get recordingTitle;

  /// No description provided for @recordingStart.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get recordingStart;

  /// No description provided for @recordingPause.
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get recordingPause;

  /// No description provided for @recordingResume.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get recordingResume;

  /// No description provided for @recordingStop.
  ///
  /// In de, this message translates to:
  /// **'Stop'**
  String get recordingStop;

  /// No description provided for @recordingPermissionDenied.
  ///
  /// In de, this message translates to:
  /// **'Standortfreigabe wird benötigt'**
  String get recordingPermissionDenied;

  /// No description provided for @recordingDistance.
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get recordingDistance;

  /// No description provided for @recordingDuration.
  ///
  /// In de, this message translates to:
  /// **'Zeit'**
  String get recordingDuration;

  /// No description provided for @recordingAvgSpeed.
  ///
  /// In de, this message translates to:
  /// **'⌀ Tempo'**
  String get recordingAvgSpeed;

  /// No description provided for @recordingMaxSpeed.
  ///
  /// In de, this message translates to:
  /// **'Max Tempo'**
  String get recordingMaxSpeed;

  /// No description provided for @recordingAscent.
  ///
  /// In de, this message translates to:
  /// **'Aufstieg'**
  String get recordingAscent;

  /// No description provided for @recordingDescent.
  ///
  /// In de, this message translates to:
  /// **'Abstieg'**
  String get recordingDescent;

  /// No description provided for @recordingKcal.
  ///
  /// In de, this message translates to:
  /// **'Kalorien'**
  String get recordingKcal;

  /// No description provided for @recordingSaveTitle.
  ///
  /// In de, this message translates to:
  /// **'Aufzeichnung speichern'**
  String get recordingSaveTitle;

  /// No description provided for @recordingSaveHint.
  ///
  /// In de, this message translates to:
  /// **'Name der Fahrt'**
  String get recordingSaveHint;

  /// No description provided for @recordingSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get recordingSave;

  /// No description provided for @recordingDefaultName.
  ///
  /// In de, this message translates to:
  /// **'Fahrt {date} {time}'**
  String recordingDefaultName(String date, String time);

  /// No description provided for @recordingSummaryTitle.
  ///
  /// In de, this message translates to:
  /// **'Aufzeichnung abgeschlossen'**
  String get recordingSummaryTitle;

  /// No description provided for @recordingCloseSummary.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get recordingCloseSummary;

  /// No description provided for @recordingExportGpx.
  ///
  /// In de, this message translates to:
  /// **'Als GPX teilen'**
  String get recordingExportGpx;

  /// No description provided for @recordingActive.
  ///
  /// In de, this message translates to:
  /// **'Aufzeichnung läuft'**
  String get recordingActive;

  /// No description provided for @recordedRidesTitle.
  ///
  /// In de, this message translates to:
  /// **'Aufgezeichnete Fahrten'**
  String get recordedRidesTitle;

  /// No description provided for @recordedRidesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Fahrten aufgezeichnet'**
  String get recordedRidesEmpty;

  /// No description provided for @recordedRideDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get recordedRideDelete;

  /// No description provided for @liveTrackingStart.
  ///
  /// In de, this message translates to:
  /// **'Live-Position teilen'**
  String get liveTrackingStart;

  /// No description provided for @liveTrackingActive.
  ///
  /// In de, this message translates to:
  /// **'Live-Position aktiv (tippen zum Beenden)'**
  String get liveTrackingActive;

  /// No description provided for @liveTrackingTitle.
  ///
  /// In de, this message translates to:
  /// **'Live-Tracking'**
  String get liveTrackingTitle;

  /// No description provided for @liveTrackingExplain.
  ///
  /// In de, this message translates to:
  /// **'Dieser Link zeigt deine aktuelle Position auf einer Karte und läuft nach 12 Stunden automatisch ab.'**
  String get liveTrackingExplain;

  /// No description provided for @liveTrackingShare.
  ///
  /// In de, this message translates to:
  /// **'Link teilen'**
  String get liveTrackingShare;

  /// No description provided for @liveTrackingCopy.
  ///
  /// In de, this message translates to:
  /// **'Link kopieren'**
  String get liveTrackingCopy;

  /// No description provided for @liveTrackingShareBody.
  ///
  /// In de, this message translates to:
  /// **'Verfolge meine Fahrt live:'**
  String get liveTrackingShareBody;

  /// No description provided for @liveTrackingError.
  ///
  /// In de, this message translates to:
  /// **'Live-Tracking konnte nicht gestartet werden'**
  String get liveTrackingError;

  /// No description provided for @profileSpeedEdit.
  ///
  /// In de, this message translates to:
  /// **'Geschwindigkeit anpassen'**
  String get profileSpeedEdit;

  /// No description provided for @profileSpeedDefault.
  ///
  /// In de, this message translates to:
  /// **'Standard: {kmh} km/h'**
  String profileSpeedDefault(int kmh);

  /// No description provided for @profileSpeedReset.
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get profileSpeedReset;

  /// No description provided for @routingFlagsTitle.
  ///
  /// In de, this message translates to:
  /// **'Routen-Optionen'**
  String get routingFlagsTitle;

  /// No description provided for @routingFlagsShowMore.
  ///
  /// In de, this message translates to:
  /// **'{n} weitere Optionen'**
  String routingFlagsShowMore(int n);

  /// No description provided for @routingFlagsHideMore.
  ///
  /// In de, this message translates to:
  /// **'Weniger anzeigen'**
  String get routingFlagsHideMore;

  /// No description provided for @routingFlagLowElevation.
  ///
  /// In de, this message translates to:
  /// **'Wenig Höhenmeter'**
  String get routingFlagLowElevation;

  /// No description provided for @routingFlagAvoidSteps.
  ///
  /// In de, this message translates to:
  /// **'Treppen meiden'**
  String get routingFlagAvoidSteps;

  /// No description provided for @routingFlagAvoidFerries.
  ///
  /// In de, this message translates to:
  /// **'Fähren meiden'**
  String get routingFlagAvoidFerries;

  /// No description provided for @routingFlagAvoidMainRoads.
  ///
  /// In de, this message translates to:
  /// **'Bundesstraßen meiden'**
  String get routingFlagAvoidMainRoads;

  /// No description provided for @routingFlagPreferCycleRoutes.
  ///
  /// In de, this message translates to:
  /// **'Radwege bevorzugen'**
  String get routingFlagPreferCycleRoutes;

  /// No description provided for @routingFlagPreferQuiet.
  ///
  /// In de, this message translates to:
  /// **'Ruhige Strecke'**
  String get routingFlagPreferQuiet;

  /// No description provided for @routingFlagPreferForest.
  ///
  /// In de, this message translates to:
  /// **'Wald & Park bevorzugen'**
  String get routingFlagPreferForest;

  /// No description provided for @routingFlagPreferRiver.
  ///
  /// In de, this message translates to:
  /// **'Am Fluss entlang'**
  String get routingFlagPreferRiver;

  /// No description provided for @routingFlagAvoidTowns.
  ///
  /// In de, this message translates to:
  /// **'Städte umfahren'**
  String get routingFlagAvoidTowns;

  /// No description provided for @routingFlagConsiderTraffic.
  ///
  /// In de, this message translates to:
  /// **'Verkehr beachten'**
  String get routingFlagConsiderTraffic;

  /// No description provided for @routingFlagAvoidPath.
  ///
  /// In de, this message translates to:
  /// **'Schmale Pfade meiden'**
  String get routingFlagAvoidPath;

  /// No description provided for @routingFlagAvoidSteep.
  ///
  /// In de, this message translates to:
  /// **'Steile Anstiege meiden'**
  String get routingFlagAvoidSteep;

  /// No description provided for @routingFlagAvoidMotorways.
  ///
  /// In de, this message translates to:
  /// **'Autobahn meiden'**
  String get routingFlagAvoidMotorways;

  /// No description provided for @routingFlagAvoidToll.
  ///
  /// In de, this message translates to:
  /// **'Maut meiden'**
  String get routingFlagAvoidToll;

  /// No description provided for @routingFlagAvoidUnpaved.
  ///
  /// In de, this message translates to:
  /// **'Unbefestigt meiden'**
  String get routingFlagAvoidUnpaved;

  /// No description provided for @routingFlagShortest.
  ///
  /// In de, this message translates to:
  /// **'Kürzeste Route'**
  String get routingFlagShortest;

  /// No description provided for @routingFlagAvoidNaturalPaths.
  ///
  /// In de, this message translates to:
  /// **'Naturwege meiden'**
  String get routingFlagAvoidNaturalPaths;

  /// No description provided for @routingFlagAvoidFarmTracks.
  ///
  /// In de, this message translates to:
  /// **'Wirtschaftswege meiden'**
  String get routingFlagAvoidFarmTracks;

  /// No description provided for @navigateDarkRide.
  ///
  /// In de, this message translates to:
  /// **'Dunkelfahrt: {dur}'**
  String navigateDarkRide(String dur);

  /// No description provided for @navigateUntilSunset.
  ///
  /// In de, this message translates to:
  /// **'Sonnenuntergang in {dur}'**
  String navigateUntilSunset(String dur);

  /// No description provided for @routeOverlayMyRoutes.
  ///
  /// In de, this message translates to:
  /// **'Eigene Touren'**
  String get routeOverlayMyRoutes;

  /// No description provided for @routePoiOnlyOpenNow.
  ///
  /// In de, this message translates to:
  /// **'Nur jetzt offen'**
  String get routePoiOnlyOpenNow;

  /// No description provided for @routePoiOpen.
  ///
  /// In de, this message translates to:
  /// **'OFFEN'**
  String get routePoiOpen;

  /// No description provided for @routePoiClosed.
  ///
  /// In de, this message translates to:
  /// **'ZU'**
  String get routePoiClosed;

  /// No description provided for @settingsBatteryBudget.
  ///
  /// In de, this message translates to:
  /// **'Akku-Budget'**
  String get settingsBatteryBudget;

  /// No description provided for @settingsBatteryBudgetSub.
  ///
  /// In de, this message translates to:
  /// **'Powerbank-Größe für deine Tour berechnen'**
  String get settingsBatteryBudgetSub;

  /// No description provided for @batteryBudgetTitle.
  ///
  /// In de, this message translates to:
  /// **'Akku-Budget'**
  String get batteryBudgetTitle;

  /// No description provided for @batteryBudgetDuration.
  ///
  /// In de, this message translates to:
  /// **'Tour-Dauer: {h}h'**
  String batteryBudgetDuration(int h);

  /// No description provided for @batteryBudgetDisplayPct.
  ///
  /// In de, this message translates to:
  /// **'Display an: {pct}% der Zeit'**
  String batteryBudgetDisplayPct(int pct);

  /// No description provided for @batteryBudgetNight.
  ///
  /// In de, this message translates to:
  /// **'Nachtfahrt'**
  String get batteryBudgetNight;

  /// No description provided for @batteryBudgetNightSub.
  ///
  /// In de, this message translates to:
  /// **'Display heller, höherer Verbrauch'**
  String get batteryBudgetNightSub;

  /// No description provided for @batteryBudgetNeeded.
  ///
  /// In de, this message translates to:
  /// **'Phone-Bedarf'**
  String get batteryBudgetNeeded;

  /// No description provided for @batteryBudgetPowerbank.
  ///
  /// In de, this message translates to:
  /// **'Powerbank-Empfehlung'**
  String get batteryBudgetPowerbank;

  /// No description provided for @batteryBudgetDisclaimer.
  ///
  /// In de, this message translates to:
  /// **'Grobe Schätzung — echter Verbrauch variiert je nach Phone, Helligkeit und Hintergrundprozessen.'**
  String get batteryBudgetDisclaimer;

  /// No description provided for @shareToWatch.
  ///
  /// In de, this message translates to:
  /// **'An Watch senden'**
  String get shareToWatch;

  /// No description provided for @shareToWatchSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Route auf die Apple Watch laden'**
  String get shareToWatchSubtitle;

  /// No description provided for @shareToWatchQueued.
  ///
  /// In de, this message translates to:
  /// **'Route an Watch geschickt'**
  String get shareToWatchQueued;

  /// No description provided for @shareToWatchFailed.
  ///
  /// In de, this message translates to:
  /// **'Watch nicht erreichbar'**
  String get shareToWatchFailed;

  /// No description provided for @settingsEbikeCapacity.
  ///
  /// In de, this message translates to:
  /// **'E-Bike-Akku'**
  String get settingsEbikeCapacity;

  /// No description provided for @settingsEbikeCapacityEdit.
  ///
  /// In de, this message translates to:
  /// **'Akkukapazität'**
  String get settingsEbikeCapacityEdit;

  /// No description provided for @settingsEvTitle.
  ///
  /// In de, this message translates to:
  /// **'Elektroauto'**
  String get settingsEvTitle;

  /// No description provided for @settingsEvOff.
  ///
  /// In de, this message translates to:
  /// **'Aus'**
  String get settingsEvOff;

  /// No description provided for @settingsEvSummary.
  ///
  /// In de, this message translates to:
  /// **'{kwh} kWh · {cons} kWh/100 km'**
  String settingsEvSummary(String kwh, String cons);

  /// No description provided for @settingsEvEnabled.
  ///
  /// In de, this message translates to:
  /// **'EV-Modus (Auto-Profil)'**
  String get settingsEvEnabled;

  /// No description provided for @settingsEvEnabledSub.
  ///
  /// In de, this message translates to:
  /// **'Reichweiten-Badge + Ladestopp-Planer fürs Auto'**
  String get settingsEvEnabledSub;

  /// No description provided for @settingsEvBattery.
  ///
  /// In de, this message translates to:
  /// **'Akku'**
  String get settingsEvBattery;

  /// No description provided for @settingsEvConsumption.
  ///
  /// In de, this message translates to:
  /// **'Verbrauch'**
  String get settingsEvConsumption;

  /// No description provided for @settingsEvStartCharge.
  ///
  /// In de, this message translates to:
  /// **'Start-Ladung'**
  String get settingsEvStartCharge;

  /// No description provided for @evChargeTime.
  ///
  /// In de, this message translates to:
  /// **'~{min} min laden'**
  String evChargeTime(int min);

  /// No description provided for @ebikeRangeComfortable.
  ///
  /// In de, this message translates to:
  /// **'reicht locker'**
  String get ebikeRangeComfortable;

  /// No description provided for @ebikeRangeTight.
  ///
  /// In de, this message translates to:
  /// **'wird knapp'**
  String get ebikeRangeTight;

  /// No description provided for @ebikeRangeBarely.
  ///
  /// In de, this message translates to:
  /// **'sehr knapp'**
  String get ebikeRangeBarely;

  /// No description provided for @ebikeRangeOver.
  ///
  /// In de, this message translates to:
  /// **'Akku reicht nicht'**
  String get ebikeRangeOver;

  /// No description provided for @ebikePlanChargingStop.
  ///
  /// In de, this message translates to:
  /// **'Ladestopp planen'**
  String get ebikePlanChargingStop;

  /// No description provided for @ebikePlanChargingSearching.
  ///
  /// In de, this message translates to:
  /// **'Suche Ladestation…'**
  String get ebikePlanChargingSearching;

  /// No description provided for @ebikePlanChargingNoneFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Ladestation in Reichweite gefunden'**
  String get ebikePlanChargingNoneFound;

  /// No description provided for @ebikePlanChargingTitle.
  ///
  /// In de, this message translates to:
  /// **'Ladestopp vorgeschlagen'**
  String get ebikePlanChargingTitle;

  /// No description provided for @ebikePlanChargingDetails.
  ///
  /// In de, this message translates to:
  /// **'{km} km auf der Route, {m} m Umweg'**
  String ebikePlanChargingDetails(String km, int m);

  /// No description provided for @ebikePlanChargingInsert.
  ///
  /// In de, this message translates to:
  /// **'Einfügen'**
  String get ebikePlanChargingInsert;

  /// No description provided for @newPill.
  ///
  /// In de, this message translates to:
  /// **'NEU'**
  String get newPill;

  /// No description provided for @activityPickerTitle.
  ///
  /// In de, this message translates to:
  /// **'Was machst du heute?'**
  String get activityPickerTitle;

  /// No description provided for @activityPickerAdvanced.
  ///
  /// In de, this message translates to:
  /// **'Erweitert (alle Profile)'**
  String get activityPickerAdvanced;

  /// No description provided for @activityPickerAllProfiles.
  ///
  /// In de, this message translates to:
  /// **'Alle Profile'**
  String get activityPickerAllProfiles;

  /// No description provided for @activityEv.
  ///
  /// In de, this message translates to:
  /// **'E-Auto'**
  String get activityEv;

  /// No description provided for @activityTour.
  ///
  /// In de, this message translates to:
  /// **'Tour'**
  String get activityTour;

  /// No description provided for @activityCommute.
  ///
  /// In de, this message translates to:
  /// **'Pendeln'**
  String get activityCommute;

  /// No description provided for @activityRoad.
  ///
  /// In de, this message translates to:
  /// **'Rennrad'**
  String get activityRoad;

  /// No description provided for @activityGravel.
  ///
  /// In de, this message translates to:
  /// **'Gravel'**
  String get activityGravel;

  /// No description provided for @activityMtb.
  ///
  /// In de, this message translates to:
  /// **'MTB'**
  String get activityMtb;

  /// No description provided for @activityEbike.
  ///
  /// In de, this message translates to:
  /// **'E-Bike'**
  String get activityEbike;

  /// No description provided for @activityBikepacking.
  ///
  /// In de, this message translates to:
  /// **'Bikepacking'**
  String get activityBikepacking;

  /// No description provided for @activityHiking.
  ///
  /// In de, this message translates to:
  /// **'Wandern'**
  String get activityHiking;

  /// No description provided for @activityRunning.
  ///
  /// In de, this message translates to:
  /// **'Laufen'**
  String get activityRunning;

  /// No description provided for @activityUltra.
  ///
  /// In de, this message translates to:
  /// **'Ultra'**
  String get activityUltra;

  /// No description provided for @activityCar.
  ///
  /// In de, this message translates to:
  /// **'Auto'**
  String get activityCar;

  /// No description provided for @activityCarTrailer.
  ///
  /// In de, this message translates to:
  /// **'Auto + Anhänger'**
  String get activityCarTrailer;

  /// No description provided for @activitySafety.
  ///
  /// In de, this message translates to:
  /// **'Sicher'**
  String get activitySafety;

  /// No description provided for @statsBarTapToExpand.
  ///
  /// In de, this message translates to:
  /// **'Tippen für Details'**
  String get statsBarTapToExpand;

  /// No description provided for @ebikeWorstLeg.
  ///
  /// In de, this message translates to:
  /// **'Längste Etappe'**
  String get ebikeWorstLeg;

  /// No description provided for @ebikePlanChargingOneStop.
  ///
  /// In de, this message translates to:
  /// **'1 Ladestopp vorgeschlagen'**
  String get ebikePlanChargingOneStop;

  /// No description provided for @ebikePlanChargingManyStops.
  ///
  /// In de, this message translates to:
  /// **'{n} Ladestopps vorgeschlagen'**
  String ebikePlanChargingManyStops(int n);

  /// No description provided for @ebikePlanChargingIncomplete.
  ///
  /// In de, this message translates to:
  /// **'Achtung: Auf einer Etappe gibt es keine erreichbare Ladestation — der Akku reicht trotzdem nicht überall.'**
  String get ebikePlanChargingIncomplete;
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
      'that was used.');
}
