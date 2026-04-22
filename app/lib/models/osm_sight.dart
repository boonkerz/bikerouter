import '../l10n/app_localizations.dart';

/// All OSM POI types we support, grouped by category.
const Map<String, List<String>> sightTypes = {
  'tourism': [
    'attraction',
    'viewpoint',
    'museum',
    'artwork',
    'picnic_site',
    'information',
    'hotel',
    'guest_house',
    'hostel',
    'camp_site',
  ],
  'historic': [
    'castle',
    'monument',
    'memorial',
    'ruins',
    'archaeological_site',
  ],
  'natural': [
    'peak',
    'waterfall',
    'cave_entrance',
  ],
  'shop': [
    'supermarket',
    'bakery',
    'convenience',
    'bicycle',
  ],
  'amenity': [
    'restaurant',
    'cafe',
    'fast_food',
    'biergarten',
    'pub',
    'drinking_water',
    'toilets',
    'pharmacy',
    'atm',
    'bicycle_repair_station',
    'bicycle_rental',
    'charging_station',
  ],
  'railway': [
    'station',
    'halt',
    'tram_stop',
  ],
};

String sightCategoryLabel(AppLocalizations l, String category) {
  switch (category) {
    case 'tourism':
      return l.sightsGroupTourism;
    case 'historic':
      return l.sightsGroupHistoric;
    case 'natural':
      return l.sightsGroupNatural;
    case 'shop':
      return l.sightsGroupShop;
    case 'amenity':
      return l.sightsGroupAmenity;
    case 'railway':
      return l.sightsGroupRailway;
    default:
      return category;
  }
}

String sightSubtypeLabel(AppLocalizations l, String subtype) {
  switch (subtype) {
    case 'attraction':
      return l.sightSubAttraction;
    case 'viewpoint':
      return l.sightSubViewpoint;
    case 'museum':
      return l.sightSubMuseum;
    case 'artwork':
      return l.sightSubArtwork;
    case 'picnic_site':
      return l.sightSubPicnicSite;
    case 'information':
      return l.sightSubInformation;
    case 'hotel':
      return l.sightSubHotel;
    case 'guest_house':
      return l.sightSubGuestHouse;
    case 'hostel':
      return l.sightSubHostel;
    case 'camp_site':
      return l.sightSubCampSite;
    case 'castle':
      return l.sightSubCastle;
    case 'monument':
      return l.sightSubMonument;
    case 'memorial':
      return l.sightSubMemorial;
    case 'ruins':
      return l.sightSubRuins;
    case 'archaeological_site':
      return l.sightSubArchaeological;
    case 'peak':
      return l.sightSubPeak;
    case 'waterfall':
      return l.sightSubWaterfall;
    case 'cave_entrance':
      return l.sightSubCave;
    case 'supermarket':
      return l.sightSubSupermarket;
    case 'bakery':
      return l.sightSubBakery;
    case 'convenience':
      return l.sightSubConvenience;
    case 'bicycle':
      return l.sightSubBicycleShop;
    case 'restaurant':
      return l.sightSubRestaurant;
    case 'cafe':
      return l.sightSubCafe;
    case 'fast_food':
      return l.sightSubFastFood;
    case 'biergarten':
      return l.sightSubBiergarten;
    case 'pub':
      return l.sightSubPub;
    case 'drinking_water':
      return l.sightSubDrinkingWater;
    case 'toilets':
      return l.sightSubToilets;
    case 'pharmacy':
      return l.sightSubPharmacy;
    case 'atm':
      return l.sightSubAtm;
    case 'bicycle_repair_station':
      return l.sightSubBicycleRepair;
    case 'bicycle_rental':
      return l.sightSubBicycleRental;
    case 'charging_station':
      return l.sightSubChargingStation;
    case 'station':
      return l.sightSubStation;
    case 'halt':
      return l.sightSubHalt;
    case 'tram_stop':
      return l.sightSubTramStop;
    default:
      return subtype;
  }
}

Set<String> get allSightTypes => {
      for (final entry in sightTypes.entries)
        for (final sub in entry.value) '${entry.key}:$sub',
    };

class OsmSight {
  final int id;
  final double lat;
  final double lon;
  final String category;
  final String subtype;
  final String? name;
  final String? wikipedia;
  final String? wikidata;
  final String? website;
  final String? description;
  final String? phone;
  final String? email;
  final String? openingHours;
  final String? fee;
  final String? charge;
  final String? wheelchair;
  final String? address;
  final String? image;
  final String? wikimediaCommons;
  final String? ele;
  final String? startDate;
  final String? heritage;
  final String? operator;
  final String? artist;
  final String? artworkType;
  final String? castleType;
  final String? material;

  const OsmSight({
    required this.id,
    required this.lat,
    required this.lon,
    required this.category,
    required this.subtype,
    this.name,
    this.wikipedia,
    this.wikidata,
    this.website,
    this.description,
    this.phone,
    this.email,
    this.openingHours,
    this.fee,
    this.charge,
    this.wheelchair,
    this.address,
    this.image,
    this.wikimediaCommons,
    this.ele,
    this.startDate,
    this.heritage,
    this.operator,
    this.artist,
    this.artworkType,
    this.castleType,
    this.material,
  });

  String displayName(AppLocalizations l) => name ?? sightSubtypeLabel(l, subtype);

  String localizedSubtype(AppLocalizations l) => sightSubtypeLabel(l, subtype);

  /// Direct image URL if available: prefers `image` tag, falls back to wikimedia_commons File:
  String? get imageUrl {
    if (image != null && image!.startsWith('http')) return image;
    final commons = wikimediaCommons ?? image;
    if (commons != null && commons.startsWith('File:')) {
      final fileName = Uri.encodeComponent(commons.substring(5));
      return 'https://commons.wikimedia.org/wiki/Special:FilePath/$fileName?width=600';
    }
    return null;
  }
}
