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
  String get settingsSectionPersonal => 'Personal';

  @override
  String get settingsSectionEnergy => 'Energy & Battery';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsBodyWeight => 'Body weight';

  @override
  String get settingsBodyWeightEdit => 'Set body weight';

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
  String get profileCategoryCar => 'Car';

  @override
  String get profileCategoryEbike => 'E-bike';

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
  String get profileHiking => 'Hiking';

  @override
  String get profileRunning => 'Running';

  @override
  String get profileShortest => 'Shortest route';

  @override
  String get profileCar => 'Car';

  @override
  String get profileCarTrailer => 'Car with trailer';

  @override
  String get profileEbike => 'E-bike';

  @override
  String get profileEbikeMtb => 'E-MTB';

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
  String get roundtripWindOptimized => 'Wind-optimised';

  @override
  String get roundtripWindCalm => 'Barely any wind – plain roundtrip generated';

  @override
  String roundtripWindHint(String dir, int kmh) {
    return 'Headwind out, tailwind home · wind from $dir, $kmh km/h';
  }

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
  String get stagesByKm => 'km/day';

  @override
  String get stagesByDays => 'Days';

  @override
  String stagesDaysValue(int days) {
    return '$days days';
  }

  @override
  String stagesPlanSummary(int count, int km) {
    return '$count stages · ~$km km';
  }

  @override
  String get stagesDaylightOver => 'exceeds daylight';

  @override
  String get stagesDaylightTight => 'tight before sunset';

  @override
  String get stagesBatteryOver => 'battery won\'t last';

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
  String get highwayTertiary => 'Tertiary';

  @override
  String get highwaySecondary => 'Secondary road';

  @override
  String get highwayPrimary => 'Primary';

  @override
  String get highwayTrunk => 'Trunk road';

  @override
  String get highwayMotorway => 'Motorway/Trunk';

  @override
  String get highwaySteps => 'Steps';

  @override
  String get highwayUnknown => 'Unknown';

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
  String get shareSheetTitle => 'Share route';

  @override
  String get shareCopyLink => 'Copy link';

  @override
  String get shareCopyLinkSubtitle => 'Recipient opens it in their browser';

  @override
  String get shareToGarmin => 'Send to Garmin';

  @override
  String get shareToGarminSubtitle =>
      'Enter the code in the Garmin Edge companion app';

  @override
  String get garminCodeTitle => 'Code for your Garmin';

  @override
  String get garminCodeHint =>
      'Enter this code in the Wegwiesel Sync app on your Edge. Valid for 7 days.';

  @override
  String garminCodeExpiresAt(String date) {
    return 'Valid until $date';
  }

  @override
  String get garminCodeCopied => 'Code copied';

  @override
  String garminUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get garminUploading => 'Uploading…';

  @override
  String get shareDirectToEdge => 'Send straight to Edge';

  @override
  String get shareDirectToEdgeSubtitle =>
      'Via Bluetooth through Garmin Connect Mobile';

  @override
  String get garminPickDevicesTitle => 'Pick an Edge';

  @override
  String get garminPickDevicesPrompt =>
      'No Edge is linked to Wegwiesel yet. You\'ll be sent to Garmin Connect Mobile to authorise one, then come back here.';

  @override
  String get garminPickDevicesAction => 'Open Garmin Connect Mobile';

  @override
  String garminSendingTo(String device) {
    return 'Sending to $device…';
  }

  @override
  String garminSendSuccess(String device) {
    return 'Course sent to $device';
  }

  @override
  String garminSendFailed(String error) {
    return 'Send failed: $error';
  }

  @override
  String get garminNoDevicesAfterPick => 'No Edge picked';

  @override
  String get garminRepickDevices => 'Pick a different Edge';

  @override
  String get garminRepickDevicesSubtitle =>
      'Open Garmin Connect Mobile and refresh authorisation';

  @override
  String garminDeviceOffline(String device) {
    return '$device is offline';
  }

  @override
  String get menuStartNavigation => 'Start navigation';

  @override
  String get menuReturnOneWay => 'One way only';

  @override
  String get menuReturnSameWay => 'Out & back (same way)';

  @override
  String get menuReturnDifferentWay => 'Out & back (different way)';

  @override
  String get navigateContinue => 'Continue';

  @override
  String get navigateTurnLeft => 'turn left';

  @override
  String get navigateTurnRight => 'turn right';

  @override
  String get navigateKeepLeft => 'keep left';

  @override
  String get navigateKeepRight => 'keep right';

  @override
  String get navigateStraight => 'straight';

  @override
  String get navigateUTurn => 'u-turn';

  @override
  String get navigateExit => 'take the exit';

  @override
  String navigateRoundabout(int n) {
    return 'take exit $n at the roundabout';
  }

  @override
  String get navigateRemaining => 'remaining';

  @override
  String get navigateEta => 'ETA';

  @override
  String get navigateRerouting => 'Re-routing…';

  @override
  String get navigateArrived => 'Arrived';

  @override
  String get navigateStop => 'Stop';

  @override
  String get navigateNorthUp => 'North up';

  @override
  String get navigateHeadingUp => 'Heading up';

  @override
  String get navigateVoiceOn => 'Voice on';

  @override
  String get navigateVoiceOff => 'Voice off';

  @override
  String voiceInMeters(int n) {
    return 'In $n meters';
  }

  @override
  String get voiceNow => 'Now';

  @override
  String get voiceRerouting => 'Recalculating route';

  @override
  String get voiceArrived => 'You have arrived at your destination';

  @override
  String get altRoutePrimary => 'Main';

  @override
  String altRouteVariant(int n) {
    return 'Variant $n';
  }

  @override
  String get altRouteCalculating => 'calculating…';

  @override
  String get altRouteShortest => 'Shortest route';

  @override
  String get altRouteAvoidMotorways => 'Avoid motorways';

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
  String roundtripOffTarget(String actualKm) {
    return 'No matching round trip found (BRouter returned $actualKm km). Try a different direction or a shorter distance.';
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
  String get poiCatFuel => 'Fuel';

  @override
  String get poiCatCharging => 'Charging station';

  @override
  String get poiCatSights => 'Sights';

  @override
  String get poiCatScenic => 'Scenic';

  @override
  String get poiCatShelter => 'Shelter';

  @override
  String get sacBadgePrefix => 'Difficulty:';

  @override
  String get sacT1 => 'Hiking (T1)';

  @override
  String get sacT2 => 'Mountain hiking (T2)';

  @override
  String get sacT3 => 'Demanding mountain hiking (T3)';

  @override
  String get sacT4 => 'Alpine hiking (T4)';

  @override
  String get sacT5 => 'Demanding alpine hiking (T5)';

  @override
  String get sacT6 => 'Difficult alpine hiking (T6)';

  @override
  String get preferHikingRoutesLabel => 'Prefer waymarked trails';

  @override
  String get hikingPresetTitle => 'Difficulty preset';

  @override
  String get hikingPresetComfortable => 'Easy';

  @override
  String get hikingPresetSporty => 'Sporty';

  @override
  String get hikingPresetMountain => 'Mountain';

  @override
  String get actionPauseRecommendations => 'Breaks';

  @override
  String get pauseRecsTooShort =>
      'Route too short for break suggestions (min. 1.5 h).';

  @override
  String get pauseRecsNone => 'No suitable rest spots found near the route.';

  @override
  String pauseRecsFailed(String error) {
    return 'Break search failed: $error';
  }

  @override
  String get poiCatPicnic => 'Picnic';

  @override
  String get poiCatStation => 'Train station';

  @override
  String get settingsBikepackingMode => 'Bikepacking mode';

  @override
  String get settingsBikepackingModeSub =>
      'Prioritizes camping, water, shelters and train stations in POI search';

  @override
  String get stagesStartDateLabel => 'Start date:';

  @override
  String get stagesOvernightUnnamed => '(Unnamed lodging)';

  @override
  String rideRecoveredSnack(String km) {
    return 'Interrupted recording recovered ($km km). Find it under \"Recordings\".';
  }

  @override
  String get wildCampDisclaimerTitle => 'Wild camping — please note';

  @override
  String get wildCampDisclaimerBody =>
      'Bikepacking mode now also shows informal tent pitches (camp_pitch) in POI search.\n\nIn Germany wild camping outside of designated sites is mostly prohibited — exact rules depend on the federal state and local forestry law. In Sweden/Norway/Finland the \"Right to Roam\" applies. Check the local rules yourself before pitching — Wegwiesel takes no responsibility for the legal status of any chosen spot.';

  @override
  String get shareToWahoo => 'Send to Wahoo';

  @override
  String get shareToWahooSubtitle =>
      'Wahoo Companion app opens the route automatically';

  @override
  String wahooSendFailed(String error) {
    return 'Send to Wahoo failed: $error';
  }

  @override
  String get wahooNotInstalledTitle => 'Wahoo app not found';

  @override
  String get wahooNotInstalledBody =>
      'Install the \"Wahoo Companion\" or \"Wahoo Fitness\" app from the App Store / Play Store and try again.';

  @override
  String get menuFindFtpRoute => 'Find training segment';

  @override
  String get ftpFinderTitle => 'Find FTP test segment';

  @override
  String get ftpFinderTest20 => '20-min';

  @override
  String get ftpFinderTest8 => '8-min (2×)';

  @override
  String get ftpFinderTestRamp => 'Ramp';

  @override
  String get ftpFinderTestSweetSpot => 'Sweet spot';

  @override
  String get ftpFinderModeFlat => 'Flat';

  @override
  String get ftpFinderModeClimb => 'Climb';

  @override
  String get ftpFinderModeEither => 'Either';

  @override
  String ftpFinderRadius(int km) {
    return 'Radius: $km km';
  }

  @override
  String get ftpFinderSearch => 'Search segments';

  @override
  String get ftpFinderPickToSearch =>
      'Pick a test type, then tap \"Search segments\".';

  @override
  String get ftpFinderEmpty =>
      'No suitable segment within the radius. Try a larger radius or a different test type.';

  @override
  String get ftpFinderUnnamed => 'Unnamed segment';

  @override
  String ftpFinderPicked(String km) {
    return 'Segment selected ($km km). Warm up time?';
  }

  @override
  String get ftpFinderStartRecord => 'Start recording';

  @override
  String get ftpFinderOriginWaypoint => 'Searching around your start waypoint.';

  @override
  String get ftpFinderOriginGps =>
      'Searching around your current GPS position.';

  @override
  String get ftpFinderOriginMapView =>
      'Searching around the map centre. For better results, tap a point on the map first or enable GPS.';

  @override
  String get menuRouteSourcesTooltip => 'Route sources';

  @override
  String get poiCatCamping => 'Camping';

  @override
  String get poiCatInfo => 'Information';

  @override
  String get poiCatOther => 'Other';

  @override
  String get routePoiSearchTitle => 'Search along route';

  @override
  String get routePoiSearchEmpty => 'Nothing found along the route';

  @override
  String get routePoiSearchPickCategories => 'Choose categories';

  @override
  String routePoiSearchAt(String km) {
    return 'at $km km';
  }

  @override
  String routePoiSearchSide(int m) {
    return '$m m off-route';
  }

  @override
  String get routePoiSearchAdd => 'Add to route';

  @override
  String get menuSearchAlongRoute => 'Search along route';

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
  String get profileModeGradient => 'Gradient';

  @override
  String get profileModeSurface => 'Surface';

  @override
  String get profileModeHighway => 'Road type';

  @override
  String get profileModeSmoothness => 'Smoothness';

  @override
  String get profileModeMaxSpeed => 'Speed limit';

  @override
  String get profileModeCost => 'Routing cost';

  @override
  String get profileZoomLocked => 'Zoom locked';

  @override
  String get profileZoomUnlocked => 'Zoom free';

  @override
  String get profileZoomReset => 'Reset zoom';

  @override
  String get profileSimplifiedWarning =>
      'Simplified view — zoom in for details';

  @override
  String get profileTooltipDistance => 'Distance';

  @override
  String get profileTooltipElevation => 'Elevation';

  @override
  String get profileTooltipGradient => 'Gradient';

  @override
  String get profileTooltipAscent => 'Ascent';

  @override
  String get profileTooltipHighway => 'Road';

  @override
  String get profileTooltipSurface => 'Surface';

  @override
  String get profileTooltipSmoothness => 'Smoothness';

  @override
  String get profileTooltipMaxSpeed => 'Speed';

  @override
  String get profileTooltipCost => 'Cost';

  @override
  String get smoothnessExcellent => 'Excellent';

  @override
  String get smoothnessGood => 'Good';

  @override
  String get smoothnessIntermediate => 'Intermediate';

  @override
  String get smoothnessBad => 'Bad';

  @override
  String get smoothnessUnknown => 'Unknown';

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

  @override
  String get routeOverlayHillshade => 'Hillshade';

  @override
  String get routeOverlayHeatmap => 'Wegwiesel heatmap';

  @override
  String get gpxImportTitle => 'Import GPX track';

  @override
  String get gpxImportButton => 'Choose GPX file';

  @override
  String gpxImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String gpxImportSuccess(int points, String km) {
    return 'Track loaded: $points points, $km km';
  }

  @override
  String get gpxImportEmpty => 'No track points found in the file';

  @override
  String get gpxModeTitle => 'How should the track be imported?';

  @override
  String gpxModeSummary(int points, String km) {
    return '$points points · $km km';
  }

  @override
  String get gpxModeRerouteTitle => 'Re-route with your profile';

  @override
  String get gpxModeRerouteBody =>
      'Wegwiesel recomputes the route using your currently selected profile. You get surface coloring, elevation modes, turn-by-turn navigation and voice. The route may differ slightly from the original.';

  @override
  String get gpxModeTrackTitle => 'Keep the track as-is';

  @override
  String get gpxModeTrackBody =>
      'Show the original geometry 1:1. No surface info, no voice navigation — best when you want to follow the source tour exactly.';

  @override
  String get urlImportTitle => 'Import tour URL';

  @override
  String get urlImportHint => 'Komoot link or direct GPX URL';

  @override
  String get urlImportFetch => 'Fetch';

  @override
  String get urlImportCancel => 'Cancel';

  @override
  String get urlImportLoading => 'Fetching tour…';

  @override
  String get urlImportErrEmpty => 'Please enter a URL';

  @override
  String get urlImportErrInvalid => 'URL is not valid';

  @override
  String get urlImportErrNetwork => 'Network error';

  @override
  String get urlImportErrForbidden => 'Tour is private or requires login';

  @override
  String get urlImportErrNotFound => 'Tour not found';

  @override
  String get urlImportErrNotGpx => 'URL did not return GPX data';

  @override
  String get urlImportErrStravaLogin =>
      'Strava routes can\'t be imported directly because they require login — please export the GPX manually and open it via \"Import GPX\"';

  @override
  String get nogoTitle => 'No-go areas';

  @override
  String get nogoEmpty => 'No no-go areas defined';

  @override
  String get nogoAdd => 'Add no-go area';

  @override
  String get nogoAddHint => 'Tap the map to place a no-go area';

  @override
  String nogoRadius(int meters) {
    return 'Radius: $meters m';
  }

  @override
  String get nogoDelete => 'Remove';

  @override
  String get nogoConfirmCancel => 'Cancel';

  @override
  String get nogoConfirmAdd => 'Add';

  @override
  String get menuImportGpx => 'Import GPX';

  @override
  String get menuImportUrl => 'Import tour URL';

  @override
  String get menuNogos => 'No-go areas';

  @override
  String get menuRecording => 'Record ride';

  @override
  String get menuRecordedRides => 'Recorded rides';

  @override
  String get menuLibrary => 'Discover routes';

  @override
  String get menuPublishRoute => 'Publish route';

  @override
  String get menuOfflineMaps => 'Offline maps';

  @override
  String get offlineMapsTitle => 'Offline maps';

  @override
  String get offlineMapsCurrentSection => 'Cache';

  @override
  String get offlineMapsDownloadSection => 'Download';

  @override
  String get offlineMapsProgressSection => 'Download running';

  @override
  String get offlineMapsUsed => 'Used';

  @override
  String get offlineMapsLimit => 'Storage limit';

  @override
  String get offlineMapsClearTitle => 'Clear cache';

  @override
  String get offlineMapsClearSubtitle => 'Remove all cached tiles';

  @override
  String get offlineMapsClearBody =>
      'All stored map tiles will be deleted. They will be re-fetched the next time you go online.';

  @override
  String get offlineMapsDownloadCurrent => 'Download current view';

  @override
  String get offlineMapsDownloadCurrentSub =>
      'Pre-load zoom 8–15 tiles for the visible area';

  @override
  String get offlineMapsNoViewport =>
      'First adjust the map to the area you want to download';

  @override
  String get offlineMapsConfirmTitle => 'Download region?';

  @override
  String offlineMapsConfirmBody(int mb) {
    return 'Estimated size: about $mb MB. Please keep the app open during the download.';
  }

  @override
  String get offlineMapsStart => 'Start';

  @override
  String offlineMapsProgressLine(int done, int total) {
    return '$done of $total tiles';
  }

  @override
  String offlineMapsProgressDone(int total) {
    return '$total tiles available offline';
  }

  @override
  String get libraryTitle => 'Discover routes';

  @override
  String get libraryEmpty => 'No public routes match this filter yet';

  @override
  String get libraryFilterAll => 'All';

  @override
  String get libraryFilterNear => 'Near me';

  @override
  String get libraryFilterShort => 'short (< 30 km)';

  @override
  String get libraryFilterMedium => 'medium (30–80 km)';

  @override
  String get libraryFilterLong => 'long (> 80 km)';

  @override
  String get libraryItemBy => 'by a Wegwiesel user';

  @override
  String get librarySearchHint => 'Search title or description…';

  @override
  String get libraryLoadFailed => 'Could not load library';

  @override
  String get libraryOpenFailed => 'Could not open route';

  @override
  String get publishTitle => 'Publish route';

  @override
  String get publishExplain =>
      'Your route becomes visible to everyone with a title and description. No account, no tracking — only you on this device can later remove it from the library.';

  @override
  String get publishNameLabel => 'Title';

  @override
  String get publishNameHint => 'e.g. Rhine cycle path Mainz to Koblenz';

  @override
  String get publishDescriptionLabel => 'Description';

  @override
  String get publishDescriptionHint => 'What makes this route special?';

  @override
  String get publishConfirm => 'Publish';

  @override
  String get publishSuccess => 'Route is now public';

  @override
  String get publishFailed => 'Publishing failed';

  @override
  String get publishUnpublish => 'Remove from library';

  @override
  String get publishUnpublished => 'Route removed';

  @override
  String get recordingTitle => 'Recording';

  @override
  String get recordingStart => 'Start';

  @override
  String get recordingPause => 'Pause';

  @override
  String get recordingResume => 'Resume';

  @override
  String get recordingStop => 'Stop';

  @override
  String get recordingPermissionDenied => 'Location permission required';

  @override
  String get recordingDistance => 'Distance';

  @override
  String get recordingDuration => 'Time';

  @override
  String get recordingAvgSpeed => 'Avg speed';

  @override
  String get recordingMaxSpeed => 'Max speed';

  @override
  String get recordingAscent => 'Ascent';

  @override
  String get recordingDescent => 'Descent';

  @override
  String get recordingKcal => 'Calories';

  @override
  String get recordingSaveTitle => 'Save recording';

  @override
  String get recordingSaveHint => 'Ride name';

  @override
  String get recordingSave => 'Save';

  @override
  String recordingDefaultName(String date, String time) {
    return 'Ride $date $time';
  }

  @override
  String get recordingSummaryTitle => 'Recording finished';

  @override
  String get recordingCloseSummary => 'Close';

  @override
  String get recordingExportGpx => 'Share as GPX';

  @override
  String get recordingActive => 'Recording in progress';

  @override
  String get recordedRidesTitle => 'Recorded rides';

  @override
  String get recordedRidesEmpty => 'No rides recorded yet';

  @override
  String get recordedRideDelete => 'Delete';

  @override
  String get liveTrackingStart => 'Share live position';

  @override
  String get liveTrackingActive => 'Live position shared (tap to stop)';

  @override
  String get liveTrackingTitle => 'Live tracking';

  @override
  String get liveTrackingExplain =>
      'This link shows your current position on a map and expires automatically after 12 hours.';

  @override
  String get liveTrackingShare => 'Share link';

  @override
  String get liveTrackingCopy => 'Copy link';

  @override
  String get liveTrackingShareBody => 'Follow my ride live:';

  @override
  String get liveTrackingError => 'Could not start live tracking';

  @override
  String get profileSpeedEdit => 'Adjust speed';

  @override
  String profileSpeedDefault(int kmh) {
    return 'Default: $kmh km/h';
  }

  @override
  String get profileSpeedReset => 'Reset';

  @override
  String get routingFlagsTitle => 'Routing options';

  @override
  String routingFlagsShowMore(int n) {
    return '$n more options';
  }

  @override
  String get routingFlagsHideMore => 'Show less';

  @override
  String get routingFlagLowElevation => 'Low elevation';

  @override
  String get routingFlagAvoidSteps => 'Avoid steps';

  @override
  String get routingFlagAvoidFerries => 'Avoid ferries';

  @override
  String get routingFlagAvoidMainRoads => 'Avoid main roads';

  @override
  String get routingFlagPreferCycleRoutes => 'Prefer cycle routes';

  @override
  String get routingFlagPreferQuiet => 'Prefer quiet';

  @override
  String get routingFlagPreferForest => 'Prefer forest & parks';

  @override
  String get routingFlagPreferRiver => 'Along rivers';

  @override
  String get routingFlagAvoidTowns => 'Bypass towns';

  @override
  String get routingFlagConsiderTraffic => 'Consider traffic';

  @override
  String get routingFlagAvoidPath => 'Avoid narrow paths';

  @override
  String get routingFlagAvoidSteep => 'Avoid steep inclines';

  @override
  String get routingFlagAvoidMotorways => 'Avoid motorways';

  @override
  String get routingFlagAvoidToll => 'Avoid toll';

  @override
  String get routingFlagAvoidUnpaved => 'Avoid unpaved';

  @override
  String get routingFlagShortest => 'Shortest route';

  @override
  String get routingFlagAvoidNaturalPaths => 'Avoid nature trails';

  @override
  String get routingFlagAvoidFarmTracks => 'Avoid farm tracks';

  @override
  String navigateDarkRide(String dur) {
    return 'After sunset: $dur';
  }

  @override
  String navigateUntilSunset(String dur) {
    return 'Sunset in $dur';
  }

  @override
  String get routeOverlayMyRoutes => 'My tracks';

  @override
  String get routePoiOnlyOpenNow => 'Open now';

  @override
  String get routePoiOpen => 'OPEN';

  @override
  String get routePoiClosed => 'CLOSED';

  @override
  String get settingsBatteryBudget => 'Battery budget';

  @override
  String get settingsBatteryBudgetSub =>
      'Estimate power-bank capacity for your tour';

  @override
  String get batteryBudgetTitle => 'Battery budget';

  @override
  String batteryBudgetDuration(int h) {
    return 'Tour duration: ${h}h';
  }

  @override
  String batteryBudgetDisplayPct(int pct) {
    return 'Display on: $pct% of the time';
  }

  @override
  String get batteryBudgetNight => 'Night riding';

  @override
  String get batteryBudgetNightSub => 'Higher display brightness, more drain';

  @override
  String get batteryBudgetNeeded => 'Phone needs';

  @override
  String get batteryBudgetPowerbank => 'Power-bank recommendation';

  @override
  String get batteryBudgetDisclaimer =>
      'Rough estimate — actual drain depends on phone, brightness, and background apps.';

  @override
  String get shareToWatch => 'Send to Watch';

  @override
  String get shareToWatchSubtitle => 'Push the route to your Apple Watch';

  @override
  String get shareToWatchQueued => 'Route sent to Watch';

  @override
  String get shareToWatchFailed => 'Watch not reachable';

  @override
  String get settingsEbikeCapacity => 'E-bike battery';

  @override
  String get settingsEbikeCapacityEdit => 'Battery capacity';

  @override
  String get settingsEvTitle => 'Electric car';

  @override
  String get settingsEvOff => 'Off';

  @override
  String settingsEvSummary(String kwh, String cons) {
    return '$kwh kWh · $cons kWh/100 km';
  }

  @override
  String get settingsEvEnabled => 'EV mode (car profile)';

  @override
  String get settingsEvEnabledSub =>
      'Range badge + charging-stop planner for the car';

  @override
  String get settingsEvBattery => 'Battery';

  @override
  String get settingsEvConsumption => 'Consumption';

  @override
  String get settingsEvStartCharge => 'Start charge';

  @override
  String evChargeTime(int min) {
    return '~$min min charging';
  }

  @override
  String evPriceOsm(String price) {
    return 'Price (OSM): $price';
  }

  @override
  String evPriceAdhoc(String price) {
    return 'Ad-hoc $price €/kWh';
  }

  @override
  String get evChargingFree => 'free';

  @override
  String get evChargingPaid => 'paid';

  @override
  String get ebikeRangeComfortable => 'comfortable';

  @override
  String get ebikeRangeTight => 'getting tight';

  @override
  String get ebikeRangeBarely => 'barely enough';

  @override
  String get ebikeRangeOver => 'won\'t make it';

  @override
  String get ebikePlanChargingStop => 'Plan charging stop';

  @override
  String get ebikePlanChargingSearching => 'Searching for a charging station…';

  @override
  String get ebikePlanChargingNoneFound => 'No charging station found in range';

  @override
  String get ebikePlanChargingTitle => 'Charging stop suggestion';

  @override
  String ebikePlanChargingDetails(String km, int m) {
    return '$km km along the route, $m m off-route';
  }

  @override
  String get ebikePlanChargingInsert => 'Insert';

  @override
  String get newPill => 'NEW';

  @override
  String get activityPickerTitle => 'What are you doing today?';

  @override
  String get tourProfile =>
      'Pick your profile / activity here (bike, e-bike, hiking, car …).';

  @override
  String get tourModes => 'A→B route or a roundtrip? Switch here.';

  @override
  String get tourSearch =>
      'Search an address — or just tap your destination on the map. Your location is the start.';

  @override
  String get tourSkip => 'SKIP';

  @override
  String get mapHintChooseProfile => 'Pick a profile & A→B / roundtrip up top';

  @override
  String get mapTapHintGps =>
      'Tap your destination — your location is the start';

  @override
  String get mapTapHintNoGps => 'Tap start and destination on the map';

  @override
  String get activityPickerAdvanced => 'Advanced (all profiles)';

  @override
  String get activityPickerAllProfiles => 'All profiles';

  @override
  String get activityEv => 'E-car';

  @override
  String get activityTour => 'Tour';

  @override
  String get activityCommute => 'Commute';

  @override
  String get activityRoad => 'Road bike';

  @override
  String get activityGravel => 'Gravel';

  @override
  String get activityMtb => 'MTB';

  @override
  String get activityEbike => 'E-bike';

  @override
  String get activityBikepacking => 'Bikepacking';

  @override
  String get activityHiking => 'Hiking';

  @override
  String get activityRunning => 'Running';

  @override
  String get activityUltra => 'Ultra';

  @override
  String get activityCar => 'Car';

  @override
  String get activityCarTrailer => 'Car + trailer';

  @override
  String get activitySafety => 'Safe';

  @override
  String get statsBarTapToExpand => 'Tap for details';

  @override
  String get ebikeWorstLeg => 'Longest leg';

  @override
  String get ebikePlanChargingOneStop => '1 charging stop suggested';

  @override
  String ebikePlanChargingManyStops(int n) {
    return '$n charging stops suggested';
  }

  @override
  String get ebikePlanChargingIncomplete =>
      'Heads up: one leg has no reachable charging station — the battery still won\'t last everywhere.';
}
