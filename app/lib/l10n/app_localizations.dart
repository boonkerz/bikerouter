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

  /// No description provided for @settingsSectionAbout.
  ///
  /// In de, this message translates to:
  /// **'Über'**
  String get settingsSectionAbout;

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
  /// **'Wandern (beta)'**
  String get profileHiking;

  /// No description provided for @profileShortest.
  ///
  /// In de, this message translates to:
  /// **'Kürzeste Route'**
  String get profileShortest;

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

  /// No description provided for @garminDeviceOffline.
  ///
  /// In de, this message translates to:
  /// **'{device} ist nicht erreichbar'**
  String garminDeviceOffline(String device);

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

  /// No description provided for @poiCatScenic.
  ///
  /// In de, this message translates to:
  /// **'Aussicht'**
  String get poiCatScenic;

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

  /// No description provided for @menuNogos.
  ///
  /// In de, this message translates to:
  /// **'Sperrzonen'**
  String get menuNogos;

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
