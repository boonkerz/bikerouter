// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Wegwiesel';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonShare => 'Teilen';

  @override
  String get commonLoading => 'Lädt…';

  @override
  String get commonError => 'Fehler';

  @override
  String get commonYes => 'Ja';

  @override
  String get commonNo => 'Nein';

  @override
  String get commonKm => 'km';

  @override
  String get commonM => 'm';

  @override
  String get commonMin => 'min';

  @override
  String get commonH => 'h';

  @override
  String get commonSearch => 'Suchen';

  @override
  String get settingsTitle => 'Einstellungen & Info';

  @override
  String get settingsSectionLegal => 'Rechtliches';

  @override
  String get settingsSectionFeedback => 'Feedback';

  @override
  String get settingsSectionPersonal => 'Persönlich';

  @override
  String get settingsSectionEnergy => 'Energie & Akku';

  @override
  String get settingsSectionAbout => 'Über';

  @override
  String get settingsBodyWeight => 'Körpergewicht';

  @override
  String get settingsBodyWeightEdit => 'Körpergewicht setzen';

  @override
  String get settingsImpressum => 'Impressum';

  @override
  String get settingsPrivacy => 'Datenschutz';

  @override
  String get settingsFeedbackForm => 'Feedback & Feature-Wünsche';

  @override
  String get settingsFeedbackFormSub => 'Vorschläge posten und upvoten';

  @override
  String get settingsContactMail => 'Kontakt per E-Mail';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicenses => 'Open-Source-Lizenzen';

  @override
  String get settingsLegalese =>
      '© 2026 Thomas Peterson\nPrivates, nicht-kommerzielles Projekt';

  @override
  String get settingsAbout =>
      'Wegwiesel ist ein privates, nicht-kommerzielles Projekt, um bikerouter.de besser auf mobilen Plattformen nutzbar zu machen. Routing basiert auf BRouter, Karten auf OpenStreetMap.';

  @override
  String get menuSaveRoute => 'Route speichern';

  @override
  String get menuSavedRoutes => 'Gespeicherte Routen';

  @override
  String get menuSettings => 'Einstellungen';

  @override
  String get savedRoutesTitle => 'Gespeicherte Routen';

  @override
  String get savedRoutesEmpty => 'Noch keine Routen gespeichert.';

  @override
  String get savedRoutesLoad => 'Laden';

  @override
  String get savedRoutesDelete => 'Löschen';

  @override
  String get savedRoutesDeleteConfirm => 'Diese Route wirklich löschen?';

  @override
  String get savedRouteSavePrompt => 'Name der Route';

  @override
  String get savedRouteSaveDialogTitle => 'Route speichern';

  @override
  String get savedRouteSaved => 'Route gespeichert';

  @override
  String get savedRouteDeleted => 'Route gelöscht';

  @override
  String savedRouteDefaultName(int day, int month) {
    return 'Route $day.$month.';
  }

  @override
  String get actionSights => 'POIs';

  @override
  String get actionFilter => 'Filter';

  @override
  String get actionWeather => 'Wetter';

  @override
  String get actionAccommodation => 'Unterkunft';

  @override
  String get actionStages => 'Etappen';

  @override
  String get actionShare => 'Teilen';

  @override
  String get actionGpx => 'GPX';

  @override
  String get actionInfo => 'Info';

  @override
  String get statsDistance => 'Distanz';

  @override
  String get statsAscent => 'Aufstieg';

  @override
  String get statsDescent => 'Abstieg';

  @override
  String get statsTime => 'Zeit';

  @override
  String get statsSpeed => 'Ø km/h';

  @override
  String get routeLoading => 'Route wird berechnet…';

  @override
  String get routeError => 'Route konnte nicht berechnet werden';

  @override
  String get routeNoPoints => 'Bitte Start- und Zielpunkt setzen';

  @override
  String get routeClear => 'Route löschen';

  @override
  String get routeClearConfirm => 'Route und alle Wegpunkte entfernen?';

  @override
  String get gpsPermissionDenied => 'Standortzugriff verweigert';

  @override
  String get gpsUnavailable => 'Standort nicht verfügbar';

  @override
  String get searchHint => 'Adresse oder Ort suchen…';

  @override
  String get searchNoResults => 'Keine Ergebnisse';

  @override
  String get searchPrompt => 'Tippe eine Adresse ein';

  @override
  String get profileTitle => 'Radtyp';

  @override
  String get profileCategoryRoad => 'Rennrad';

  @override
  String get profileCategoryGravel => 'Gravel';

  @override
  String get profileCategoryTrekking => 'Trekking';

  @override
  String get profileCategoryMtb => 'MTB';

  @override
  String get profileCategoryCar => 'Auto';

  @override
  String get profileCategoryEbike => 'E-Bike';

  @override
  String get profileCategoryOther => 'Sonstige';

  @override
  String get profileFastbike => 'Rennrad';

  @override
  String get profileFastbikeLowTraffic => 'Rennrad (weniger Verkehr)';

  @override
  String get profileFastbikeVeryLowTraffic => 'Rennrad (sehr wenig Verkehr)';

  @override
  String get profileRandonneur => 'Randonneur';

  @override
  String get profileGravelM11n => 'Gravel „m11n“ (mehr offroad)';

  @override
  String get profileGravelQuaelnix => 'Gravel „quaelnix“ (wenig Verkehr)';

  @override
  String get profileGravelCxb => 'Gravel „CXB“ (mehr offroad)';

  @override
  String get profileTrekking => 'Trekkingrad';

  @override
  String get profileSafety => 'Sicherste Route';

  @override
  String get profileMtbZossebart => 'MTB „Zossebart“';

  @override
  String get profileMtbZossebartHard => 'MTB „Zossebart“ (hart)';

  @override
  String get profileHiking => 'Wandern';

  @override
  String get profileRunning => 'Laufen';

  @override
  String get profileShortest => 'Kürzeste Route';

  @override
  String get profileCar => 'Auto';

  @override
  String get profileCarTrailer => 'Auto mit Anhänger';

  @override
  String get profileEbike => 'E-Bike';

  @override
  String get profileEbikeMtb => 'E-MTB';

  @override
  String get roundtripTitle => 'Rundtour';

  @override
  String get roundtripDistance => 'Distanz';

  @override
  String get roundtripTime => 'Zeit';

  @override
  String get roundtripDirection => 'Richtung';

  @override
  String get roundtripGenerate => 'Rundtour berechnen';

  @override
  String get roundtripAlternative => 'Andere Variante';

  @override
  String get roundtripWindOptimized => 'Wind-optimiert';

  @override
  String get roundtripWindCalm => 'Kaum Wind – normale Rundtour erzeugt';

  @override
  String roundtripWindHint(String dir, int kmh) {
    return 'Gegenwind raus, Rückenwind heim · Wind aus $dir, $kmh km/h';
  }

  @override
  String get roundtripNeedStart => 'Startpunkt auf Karte tippen';

  @override
  String roundtripApproxAt(int km, int speed) {
    return '~$km km bei ~$speed km/h';
  }

  @override
  String roundtripTimeMinutes(int min) {
    return 'Zeit: $min min';
  }

  @override
  String roundtripTimeHours(int h) {
    return 'Zeit: ${h}h';
  }

  @override
  String roundtripTimeHoursMinutes(int h, int min) {
    return 'Zeit: ${h}h ${min}min';
  }

  @override
  String roundtripDirectionLabel(int deg) {
    return 'Richtung: $deg°';
  }

  @override
  String roundtripDistanceLabel(int km) {
    return 'Distanz: $km km';
  }

  @override
  String get roundtripCompassN => 'N';

  @override
  String get roundtripCompassE => 'O';

  @override
  String get roundtripCompassS => 'S';

  @override
  String get roundtripCompassW => 'W';

  @override
  String get weatherTitle => 'Wetter entlang der Route';

  @override
  String get weatherDay => 'Tag';

  @override
  String get weatherLoading => 'Wetter wird geladen…';

  @override
  String get weatherError => 'Wetter-Abruf fehlgeschlagen';

  @override
  String get weatherEmpty => 'Keine Wetterdaten';

  @override
  String weatherToday(String hm) {
    return 'Heute $hm';
  }

  @override
  String weatherTomorrow(String hm) {
    return 'Morgen $hm';
  }

  @override
  String get weatherTemperature => 'Temperatur';

  @override
  String get weatherWind => 'Wind';

  @override
  String get weatherPrecipitation => 'Niederschlag';

  @override
  String get stagesTitle => 'Etappenplaner';

  @override
  String get stagesPerDay => 'km/Tag';

  @override
  String stagesTotalKm(String km) {
    return '$km km gesamt';
  }

  @override
  String get stagesTargetLabel => 'Tagesziel';

  @override
  String get stagesByKm => 'km/Tag';

  @override
  String get stagesByDays => 'Tage';

  @override
  String stagesDaysValue(int days) {
    return '$days Tage';
  }

  @override
  String stagesPlanSummary(int count, int km) {
    return '$count Etappen · Ø $km km';
  }

  @override
  String get stagesDaylightOver => 'länger als Tageslicht';

  @override
  String get stagesDaylightTight => 'knapp vor Sonnenuntergang';

  @override
  String get stagesBatteryOver => 'Akku reicht nicht';

  @override
  String stagesDays(int count) {
    return '$count Tage';
  }

  @override
  String get stagesCreating => 'Etappen werden berechnet…';

  @override
  String get stagesEmpty => 'Keine Etappen';

  @override
  String get stagesError => 'Etappen konnten nicht berechnet werden';

  @override
  String get stagesShowOnMap => 'Etappen auf Karte zeigen';

  @override
  String stagesDefault(int n) {
    return 'Etappe $n';
  }

  @override
  String stagesRowSummary(String km, int ascent, String end) {
    return '$km km · $ascent hm · bis $end km';
  }

  @override
  String get accommodationTitle => 'Unterkünfte';

  @override
  String get accommodationLoading => 'Unterkünfte werden gesucht…';

  @override
  String get accommodationNoResults => 'Keine Unterkünfte gefunden';

  @override
  String get accommodationOpenInMaps => 'In Karten öffnen';

  @override
  String get accommodationRadius => 'Umkreis';

  @override
  String get accommodationHotel => 'Hotel';

  @override
  String get accommodationMotel => 'Motel';

  @override
  String get accommodationHostel => 'Hostel';

  @override
  String get accommodationGuesthouse => 'Pension';

  @override
  String get accommodationBnb => 'B&B';

  @override
  String get accommodationApartment => 'Ferienwohnung';

  @override
  String get accommodationChalet => 'Chalet';

  @override
  String get accommodationAlpineHut => 'Berghütte';

  @override
  String get accommodationWildernessHut => 'Schutzhütte';

  @override
  String get accommodationCampsite => 'Campingplatz';

  @override
  String get accommodationCaravanSite => 'Wohnmobilplatz';

  @override
  String get sightsTitle => 'Sehenswürdigkeiten';

  @override
  String get sightsLoading => 'Sehenswürdigkeiten werden geladen…';

  @override
  String get sightsNoResults => 'Nichts gefunden';

  @override
  String get sightsCategoryAttraction => 'Sehenswürdigkeit';

  @override
  String get sightsCategoryViewpoint => 'Aussichtspunkt';

  @override
  String get sightsCategoryMonument => 'Denkmal';

  @override
  String get sightsCategoryMemorial => 'Mahnmal';

  @override
  String get sightsCategoryCastle => 'Burg/Schloss';

  @override
  String get sightsCategoryRuins => 'Ruine';

  @override
  String get sightsCategoryChurch => 'Kirche';

  @override
  String get sightsCategoryMuseum => 'Museum';

  @override
  String get sightsCategoryArtwork => 'Kunstwerk';

  @override
  String get sightsCategoryWaterfall => 'Wasserfall';

  @override
  String get sightsCategoryPeak => 'Gipfel';

  @override
  String get sightsCategoryCave => 'Höhle';

  @override
  String get sightsCategoryWater => 'Gewässer';

  @override
  String get sightsCategorySpring => 'Quelle';

  @override
  String get sightsCategoryInformation => 'Info-Tafel';

  @override
  String get sightsCategoryDrinkingWater => 'Trinkwasser';

  @override
  String get sightsCategoryBench => 'Rastplatz';

  @override
  String get sightsCategoryShelter => 'Unterstand';

  @override
  String get sightsCategoryCampsite => 'Zeltplatz';

  @override
  String get sightsCategoryPicnic => 'Picknickplatz';

  @override
  String get sightsCategoryBakery => 'Bäckerei';

  @override
  String get sightsCategoryCafe => 'Café';

  @override
  String get sightsCategoryRestaurant => 'Restaurant';

  @override
  String get sightsCategorySupermarket => 'Supermarkt';

  @override
  String get sightsCategoryBicycleRepair => 'Radwerkstatt';

  @override
  String get sightsCategoryBicycleShop => 'Fahrradladen';

  @override
  String get surfaceTitle => 'Beschaffenheit';

  @override
  String get surfaceCategoryAsphalt => 'Asphalt';

  @override
  String get surfaceCategoryPavingStones => 'Pflaster';

  @override
  String get surfaceCategoryGravel => 'Schotter';

  @override
  String get surfaceCategoryUnpaved => 'Naturweg';

  @override
  String get surfaceCategoryOffroad => 'Waldweg';

  @override
  String get surfaceCategoryUnknown => 'Unbekannt';

  @override
  String get surfaceAsphalt => 'Asphalt';

  @override
  String get surfacePaved => 'Befestigt';

  @override
  String get surfaceConcrete => 'Beton';

  @override
  String get surfacePavingStones => 'Pflastersteine';

  @override
  String get surfaceCobblestone => 'Kopfsteinpflaster';

  @override
  String get surfaceCompacted => 'Wassergebunden';

  @override
  String get surfaceGravel => 'Schotter';

  @override
  String get surfaceFineGravel => 'Feinschotter';

  @override
  String get surfaceUnpaved => 'Unbefestigt';

  @override
  String get surfaceGround => 'Erdweg';

  @override
  String get surfaceDirt => 'Feldweg';

  @override
  String get surfaceGrass => 'Gras';

  @override
  String get surfaceSand => 'Sand';

  @override
  String get surfaceWood => 'Holz';

  @override
  String get surfaceMetal => 'Metall';

  @override
  String get surfaceUnknown => 'Unbekannt';

  @override
  String get highwayCycleway => 'Radweg';

  @override
  String get highwayPath => 'Pfad';

  @override
  String get highwayTrack => 'Wirtschaftsweg';

  @override
  String get highwayFootway => 'Fußweg';

  @override
  String get highwayPedestrian => 'Fußgängerzone';

  @override
  String get highwayLivingStreet => 'Verkehrsberuhigt';

  @override
  String get highwayResidential => 'Wohnstraße';

  @override
  String get highwayService => 'Erschließung';

  @override
  String get highwayUnclassified => 'Nebenstraße';

  @override
  String get highwayTertiary => 'Nebenstraße';

  @override
  String get highwaySecondary => 'Straße (mittel)';

  @override
  String get highwayPrimary => 'Haupt-/Bundesstraße';

  @override
  String get highwayTrunk => 'Kraftfahrstraße';

  @override
  String get highwayMotorway => 'Autobahn/Schnellstraße';

  @override
  String get highwaySteps => 'Treppen';

  @override
  String get highwayUnknown => 'Unbekannt';

  @override
  String get shareDialogTitle => 'Route teilen';

  @override
  String get shareLinkCopied => 'Link kopiert';

  @override
  String get shareLinkCreating => 'Link wird erstellt…';

  @override
  String get shareLinkError => 'Link konnte nicht erstellt werden';

  @override
  String get gpxExportTitle => 'GPX exportieren';

  @override
  String get gpxExportDone => 'GPX gespeichert';

  @override
  String get gpxExportError => 'GPX-Export fehlgeschlagen';

  @override
  String get infoDialogTitle => 'Route-Info';

  @override
  String infoPoiCount(int count) {
    return '$count POIs';
  }

  @override
  String get elevationToggleShow => 'Profil anzeigen';

  @override
  String get elevationToggleHide => 'Profil ausblenden';

  @override
  String get addWaypoint => 'Wegpunkt hinzufügen';

  @override
  String get removeWaypoint => 'Wegpunkt entfernen';

  @override
  String get setAsStart => 'Als Start setzen';

  @override
  String get setAsEnd => 'Als Ziel setzen';

  @override
  String get modeAtoB => 'A → B';

  @override
  String get modeRoundtrip => 'Runde';

  @override
  String get tapRouteForInfo => 'Tippe auf eine Route, um Info zu sehen';

  @override
  String get routeLinkCopied => 'Link in die Zwischenablage kopiert';

  @override
  String get noRouteHere => 'Keine Route an dieser Stelle gefunden';

  @override
  String get shareSheetTitle => 'Route teilen';

  @override
  String get shareCopyLink => 'Link kopieren';

  @override
  String get shareCopyLinkSubtitle => 'Empfänger öffnet sie im Browser';

  @override
  String get shareToGarmin => 'An Garmin senden';

  @override
  String get shareToGarminSubtitle => 'Code in der Garmin-Edge-App eingeben';

  @override
  String get garminCodeTitle => 'Code für deinen Garmin';

  @override
  String get garminCodeHint =>
      'In der Wegwiesel-Sync-App auf der Edge eingeben. Gültig 7 Tage.';

  @override
  String garminCodeExpiresAt(String date) {
    return 'Gültig bis $date';
  }

  @override
  String get garminCodeCopied => 'Code kopiert';

  @override
  String garminUploadFailed(String error) {
    return 'Senden fehlgeschlagen: $error';
  }

  @override
  String get garminUploading => 'Wird hochgeladen…';

  @override
  String get shareDirectToEdge => 'Direkt an Edge schicken';

  @override
  String get shareDirectToEdgeSubtitle =>
      'Per Bluetooth über Garmin Connect Mobile';

  @override
  String get garminPickDevicesTitle => 'Edge auswählen';

  @override
  String get garminPickDevicesPrompt =>
      'Bisher ist keine Edge mit Wegwiesel verknüpft. Du wirst gleich zu Garmin Connect Mobile geleitet, dort die Edge bestätigen und kommst dann zurück.';

  @override
  String get garminPickDevicesAction => 'Garmin Connect Mobile öffnen';

  @override
  String garminSendingTo(String device) {
    return 'Sende an $device…';
  }

  @override
  String garminSendSuccess(String device) {
    return 'Strecke an $device geschickt';
  }

  @override
  String garminSendFailed(String error) {
    return 'Senden fehlgeschlagen: $error';
  }

  @override
  String get garminNoDevicesAfterPick => 'Keine Edge ausgewählt';

  @override
  String get garminRepickDevices => 'Edge neu auswählen';

  @override
  String get garminRepickDevicesSubtitle =>
      'Garmin Connect Mobile öffnen und Berechtigung erneuern';

  @override
  String garminDeviceOffline(String device) {
    return '$device ist nicht erreichbar';
  }

  @override
  String get menuStartNavigation => 'Navigation starten';

  @override
  String get menuReturnOneWay => 'Nur Hinweg';

  @override
  String get menuReturnSameWay => 'Hin & zurück (gleicher Weg)';

  @override
  String get menuReturnDifferentWay => 'Hin & zurück (anderer Weg)';

  @override
  String get navigateContinue => 'Weiterfahren';

  @override
  String get navigateTurnLeft => 'links abbiegen';

  @override
  String get navigateTurnRight => 'rechts abbiegen';

  @override
  String get navigateKeepLeft => 'links halten';

  @override
  String get navigateKeepRight => 'rechts halten';

  @override
  String get navigateStraight => 'geradeaus';

  @override
  String get navigateUTurn => 'wenden';

  @override
  String get navigateExit => 'Ausfahrt nehmen';

  @override
  String navigateRoundabout(int n) {
    return '$n. Ausfahrt im Kreisverkehr';
  }

  @override
  String get navigateRemaining => 'verbleibend';

  @override
  String get navigateEta => 'Ankunft';

  @override
  String get navigateRerouting => 'Neu berechnen…';

  @override
  String get navigateArrived => 'Angekommen';

  @override
  String get navigateStop => 'Stopp';

  @override
  String get navigateNorthUp => 'Nach Norden';

  @override
  String get navigateHeadingUp => 'In Fahrtrichtung';

  @override
  String get navigateVoiceOn => 'Sprachansage an';

  @override
  String get navigateVoiceOff => 'Sprachansage aus';

  @override
  String voiceInMeters(int n) {
    return 'In $n Metern';
  }

  @override
  String get voiceNow => 'Jetzt';

  @override
  String get voiceRerouting => 'Route wird neu berechnet';

  @override
  String get voiceArrived => 'Sie haben Ihr Ziel erreicht';

  @override
  String get altRoutePrimary => 'Hauptroute';

  @override
  String altRouteVariant(int n) {
    return 'Variante $n';
  }

  @override
  String get altRouteCalculating => 'wird berechnet…';

  @override
  String get altRouteShortest => 'Kürzeste Route';

  @override
  String get altRouteAvoidMotorways => 'Autobahn vermeiden';

  @override
  String get mapStyleTitle => 'Kartenstil';

  @override
  String get mapOverlayRoutes => 'Overlay-Routen';

  @override
  String get mapRouteVizTitle => 'Routen-Färbung';

  @override
  String get mapVizGradient => 'Steigung';

  @override
  String get gpsPermanentlyDenied =>
      'Standort-Berechtigung dauerhaft verweigert. Bitte in den Einstellungen aktivieren.';

  @override
  String gpsFetchFailed(String error) {
    return 'Standort konnte nicht ermittelt werden: $error';
  }

  @override
  String routingFailed(String error) {
    return 'Routing fehlgeschlagen: $error';
  }

  @override
  String roundtripFailed(String error) {
    return 'Rundtour fehlgeschlagen: $error';
  }

  @override
  String roundtripOffTarget(String actualKm) {
    return 'Keine passende Rundtour gefunden (BRouter hat $actualKm km geliefert). Bitte andere Richtung oder kürzere Distanz probieren.';
  }

  @override
  String exportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String overpassError(String error) {
    return 'Overpass-Fehler: $error';
  }

  @override
  String get poiAddTitle => 'POI hinzufügen';

  @override
  String get poiEditTitle => 'POI bearbeiten';

  @override
  String get poiCategoryLabel => 'Kategorie';

  @override
  String get poiNameLabel => 'Name';

  @override
  String get poiNoteLabel => 'Notiz (optional)';

  @override
  String get poiTypesTitle => 'POI-Typen';

  @override
  String get filterSelectAll => 'Alle';

  @override
  String get filterSelectNone => 'Keine';

  @override
  String get sightWikipedia => 'Wikipedia';

  @override
  String get sightWebsite => 'Website';

  @override
  String get sightOsmRelation => 'OSM-Relation';

  @override
  String get sightAsWaypoint => 'Als Waypoint';

  @override
  String get sightFeeYes => 'Eintritt';

  @override
  String get sightFeeNo => 'Kostenlos';

  @override
  String get sightAccessibleYes => 'Barrierefrei';

  @override
  String get sightAccessibleLimited => 'Teilweise barrierefrei';

  @override
  String get sightAccessibleNo => 'Nicht barrierefrei';

  @override
  String sightBuilt(String year) {
    return 'Erbaut $year';
  }

  @override
  String get sightHeritage => 'Denkmalschutz';

  @override
  String sightArtist(String name) {
    return 'Künstler: $name';
  }

  @override
  String get sightsGroupTourism => 'Tourismus';

  @override
  String get sightsGroupHistoric => 'Historisch';

  @override
  String get sightsGroupNatural => 'Natur';

  @override
  String get sightsGroupShop => 'Einkauf';

  @override
  String get sightsGroupAmenity => 'Versorgung';

  @override
  String get sightsGroupRailway => 'Bahn';

  @override
  String get sightSubAttraction => 'Sehenswürdigkeit';

  @override
  String get sightSubViewpoint => 'Aussichtspunkt';

  @override
  String get sightSubMuseum => 'Museum';

  @override
  String get sightSubArtwork => 'Kunstwerk';

  @override
  String get sightSubPicnicSite => 'Picknickplatz';

  @override
  String get sightSubInformation => 'Touristen-Info';

  @override
  String get sightSubHotel => 'Hotel';

  @override
  String get sightSubGuestHouse => 'Pension';

  @override
  String get sightSubHostel => 'Hostel';

  @override
  String get sightSubCampSite => 'Campingplatz';

  @override
  String get sightSubCastle => 'Burg/Schloss';

  @override
  String get sightSubMonument => 'Denkmal';

  @override
  String get sightSubMemorial => 'Gedenkstätte';

  @override
  String get sightSubRuins => 'Ruine';

  @override
  String get sightSubArchaeological => 'Archäologische Stätte';

  @override
  String get sightSubPeak => 'Gipfel';

  @override
  String get sightSubWaterfall => 'Wasserfall';

  @override
  String get sightSubCave => 'Höhle';

  @override
  String get sightSubSupermarket => 'Supermarkt';

  @override
  String get sightSubBakery => 'Bäckerei';

  @override
  String get sightSubConvenience => 'Kiosk/Späti';

  @override
  String get sightSubBicycleShop => 'Fahrradladen';

  @override
  String get sightSubRestaurant => 'Restaurant';

  @override
  String get sightSubCafe => 'Café';

  @override
  String get sightSubFastFood => 'Imbiss';

  @override
  String get sightSubBiergarten => 'Biergarten';

  @override
  String get sightSubPub => 'Kneipe';

  @override
  String get sightSubDrinkingWater => 'Trinkwasser';

  @override
  String get sightSubToilets => 'Toilette';

  @override
  String get sightSubPharmacy => 'Apotheke';

  @override
  String get sightSubAtm => 'Geldautomat';

  @override
  String get sightSubBicycleRepair => 'Fahrrad-Reparaturstation';

  @override
  String get sightSubBicycleRental => 'Fahrradverleih';

  @override
  String get sightSubChargingStation => 'Ladesäule';

  @override
  String get sightSubStation => 'Bahnhof';

  @override
  String get sightSubHalt => 'Haltepunkt';

  @override
  String get sightSubTramStop => 'Straßenbahn-Halt';

  @override
  String get poiCatLodging => 'Unterkunft';

  @override
  String get poiCatFood => 'Verpflegung';

  @override
  String get poiCatWater => 'Trinkwasser';

  @override
  String get poiCatShop => 'Einkauf';

  @override
  String get poiCatFuel => 'Tankstelle';

  @override
  String get poiCatCharging => 'Ladestation';

  @override
  String get poiCatSights => 'Sehenswürdigkeiten';

  @override
  String get poiCatScenic => 'Aussicht';

  @override
  String get poiCatShelter => 'Schutzhütte';

  @override
  String get sacBadgePrefix => 'Schwierigkeit:';

  @override
  String get sacT1 => 'Wandern (T1)';

  @override
  String get sacT2 => 'Bergwandern (T2)';

  @override
  String get sacT3 => 'Anspruchsvolles Bergwandern (T3)';

  @override
  String get sacT4 => 'Alpinwandern (T4)';

  @override
  String get sacT5 => 'Anspruchsvolles Alpinwandern (T5)';

  @override
  String get sacT6 => 'Schwieriges Alpinwandern (T6)';

  @override
  String get preferHikingRoutesLabel => 'Wanderwege bevorzugen';

  @override
  String get hikingPresetTitle => 'Schwierigkeitsstufe';

  @override
  String get hikingPresetComfortable => 'Gemütlich';

  @override
  String get hikingPresetSporty => 'Sportlich';

  @override
  String get hikingPresetMountain => 'Bergtour';

  @override
  String get actionPauseRecommendations => 'Pausen';

  @override
  String get pauseRecsTooShort =>
      'Route ist zu kurz für Pausen-Empfehlungen (mind. 1.5 h).';

  @override
  String get pauseRecsNone =>
      'Keine Pausenplätze in der Nähe der Route gefunden.';

  @override
  String pauseRecsFailed(String error) {
    return 'Pausensuche fehlgeschlagen: $error';
  }

  @override
  String get poiCatPicnic => 'Picknickplatz';

  @override
  String get poiCatStation => 'Bahnhof';

  @override
  String get settingsBikepackingMode => 'Bikepacking-Modus';

  @override
  String get settingsBikepackingModeSub =>
      'Priorisiert Camping, Wasser, Schutzhütten und Bahnhöfe in der POI-Suche';

  @override
  String get stagesStartDateLabel => 'Starttag:';

  @override
  String get stagesOvernightUnnamed => '(Unbenannte Unterkunft)';

  @override
  String rideRecoveredSnack(String km) {
    return 'Unterbrochene Aufzeichnung wiederhergestellt ($km km). Findest du unter „Aufzeichnungen\".';
  }

  @override
  String get wildCampDisclaimerTitle => 'Wildcampen — bitte beachten';

  @override
  String get wildCampDisclaimerBody =>
      'Bikepacking-Modus zeigt auch informelle Zeltplätze (camp_pitch) in der POI-Suche.\n\nIn Deutschland ist Wildcampen außerhalb ausgewiesener Plätze meist verboten — die genauen Regeln hängen vom Bundesland und Forstrecht ab. In Schweden/Norwegen/Finnland gilt das Jedermannsrecht. Informiere dich vor jeder Übernachtung selbst — Wegwiesel übernimmt keine Haftung für die rechtliche Lage am gewählten Ort.';

  @override
  String get shareToWahoo => 'An Wahoo senden';

  @override
  String get shareToWahooSubtitle =>
      'Wahoo Companion App öffnet die Route automatisch';

  @override
  String wahooSendFailed(String error) {
    return 'Senden an Wahoo fehlgeschlagen: $error';
  }

  @override
  String get wahooNotInstalledTitle => 'Wahoo-App nicht gefunden';

  @override
  String get wahooNotInstalledBody =>
      'Installiere die „Wahoo Companion\"- bzw. „Wahoo Fitness\"-App aus dem App Store / Play Store und versuche es erneut.';

  @override
  String get menuFindFtpRoute => 'Trainingsstrecke finden';

  @override
  String get ftpFinderTitle => 'FTP-Test-Strecke finden';

  @override
  String get ftpFinderTest20 => '20-min';

  @override
  String get ftpFinderTest8 => '8-min (2×)';

  @override
  String get ftpFinderTestRamp => 'Stufentest';

  @override
  String get ftpFinderTestSweetSpot => 'Sweet Spot';

  @override
  String get ftpFinderModeFlat => 'Flach';

  @override
  String get ftpFinderModeClimb => 'Bergauf';

  @override
  String get ftpFinderModeEither => 'Beides';

  @override
  String ftpFinderRadius(int km) {
    return 'Umkreis: $km km';
  }

  @override
  String get ftpFinderSearch => 'Strecke suchen';

  @override
  String get ftpFinderPickToSearch =>
      'Test-Typ wählen und „Strecke suchen\" tippen.';

  @override
  String get ftpFinderEmpty =>
      'Keine passende Strecke im Umkreis gefunden. Versuche einen größeren Radius oder einen anderen Test-Typ.';

  @override
  String get ftpFinderUnnamed => 'Unbenannte Strecke';

  @override
  String ftpFinderPicked(String km) {
    return 'Strecke ausgewählt ($km km). Schon mal aufwärmen?';
  }

  @override
  String get ftpFinderStartRecord => 'Aufzeichnung starten';

  @override
  String get ftpFinderOriginWaypoint => 'Suche um den gesetzten Startpunkt.';

  @override
  String get ftpFinderOriginGps => 'Suche um deine aktuelle GPS-Position.';

  @override
  String get ftpFinderOriginMapView =>
      'Suche um den Kartenmittelpunkt. Für ein besseres Ergebnis erst einen Punkt auf der Karte tippen oder GPS einschalten.';

  @override
  String get menuRouteSourcesTooltip => 'Routen-Quellen';

  @override
  String get poiCatCamping => 'Camping';

  @override
  String get poiCatInfo => 'Information';

  @override
  String get poiCatOther => 'Sonstiges';

  @override
  String get routePoiSearchTitle => 'Auf der Route suchen';

  @override
  String get routePoiSearchEmpty => 'Nichts entlang der Route gefunden';

  @override
  String get routePoiSearchPickCategories => 'Kategorien wählen';

  @override
  String routePoiSearchAt(String km) {
    return 'bei $km km';
  }

  @override
  String routePoiSearchSide(int m) {
    return '$m m abseits';
  }

  @override
  String get routePoiSearchAdd => 'Zur Route';

  @override
  String get menuSearchAlongRoute => 'Auf der Route suchen';

  @override
  String get defaultWaypoint => 'Zielpunkt';

  @override
  String get defaultTourName => 'Wegwiesel-Tour';

  @override
  String roundtripTourName(int km) {
    return 'Rundtour ${km}km';
  }

  @override
  String stageTooltip(int index, String km) {
    return 'Etappe $index: $km km';
  }

  @override
  String get osmRouteTypeBicycle => 'Radroute';

  @override
  String get osmRouteTypeHiking => 'Wanderweg';

  @override
  String get osmRouteTypeMtb => 'MTB-Route';

  @override
  String get osmNetworkIcn => 'International';

  @override
  String get osmNetworkNcn => 'National';

  @override
  String get osmNetworkRcn => 'Regional';

  @override
  String get osmNetworkLcn => 'Lokal';

  @override
  String get osmNetworkIwn => 'International (Wandern)';

  @override
  String get osmNetworkNwn => 'National (Wandern)';

  @override
  String get osmNetworkRwn => 'Regional (Wandern)';

  @override
  String get osmNetworkLwn => 'Lokal (Wandern)';

  @override
  String get profileModeGradient => 'Steigung';

  @override
  String get profileModeSurface => 'Oberfläche';

  @override
  String get profileModeHighway => 'Straßentyp';

  @override
  String get profileModeSmoothness => 'Rauheit';

  @override
  String get profileModeMaxSpeed => 'Tempolimit';

  @override
  String get profileModeCost => 'Routingkosten';

  @override
  String get profileZoomLocked => 'Zoom gesperrt';

  @override
  String get profileZoomUnlocked => 'Zoom frei';

  @override
  String get profileZoomReset => 'Zoom zurücksetzen';

  @override
  String get profileSimplifiedWarning =>
      'Vereinfachte Darstellung — hineinzoomen für Details';

  @override
  String get profileTooltipDistance => 'Distanz';

  @override
  String get profileTooltipElevation => 'Höhe';

  @override
  String get profileTooltipGradient => 'Steigung';

  @override
  String get profileTooltipAscent => 'Anstieg';

  @override
  String get profileTooltipHighway => 'Straße';

  @override
  String get profileTooltipSurface => 'Oberfläche';

  @override
  String get profileTooltipSmoothness => 'Rauheit';

  @override
  String get profileTooltipMaxSpeed => 'Tempo';

  @override
  String get profileTooltipCost => 'Kosten';

  @override
  String get smoothnessExcellent => 'Sehr gut';

  @override
  String get smoothnessGood => 'Gut';

  @override
  String get smoothnessIntermediate => 'Mittel';

  @override
  String get smoothnessBad => 'Schlecht';

  @override
  String get smoothnessUnknown => 'Unbekannt';

  @override
  String get mapStyleStandard => 'Standard';

  @override
  String get mapStyleCycling => 'Fahrrad';

  @override
  String get mapStyleTopo => 'Topo';

  @override
  String get mapStyleSatellite => 'Satellit';

  @override
  String get routeOverlayCycling => 'Radrouten';

  @override
  String get routeOverlayHiking => 'Wanderwege';

  @override
  String get routeOverlayMtb => 'MTB-Routen';

  @override
  String get routeOverlayHillshade => 'Höhenschummerung';

  @override
  String get routeOverlayHeatmap => 'Wegwiesel-Heatmap';

  @override
  String get gpxImportTitle => 'GPX-Track importieren';

  @override
  String get gpxImportButton => 'GPX-Datei wählen';

  @override
  String gpxImportFailed(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String gpxImportSuccess(int points, String km) {
    return 'Track geladen: $points Punkte, $km km';
  }

  @override
  String get gpxImportEmpty => 'Keine Trackpunkte in der Datei gefunden';

  @override
  String get gpxModeTitle => 'Wie soll der Track importiert werden?';

  @override
  String gpxModeSummary(int points, String km) {
    return '$points Punkte · $km km';
  }

  @override
  String get gpxModeRerouteTitle => 'Mit deinem Profil nachrouten';

  @override
  String get gpxModeRerouteBody =>
      'Wegwiesel berechnet die Strecke mit dem aktuell gewählten Profil. Du bekommst Belag-Anzeige, Höhenprofil-Farben, Turn-by-Turn-Navigation und Sprachausgabe. Strecke kann leicht abweichen.';

  @override
  String get gpxModeTrackTitle => 'Track 1:1 übernehmen';

  @override
  String get gpxModeTrackBody =>
      'Original-Geometrie unverändert anzeigen. Keine Belag-Info, keine Sprach-Navigation — gut wenn die Tour exakt so gefahren werden soll.';

  @override
  String get urlImportTitle => 'Tour-URL importieren';

  @override
  String get urlImportHint => 'Komoot-Link oder direkter GPX-Link';

  @override
  String get urlImportFetch => 'Laden';

  @override
  String get urlImportCancel => 'Abbrechen';

  @override
  String get urlImportLoading => 'Tour wird geladen…';

  @override
  String get urlImportErrEmpty => 'Bitte URL eingeben';

  @override
  String get urlImportErrInvalid => 'URL ist ungültig';

  @override
  String get urlImportErrNetwork => 'Netzwerkfehler';

  @override
  String get urlImportErrForbidden => 'Tour ist privat oder benötigt Login';

  @override
  String get urlImportErrNotFound => 'Tour nicht gefunden';

  @override
  String get urlImportErrNotGpx => 'Keine GPX-Daten unter der URL';

  @override
  String get urlImportErrStravaLogin =>
      'Strava-Routen können wegen Login-Pflicht nicht direkt importiert werden — bitte GPX manuell exportieren und über „GPX importieren\" öffnen';

  @override
  String get nogoTitle => 'Sperrzonen';

  @override
  String get nogoEmpty => 'Keine Sperrzonen definiert';

  @override
  String get nogoAdd => 'Sperrzone hinzufügen';

  @override
  String get nogoAddHint => 'Tippe auf die Karte, um eine Sperrzone zu setzen';

  @override
  String nogoRadius(int meters) {
    return 'Radius: $meters m';
  }

  @override
  String get nogoDelete => 'Entfernen';

  @override
  String get nogoConfirmCancel => 'Abbrechen';

  @override
  String get nogoConfirmAdd => 'Hinzufügen';

  @override
  String get menuImportGpx => 'GPX importieren';

  @override
  String get menuImportUrl => 'Tour-URL importieren';

  @override
  String get menuNogos => 'Sperrzonen';

  @override
  String get menuRecording => 'Fahrt aufzeichnen';

  @override
  String get menuRecordedRides => 'Aufzeichnungen';

  @override
  String get menuLibrary => 'Routen entdecken';

  @override
  String get menuPublishRoute => 'Route veröffentlichen';

  @override
  String get menuOfflineMaps => 'Offline-Karten';

  @override
  String get offlineMapsTitle => 'Offline-Karten';

  @override
  String get offlineMapsCurrentSection => 'Cache';

  @override
  String get offlineMapsDownloadSection => 'Herunterladen';

  @override
  String get offlineMapsProgressSection => 'Download läuft';

  @override
  String get offlineMapsUsed => 'Belegt';

  @override
  String get offlineMapsLimit => 'Speicher-Limit';

  @override
  String get offlineMapsClearTitle => 'Cache leeren';

  @override
  String get offlineMapsClearSubtitle => 'Alle gecachten Kacheln entfernen';

  @override
  String get offlineMapsClearBody =>
      'Alle gespeicherten Kartenkacheln werden gelöscht. Sie werden bei der nächsten Online-Nutzung neu geladen.';

  @override
  String get offlineMapsDownloadCurrent => 'Aktuellen Ausschnitt herunterladen';

  @override
  String get offlineMapsDownloadCurrentSub =>
      'Karten-Kacheln Zoom 8–15 für den sichtbaren Bereich vorab laden';

  @override
  String get offlineMapsNoViewport =>
      'Bitte zuerst den gewünschten Kartenausschnitt auf der Karte einstellen';

  @override
  String get offlineMapsConfirmTitle => 'Region herunterladen?';

  @override
  String offlineMapsConfirmBody(int mb) {
    return 'Geschätzte Größe: ca. $mb MB. Während des Downloads bitte die App offen lassen.';
  }

  @override
  String get offlineMapsStart => 'Starten';

  @override
  String offlineMapsProgressLine(int done, int total) {
    return '$done von $total Kacheln';
  }

  @override
  String offlineMapsProgressDone(int total) {
    return '$total Kacheln offline verfügbar';
  }

  @override
  String get libraryTitle => 'Routen entdecken';

  @override
  String get libraryEmpty => 'Noch keine öffentlichen Routen in diesem Filter';

  @override
  String get libraryFilterAll => 'Alle';

  @override
  String get libraryFilterNear => 'In meiner Nähe';

  @override
  String get libraryFilterShort => 'kurz (< 30 km)';

  @override
  String get libraryFilterMedium => 'mittel (30–80 km)';

  @override
  String get libraryFilterLong => 'lang (> 80 km)';

  @override
  String get libraryItemBy => 'von Wegwiesel-User';

  @override
  String get librarySearchHint => 'Titel oder Beschreibung suchen…';

  @override
  String get libraryLoadFailed => 'Konnte Bibliothek nicht laden';

  @override
  String get libraryOpenFailed => 'Route konnte nicht geladen werden';

  @override
  String get publishTitle => 'Route veröffentlichen';

  @override
  String get publishExplain =>
      'Deine Route wird mit Titel und Beschreibung öffentlich sichtbar. Keine Account-Bindung, kein Tracking — nur du kannst sie über die Wegwiesel-App auf diesem Gerät wieder zurückziehen.';

  @override
  String get publishNameLabel => 'Titel';

  @override
  String get publishNameHint => 'z.B. Rheinradweg von Mainz nach Koblenz';

  @override
  String get publishDescriptionLabel => 'Beschreibung';

  @override
  String get publishDescriptionHint => 'Was macht diese Route besonders?';

  @override
  String get publishConfirm => 'Veröffentlichen';

  @override
  String get publishSuccess => 'Route ist jetzt öffentlich';

  @override
  String get publishFailed => 'Veröffentlichen fehlgeschlagen';

  @override
  String get publishUnpublish => 'Aus der Bibliothek entfernen';

  @override
  String get publishUnpublished => 'Route entfernt';

  @override
  String get recordingTitle => 'Aufzeichnung';

  @override
  String get recordingStart => 'Start';

  @override
  String get recordingPause => 'Pause';

  @override
  String get recordingResume => 'Weiter';

  @override
  String get recordingStop => 'Stop';

  @override
  String get recordingPermissionDenied => 'Standortfreigabe wird benötigt';

  @override
  String get recordingDistance => 'Distanz';

  @override
  String get recordingDuration => 'Zeit';

  @override
  String get recordingAvgSpeed => '⌀ Tempo';

  @override
  String get recordingMaxSpeed => 'Max Tempo';

  @override
  String get recordingAscent => 'Aufstieg';

  @override
  String get recordingDescent => 'Abstieg';

  @override
  String get recordingKcal => 'Kalorien';

  @override
  String get recordingSaveTitle => 'Aufzeichnung speichern';

  @override
  String get recordingSaveHint => 'Name der Fahrt';

  @override
  String get recordingSave => 'Speichern';

  @override
  String recordingDefaultName(String date, String time) {
    return 'Fahrt $date $time';
  }

  @override
  String get recordingSummaryTitle => 'Aufzeichnung abgeschlossen';

  @override
  String get recordingCloseSummary => 'Schließen';

  @override
  String get recordingExportGpx => 'Als GPX teilen';

  @override
  String get recordingActive => 'Aufzeichnung läuft';

  @override
  String get recordedRidesTitle => 'Aufgezeichnete Fahrten';

  @override
  String get recordedRidesEmpty => 'Noch keine Fahrten aufgezeichnet';

  @override
  String get recordedRideDelete => 'Löschen';

  @override
  String get liveTrackingStart => 'Live-Position teilen';

  @override
  String get liveTrackingActive => 'Live-Position aktiv (tippen zum Beenden)';

  @override
  String get liveTrackingTitle => 'Live-Tracking';

  @override
  String get liveTrackingExplain =>
      'Dieser Link zeigt deine aktuelle Position auf einer Karte und läuft nach 12 Stunden automatisch ab.';

  @override
  String get liveTrackingShare => 'Link teilen';

  @override
  String get liveTrackingCopy => 'Link kopieren';

  @override
  String get liveTrackingShareBody => 'Verfolge meine Fahrt live:';

  @override
  String get liveTrackingError => 'Live-Tracking konnte nicht gestartet werden';

  @override
  String get profileSpeedEdit => 'Geschwindigkeit anpassen';

  @override
  String profileSpeedDefault(int kmh) {
    return 'Standard: $kmh km/h';
  }

  @override
  String get profileSpeedReset => 'Zurücksetzen';

  @override
  String get routingFlagsTitle => 'Routen-Optionen';

  @override
  String routingFlagsShowMore(int n) {
    return '$n weitere Optionen';
  }

  @override
  String get routingFlagsHideMore => 'Weniger anzeigen';

  @override
  String get routingFlagLowElevation => 'Wenig Höhenmeter';

  @override
  String get routingFlagAvoidSteps => 'Treppen meiden';

  @override
  String get routingFlagAvoidFerries => 'Fähren meiden';

  @override
  String get routingFlagAvoidMainRoads => 'Bundesstraßen meiden';

  @override
  String get routingFlagPreferCycleRoutes => 'Radwege bevorzugen';

  @override
  String get routingFlagPreferQuiet => 'Ruhige Strecke';

  @override
  String get routingFlagPreferForest => 'Wald & Park bevorzugen';

  @override
  String get routingFlagPreferRiver => 'Am Fluss entlang';

  @override
  String get routingFlagAvoidTowns => 'Städte umfahren';

  @override
  String get routingFlagConsiderTraffic => 'Verkehr beachten';

  @override
  String get routingFlagAvoidPath => 'Schmale Pfade meiden';

  @override
  String get routingFlagAvoidSteep => 'Steile Anstiege meiden';

  @override
  String get routingFlagAvoidMotorways => 'Autobahn meiden';

  @override
  String get routingFlagAvoidToll => 'Maut meiden';

  @override
  String get routingFlagAvoidUnpaved => 'Unbefestigt meiden';

  @override
  String get routingFlagShortest => 'Kürzeste Route';

  @override
  String get routingFlagAvoidNaturalPaths => 'Naturwege meiden';

  @override
  String get routingFlagAvoidFarmTracks => 'Wirtschaftswege meiden';

  @override
  String navigateDarkRide(String dur) {
    return 'Dunkelfahrt: $dur';
  }

  @override
  String navigateUntilSunset(String dur) {
    return 'Sonnenuntergang in $dur';
  }

  @override
  String get routeOverlayMyRoutes => 'Eigene Touren';

  @override
  String get routePoiOnlyOpenNow => 'Nur jetzt offen';

  @override
  String get routePoiOpen => 'OFFEN';

  @override
  String get routePoiClosed => 'ZU';

  @override
  String get settingsBatteryBudget => 'Akku-Budget';

  @override
  String get settingsBatteryBudgetSub =>
      'Powerbank-Größe für deine Tour berechnen';

  @override
  String get batteryBudgetTitle => 'Akku-Budget';

  @override
  String batteryBudgetDuration(int h) {
    return 'Tour-Dauer: ${h}h';
  }

  @override
  String batteryBudgetDisplayPct(int pct) {
    return 'Display an: $pct% der Zeit';
  }

  @override
  String get batteryBudgetNight => 'Nachtfahrt';

  @override
  String get batteryBudgetNightSub => 'Display heller, höherer Verbrauch';

  @override
  String get batteryBudgetNeeded => 'Phone-Bedarf';

  @override
  String get batteryBudgetPowerbank => 'Powerbank-Empfehlung';

  @override
  String get batteryBudgetDisclaimer =>
      'Grobe Schätzung — echter Verbrauch variiert je nach Phone, Helligkeit und Hintergrundprozessen.';

  @override
  String get shareToWatch => 'An Watch senden';

  @override
  String get shareToWatchSubtitle => 'Route auf die Apple Watch laden';

  @override
  String get shareToWatchQueued => 'Route an Watch geschickt';

  @override
  String get shareToWatchFailed => 'Watch nicht erreichbar';

  @override
  String get settingsEbikeCapacity => 'E-Bike-Akku';

  @override
  String get settingsEbikeCapacityEdit => 'Akkukapazität';

  @override
  String get settingsEvTitle => 'Elektroauto';

  @override
  String get settingsEvOff => 'Aus';

  @override
  String settingsEvSummary(String kwh, String cons) {
    return '$kwh kWh · $cons kWh/100 km';
  }

  @override
  String get settingsEvEnabled => 'EV-Modus (Auto-Profil)';

  @override
  String get settingsEvEnabledSub =>
      'Reichweiten-Badge + Ladestopp-Planer fürs Auto';

  @override
  String get settingsEvBattery => 'Akku';

  @override
  String get settingsEvConsumption => 'Verbrauch';

  @override
  String get settingsEvStartCharge => 'Start-Ladung';

  @override
  String evChargeTime(int min) {
    return '~$min min laden';
  }

  @override
  String evPriceOsm(String price) {
    return 'Preis (OSM): $price';
  }

  @override
  String evPriceAdhoc(String price) {
    return 'Ad-hoc $price €/kWh';
  }

  @override
  String get evChargingAlternatives => 'Alternativen in der Nähe:';

  @override
  String evChargingCostTotal(String cost) {
    return 'Ladekosten gesamt: ~$cost €';
  }

  @override
  String get evStatusAvailable => 'frei';

  @override
  String evStatusAvailableN(int n) {
    return '$n frei';
  }

  @override
  String get evStatusBusy => 'belegt';

  @override
  String get evStatusOffline => 'außer Betrieb';

  @override
  String get evChargingFree => 'kostenlos';

  @override
  String get evChargingPaid => 'kostenpflichtig';

  @override
  String get ebikeRangeComfortable => 'reicht locker';

  @override
  String get ebikeRangeTight => 'wird knapp';

  @override
  String get ebikeRangeBarely => 'sehr knapp';

  @override
  String get ebikeRangeOver => 'Akku reicht nicht';

  @override
  String get ebikePlanChargingStop => 'Ladestopp planen';

  @override
  String get ebikePlanChargingSearching => 'Suche Ladestation…';

  @override
  String get ebikePlanChargingNoneFound =>
      'Keine Ladestation in Reichweite gefunden';

  @override
  String get ebikePlanChargingTitle => 'Ladestopp vorgeschlagen';

  @override
  String ebikePlanChargingDetails(String km, int m) {
    return '$km km auf der Route, $m m Umweg';
  }

  @override
  String get ebikePlanChargingInsert => 'Einfügen';

  @override
  String get newPill => 'NEU';

  @override
  String get activityPickerTitle => 'Was machst du heute?';

  @override
  String get tourProfile =>
      'Wähle hier dein Profil bzw. deine Aktivität (Rad, E-Bike, Wandern, Auto …).';

  @override
  String get tourModes => 'A→B-Route oder Rundtour? Hier umschalten.';

  @override
  String get tourSearch =>
      'Adresse suchen — oder einfach das Ziel auf die Karte tippen. Dein Standort ist der Start.';

  @override
  String get tourSkip => 'ÜBERSPRINGEN';

  @override
  String get mapHintChooseProfile => 'Oben Profil & A→B / Rundtour wählen';

  @override
  String get mapTapHintGps => 'Ziel antippen — dein Standort ist der Start';

  @override
  String get mapTapHintNoGps => 'Start und Ziel auf die Karte tippen';

  @override
  String get activityPickerAdvanced => 'Erweitert (alle Profile)';

  @override
  String get activityPickerAllProfiles => 'Alle Profile';

  @override
  String get activityEv => 'E-Auto';

  @override
  String get activityTour => 'Tour';

  @override
  String get activityCommute => 'Pendeln';

  @override
  String get activityRoad => 'Rennrad';

  @override
  String get activityGravel => 'Gravel';

  @override
  String get activityMtb => 'MTB';

  @override
  String get activityEbike => 'E-Bike';

  @override
  String get activityBikepacking => 'Bikepacking';

  @override
  String get activityHiking => 'Wandern';

  @override
  String get activityRunning => 'Laufen';

  @override
  String get activityUltra => 'Ultra';

  @override
  String get activityCar => 'Auto';

  @override
  String get activityCarTrailer => 'Auto + Anhänger';

  @override
  String get activitySafety => 'Sicher';

  @override
  String get statsBarTapToExpand => 'Tippen für Details';

  @override
  String get ebikeWorstLeg => 'Längste Etappe';

  @override
  String get ebikePlanChargingOneStop => '1 Ladestopp vorgeschlagen';

  @override
  String ebikePlanChargingManyStops(int n) {
    return '$n Ladestopps vorgeschlagen';
  }

  @override
  String get ebikePlanChargingIncomplete =>
      'Achtung: Auf einer Etappe gibt es keine erreichbare Ladestation — der Akku reicht trotzdem nicht überall.';
}
