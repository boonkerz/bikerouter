/// All OSM POI types we support, grouped by category. Each entry: subtype → German label.
const Map<String, Map<String, String>> sightTypes = {
  'tourism': {
    'attraction': 'Sehenswürdigkeit',
    'viewpoint': 'Aussichtspunkt',
    'museum': 'Museum',
    'artwork': 'Kunstwerk',
    'picnic_site': 'Picknickplatz',
    'information': 'Touristen-Info',
    'hotel': 'Hotel',
    'guest_house': 'Pension',
    'hostel': 'Hostel',
    'camp_site': 'Campingplatz',
  },
  'historic': {
    'castle': 'Burg/Schloss',
    'monument': 'Denkmal',
    'memorial': 'Gedenkstätte',
    'ruins': 'Ruine',
    'archaeological_site': 'Archäologische Stätte',
  },
  'natural': {
    'peak': 'Gipfel',
    'waterfall': 'Wasserfall',
    'cave_entrance': 'Höhle',
  },
  'shop': {
    'supermarket': 'Supermarkt',
    'bakery': 'Bäckerei',
    'convenience': 'Kiosk/Späti',
    'bicycle': 'Fahrradladen',
  },
  'amenity': {
    'restaurant': 'Restaurant',
    'cafe': 'Café',
    'fast_food': 'Imbiss',
    'biergarten': 'Biergarten',
    'pub': 'Kneipe',
    'drinking_water': 'Trinkwasser',
    'toilets': 'Toilette',
    'pharmacy': 'Apotheke',
    'atm': 'Geldautomat',
    'bicycle_repair_station': 'Fahrrad-Reparaturstation',
    'bicycle_rental': 'Fahrradverleih',
    'charging_station': 'Ladesäule',
  },
  'railway': {
    'station': 'Bahnhof',
    'halt': 'Haltepunkt',
    'tram_stop': 'Straßenbahn-Halt',
  },
};

const Map<String, String> sightCategoryLabels = {
  'tourism': 'Tourismus',
  'historic': 'Historisch',
  'natural': 'Natur',
  'shop': 'Einkauf',
  'amenity': 'Versorgung',
  'railway': 'Bahn',
};

Set<String> get allSightTypes => {
      for (final entry in sightTypes.entries)
        for (final sub in entry.value.keys) '${entry.key}:$sub',
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

  String get displayName => name ?? subtypeLabel;

  String get subtypeLabel =>
      sightTypes[category]?[subtype] ?? subtype;

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
