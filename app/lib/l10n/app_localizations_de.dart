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
  String get settingsSectionAbout => 'Über';

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
  String get profileHiking => 'Wandern (beta)';

  @override
  String get profileShortest => 'Kürzeste Route';

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
  String get poiCatScenic => 'Aussicht';

  @override
  String get poiCatCamping => 'Camping';

  @override
  String get poiCatInfo => 'Information';

  @override
  String get poiCatOther => 'Sonstiges';

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
  String get menuNogos => 'Sperrzonen';
}
