// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Wegwiesel';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => 'Close';

  @override
  String get commonShare => 'Share';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonError => 'Error';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonKm => 'km';

  @override
  String get commonM => 'm';

  @override
  String get commonMin => 'min';

  @override
  String get commonH => 'h';

  @override
  String get commonSearch => 'Search';

  @override
  String get settingsTitle => 'Settings & Info';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get settingsSectionFeedback => 'Feedback';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsImpressum => 'Imprint';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsFeedbackForm => 'Feedback & feature requests';

  @override
  String get settingsFeedbackFormSub => 'Post and upvote suggestions';

  @override
  String get settingsContactMail => 'Contact by email';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicenses => 'Open-source licenses';

  @override
  String get settingsLegalese =>
      '© 2026 Thomas Peterson\nPrivate, non-commercial project';

  @override
  String get settingsAbout =>
      'Wegwiesel is a private, non-commercial project to make bikerouter.de more usable on mobile. Routing is based on BRouter, maps on OpenStreetMap.';

  @override
  String get menuSaveRoute => 'Save route';

  @override
  String get menuSavedRoutes => 'Saved routes';

  @override
  String get menuSettings => 'Settings';

  @override
  String get savedRoutesTitle => 'Saved routes';

  @override
  String get savedRoutesEmpty => 'No saved routes yet.';

  @override
  String get savedRoutesLoad => 'Load';

  @override
  String get savedRoutesDelete => 'Delete';

  @override
  String get savedRoutesDeleteConfirm => 'Delete this route?';

  @override
  String get savedRouteSavePrompt => 'Route name';

  @override
  String get savedRouteSaveDialogTitle => 'Save route';

  @override
  String get savedRouteSaved => 'Route saved';

  @override
  String get savedRouteDeleted => 'Route deleted';

  @override
  String savedRouteDefaultName(int day, int month) {
    return 'Route $day/$month';
  }

  @override
  String get actionSights => 'POIs';

  @override
  String get actionFilter => 'Filter';

  @override
  String get actionWeather => 'Weather';

  @override
  String get actionAccommodation => 'Lodging';

  @override
  String get actionStages => 'Stages';

  @override
  String get actionShare => 'Share';

  @override
  String get actionGpx => 'GPX';

  @override
  String get actionInfo => 'Info';

  @override
  String get statsDistance => 'Distance';

  @override
  String get statsAscent => 'Ascent';

  @override
  String get statsDescent => 'Descent';

  @override
  String get statsTime => 'Time';

  @override
  String get statsSpeed => 'avg km/h';

  @override
  String get routeLoading => 'Calculating route…';

  @override
  String get routeError => 'Route could not be calculated';

  @override
  String get routeNoPoints => 'Please set a start and end point';

  @override
  String get routeClear => 'Clear route';

  @override
  String get routeClearConfirm => 'Remove route and all waypoints?';

  @override
  String get gpsPermissionDenied => 'Location access denied';

  @override
  String get gpsUnavailable => 'Location unavailable';

  @override
  String get searchHint => 'Search address or place…';

  @override
  String get searchNoResults => 'No results';

  @override
  String get searchPrompt => 'Enter an address';

  @override
  String get profileTitle => 'Bike type';

  @override
  String get profileCategoryRoad => 'Road';

  @override
  String get profileCategoryGravel => 'Gravel';

  @override
  String get profileCategoryTrekking => 'Trekking';

  @override
  String get profileCategoryMtb => 'MTB';

  @override
  String get profileCategoryOther => 'Other';

  @override
  String get profileFastbike => 'Road bike';

  @override
  String get profileFastbikeLowTraffic => 'Road bike (low traffic)';

  @override
  String get profileFastbikeVeryLowTraffic => 'Road bike (very low traffic)';

  @override
  String get profileRandonneur => 'Randonneur';

  @override
  String get profileGravelM11n => 'Gravel “m11n” (more off-road)';

  @override
  String get profileGravelQuaelnix => 'Gravel “quaelnix” (low traffic)';

  @override
  String get profileGravelCxb => 'Gravel “CXB” (more off-road)';

  @override
  String get profileTrekking => 'Trekking bike';

  @override
  String get profileSafety => 'Safest route';

  @override
  String get profileMtbZossebart => 'MTB “Zossebart”';

  @override
  String get profileMtbZossebartHard => 'MTB “Zossebart” (hard)';

  @override
  String get profileHiking => 'Hiking (beta)';

  @override
  String get profileShortest => 'Shortest route';

  @override
  String get roundtripTitle => 'Round trip';

  @override
  String get roundtripDistance => 'Distance';

  @override
  String get roundtripTime => 'Time';

  @override
  String get roundtripDirection => 'Direction';

  @override
  String get roundtripGenerate => 'Calculate round trip';

  @override
  String get roundtripAlternative => 'Another variant';

  @override
  String get roundtripNeedStart => 'Tap the map to set a start point';

  @override
  String roundtripApproxAt(int km, int speed) {
    return '~$km km at ~$speed km/h';
  }

  @override
  String roundtripTimeMinutes(int min) {
    return 'Time: $min min';
  }

  @override
  String roundtripTimeHours(int h) {
    return 'Time: ${h}h';
  }

  @override
  String roundtripTimeHoursMinutes(int h, int min) {
    return 'Time: ${h}h ${min}min';
  }

  @override
  String roundtripDirectionLabel(int deg) {
    return 'Direction: $deg°';
  }

  @override
  String roundtripDistanceLabel(int km) {
    return 'Distance: $km km';
  }

  @override
  String get roundtripCompassN => 'N';

  @override
  String get roundtripCompassE => 'E';

  @override
  String get roundtripCompassS => 'S';

  @override
  String get roundtripCompassW => 'W';

  @override
  String get weatherTitle => 'Weather along the route';

  @override
  String get weatherDay => 'Day';

  @override
  String get weatherLoading => 'Loading weather…';

  @override
  String get weatherError => 'Weather request failed';

  @override
  String get weatherEmpty => 'No weather data';

  @override
  String weatherToday(String hm) {
    return 'Today $hm';
  }

  @override
  String weatherTomorrow(String hm) {
    return 'Tomorrow $hm';
  }

  @override
  String get weatherTemperature => 'Temperature';

  @override
  String get weatherWind => 'Wind';

  @override
  String get weatherPrecipitation => 'Precipitation';

  @override
  String get stagesTitle => 'Stage planner';

  @override
  String get stagesPerDay => 'km/day';

  @override
  String stagesTotalKm(String km) {
    return '$km km total';
  }

  @override
  String get stagesTargetLabel => 'Daily target';

  @override
  String stagesDays(int count) {
    return '$count days';
  }

  @override
  String get stagesCreating => 'Calculating stages…';

  @override
  String get stagesEmpty => 'No stages';

  @override
  String get stagesError => 'Stages could not be calculated';

  @override
  String get stagesShowOnMap => 'Show stages on map';

  @override
  String stagesDefault(int n) {
    return 'Stage $n';
  }

  @override
  String stagesRowSummary(String km, int ascent, String end) {
    return '$km km · $ascent m · through $end km';
  }

  @override
  String get accommodationTitle => 'Lodging';

  @override
  String get accommodationLoading => 'Searching for lodging…';

  @override
  String get accommodationNoResults => 'No lodging found';

  @override
  String get accommodationOpenInMaps => 'Open in Maps';

  @override
  String get accommodationRadius => 'Radius';

  @override
  String get accommodationHotel => 'Hotel';

  @override
  String get accommodationMotel => 'Motel';

  @override
  String get accommodationHostel => 'Hostel';

  @override
  String get accommodationGuesthouse => 'Guest house';

  @override
  String get accommodationBnb => 'B&B';

  @override
  String get accommodationApartment => 'Apartment';

  @override
  String get accommodationChalet => 'Chalet';

  @override
  String get accommodationAlpineHut => 'Alpine hut';

  @override
  String get accommodationWildernessHut => 'Wilderness hut';

  @override
  String get accommodationCampsite => 'Campsite';

  @override
  String get accommodationCaravanSite => 'Caravan site';

  @override
  String get sightsTitle => 'Points of interest';

  @override
  String get sightsLoading => 'Loading points of interest…';

  @override
  String get sightsNoResults => 'Nothing found';

  @override
  String get sightsCategoryAttraction => 'Attraction';

  @override
  String get sightsCategoryViewpoint => 'Viewpoint';

  @override
  String get sightsCategoryMonument => 'Monument';

  @override
  String get sightsCategoryMemorial => 'Memorial';

  @override
  String get sightsCategoryCastle => 'Castle';

  @override
  String get sightsCategoryRuins => 'Ruins';

  @override
  String get sightsCategoryChurch => 'Church';

  @override
  String get sightsCategoryMuseum => 'Museum';

  @override
  String get sightsCategoryArtwork => 'Artwork';

  @override
  String get sightsCategoryWaterfall => 'Waterfall';

  @override
  String get sightsCategoryPeak => 'Peak';

  @override
  String get sightsCategoryCave => 'Cave';

  @override
  String get sightsCategoryWater => 'Water';

  @override
  String get sightsCategorySpring => 'Spring';

  @override
  String get sightsCategoryInformation => 'Info sign';

  @override
  String get sightsCategoryDrinkingWater => 'Drinking water';

  @override
  String get sightsCategoryBench => 'Rest stop';

  @override
  String get sightsCategoryShelter => 'Shelter';

  @override
  String get sightsCategoryCampsite => 'Campsite';

  @override
  String get sightsCategoryPicnic => 'Picnic spot';

  @override
  String get sightsCategoryBakery => 'Bakery';

  @override
  String get sightsCategoryCafe => 'Café';

  @override
  String get sightsCategoryRestaurant => 'Restaurant';

  @override
  String get sightsCategorySupermarket => 'Supermarket';

  @override
  String get sightsCategoryBicycleRepair => 'Bike repair';

  @override
  String get sightsCategoryBicycleShop => 'Bike shop';

  @override
  String get surfaceTitle => 'Surface';

  @override
  String get surfaceCategoryAsphalt => 'Asphalt';

  @override
  String get surfaceCategoryPavingStones => 'Paving';

  @override
  String get surfaceCategoryGravel => 'Gravel';

  @override
  String get surfaceCategoryUnpaved => 'Unpaved';

  @override
  String get surfaceCategoryOffroad => 'Off-road';

  @override
  String get surfaceCategoryUnknown => 'Unknown';

  @override
  String get surfaceAsphalt => 'Asphalt';

  @override
  String get surfacePaved => 'Paved';

  @override
  String get surfaceConcrete => 'Concrete';

  @override
  String get surfacePavingStones => 'Paving stones';

  @override
  String get surfaceCobblestone => 'Cobblestone';

  @override
  String get surfaceCompacted => 'Compacted';

  @override
  String get surfaceGravel => 'Gravel';

  @override
  String get surfaceFineGravel => 'Fine gravel';

  @override
  String get surfaceUnpaved => 'Unpaved';

  @override
  String get surfaceGround => 'Ground';

  @override
  String get surfaceDirt => 'Dirt';

  @override
  String get surfaceGrass => 'Grass';

  @override
  String get surfaceSand => 'Sand';

  @override
  String get surfaceWood => 'Wood';

  @override
  String get surfaceMetal => 'Metal';

  @override
  String get surfaceUnknown => 'Unknown';

  @override
  String get highwayCycleway => 'Cycleway';

  @override
  String get highwayPath => 'Path';

  @override
  String get highwayTrack => 'Track';

  @override
  String get highwayFootway => 'Footway';

  @override
  String get highwayPedestrian => 'Pedestrian';

  @override
  String get highwayLivingStreet => 'Living street';

  @override
  String get highwayResidential => 'Residential';

  @override
  String get highwayService => 'Service road';

  @override
  String get highwayUnclassified => 'Minor road';

  @override
  String get highwayTertiary => 'Tertiary road';

  @override
  String get highwaySecondary => 'Secondary road';

  @override
  String get highwayPrimary => 'Primary road';

  @override
  String get highwayTrunk => 'Trunk road';

  @override
  String get highwayMotorway => 'Motorway';

  @override
  String get highwaySteps => 'Steps';

  @override
  String get highwayUnknown => 'Way';

  @override
  String get shareDialogTitle => 'Share route';

  @override
  String get shareLinkCopied => 'Link copied';

  @override
  String get shareLinkCreating => 'Creating link…';

  @override
  String get shareLinkError => 'Could not create link';

  @override
  String get gpxExportTitle => 'Export GPX';

  @override
  String get gpxExportDone => 'GPX saved';

  @override
  String get gpxExportError => 'GPX export failed';

  @override
  String get infoDialogTitle => 'Route info';

  @override
  String infoPoiCount(int count) {
    return '$count POIs';
  }

  @override
  String get elevationToggleShow => 'Show profile';

  @override
  String get elevationToggleHide => 'Hide profile';

  @override
  String get addWaypoint => 'Add waypoint';

  @override
  String get removeWaypoint => 'Remove waypoint';

  @override
  String get setAsStart => 'Set as start';

  @override
  String get setAsEnd => 'Set as end';

  @override
  String get modeAtoB => 'A → B';

  @override
  String get modeRoundtrip => 'Loop';

  @override
  String get tapRouteForInfo => 'Tap a route for details';

  @override
  String get routeLinkCopied => 'Link copied to clipboard';

  @override
  String get noRouteHere => 'No route found here';

  @override
  String get mapStyleTitle => 'Map style';

  @override
  String get mapOverlayRoutes => 'Overlay routes';

  @override
  String get mapRouteVizTitle => 'Route coloring';

  @override
  String get mapVizGradient => 'Gradient';

  @override
  String get gpsPermanentlyDenied =>
      'Location permission permanently denied. Please enable it in settings.';

  @override
  String gpsFetchFailed(String error) {
    return 'Could not determine location: $error';
  }

  @override
  String routingFailed(String error) {
    return 'Routing failed: $error';
  }

  @override
  String roundtripFailed(String error) {
    return 'Round trip failed: $error';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String overpassError(String error) {
    return 'Overpass error: $error';
  }

  @override
  String get poiAddTitle => 'Add POI';

  @override
  String get poiEditTitle => 'Edit POI';

  @override
  String get poiCategoryLabel => 'Category';

  @override
  String get poiNameLabel => 'Name';

  @override
  String get poiNoteLabel => 'Note (optional)';

  @override
  String get poiTypesTitle => 'POI types';

  @override
  String get filterSelectAll => 'All';

  @override
  String get filterSelectNone => 'None';

  @override
  String get sightWikipedia => 'Wikipedia';

  @override
  String get sightWebsite => 'Website';

  @override
  String get sightOsmRelation => 'OSM relation';

  @override
  String get sightAsWaypoint => 'As waypoint';

  @override
  String get sightFeeYes => 'Entry fee';

  @override
  String get sightFeeNo => 'Free';

  @override
  String get sightAccessibleYes => 'Wheelchair accessible';

  @override
  String get sightAccessibleLimited => 'Limited accessibility';

  @override
  String get sightAccessibleNo => 'Not accessible';

  @override
  String sightBuilt(String year) {
    return 'Built $year';
  }

  @override
  String get sightHeritage => 'Heritage protected';

  @override
  String sightArtist(String name) {
    return 'Artist: $name';
  }

  @override
  String get sightsGroupTourism => 'Tourism';

  @override
  String get sightsGroupHistoric => 'Historic';

  @override
  String get sightsGroupNatural => 'Nature';

  @override
  String get sightsGroupShop => 'Shop';

  @override
  String get sightsGroupAmenity => 'Amenity';

  @override
  String get sightsGroupRailway => 'Railway';

  @override
  String get sightSubAttraction => 'Attraction';

  @override
  String get sightSubViewpoint => 'Viewpoint';

  @override
  String get sightSubMuseum => 'Museum';

  @override
  String get sightSubArtwork => 'Artwork';

  @override
  String get sightSubPicnicSite => 'Picnic site';

  @override
  String get sightSubInformation => 'Tourist info';

  @override
  String get sightSubHotel => 'Hotel';

  @override
  String get sightSubGuestHouse => 'Guesthouse';

  @override
  String get sightSubHostel => 'Hostel';

  @override
  String get sightSubCampSite => 'Campsite';

  @override
  String get sightSubCastle => 'Castle';

  @override
  String get sightSubMonument => 'Monument';

  @override
  String get sightSubMemorial => 'Memorial';

  @override
  String get sightSubRuins => 'Ruins';

  @override
  String get sightSubArchaeological => 'Archaeological site';

  @override
  String get sightSubPeak => 'Peak';

  @override
  String get sightSubWaterfall => 'Waterfall';

  @override
  String get sightSubCave => 'Cave';

  @override
  String get sightSubSupermarket => 'Supermarket';

  @override
  String get sightSubBakery => 'Bakery';

  @override
  String get sightSubConvenience => 'Convenience store';

  @override
  String get sightSubBicycleShop => 'Bike shop';

  @override
  String get sightSubRestaurant => 'Restaurant';

  @override
  String get sightSubCafe => 'Café';

  @override
  String get sightSubFastFood => 'Fast food';

  @override
  String get sightSubBiergarten => 'Beer garden';

  @override
  String get sightSubPub => 'Pub';

  @override
  String get sightSubDrinkingWater => 'Drinking water';

  @override
  String get sightSubToilets => 'Toilets';

  @override
  String get sightSubPharmacy => 'Pharmacy';

  @override
  String get sightSubAtm => 'ATM';

  @override
  String get sightSubBicycleRepair => 'Bike repair station';

  @override
  String get sightSubBicycleRental => 'Bike rental';

  @override
  String get sightSubChargingStation => 'Charging station';

  @override
  String get sightSubStation => 'Train station';

  @override
  String get sightSubHalt => 'Stop';

  @override
  String get sightSubTramStop => 'Tram stop';

  @override
  String get poiCatLodging => 'Lodging';

  @override
  String get poiCatFood => 'Food';

  @override
  String get poiCatWater => 'Drinking water';

  @override
  String get poiCatShop => 'Shop';

  @override
  String get poiCatScenic => 'Scenic';

  @override
  String get poiCatCamping => 'Camping';

  @override
  String get poiCatInfo => 'Information';

  @override
  String get poiCatOther => 'Other';

  @override
  String get defaultWaypoint => 'Destination';

  @override
  String get defaultTourName => 'Wegwiesel tour';

  @override
  String roundtripTourName(int km) {
    return 'Loop ${km}km';
  }

  @override
  String stageTooltip(int index, String km) {
    return 'Stage $index: $km km';
  }

  @override
  String get osmRouteTypeBicycle => 'Cycling route';

  @override
  String get osmRouteTypeHiking => 'Hiking trail';

  @override
  String get osmRouteTypeMtb => 'MTB route';

  @override
  String get osmNetworkIcn => 'International';

  @override
  String get osmNetworkNcn => 'National';

  @override
  String get osmNetworkRcn => 'Regional';

  @override
  String get osmNetworkLcn => 'Local';

  @override
  String get osmNetworkIwn => 'International (Hiking)';

  @override
  String get osmNetworkNwn => 'National (Hiking)';

  @override
  String get osmNetworkRwn => 'Regional (Hiking)';

  @override
  String get osmNetworkLwn => 'Local (Hiking)';

  @override
  String get mapStyleStandard => 'Standard';

  @override
  String get mapStyleCycling => 'Cycling';

  @override
  String get mapStyleTopo => 'Topo';

  @override
  String get mapStyleSatellite => 'Satellite';

  @override
  String get routeOverlayCycling => 'Cycling routes';

  @override
  String get routeOverlayHiking => 'Hiking trails';

  @override
  String get routeOverlayMtb => 'MTB routes';
}
