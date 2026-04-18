import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class Accommodation {
  final int id;
  final String type; // hotel, guest_house, hostel, camp_site, etc.
  final double lat;
  final double lon;
  final String? name;
  final String? website;
  final String? phone;
  final String? stars;
  final double distanceKm;

  const Accommodation({
    required this.id,
    required this.type,
    required this.lat,
    required this.lon,
    required this.distanceKm,
    this.name,
    this.website,
    this.phone,
    this.stars,
  });

  String get emoji {
    switch (type) {
      case 'hotel':
        return '🏨';
      case 'motel':
        return '🏨';
      case 'hostel':
        return '🛏️';
      case 'guest_house':
      case 'bed_and_breakfast':
        return '🏡';
      case 'apartment':
        return '🏢';
      case 'chalet':
        return '🏔️';
      case 'alpine_hut':
      case 'wilderness_hut':
        return '⛰️';
      case 'camp_site':
        return '⛺';
      case 'caravan_site':
        return '🚐';
      default:
        return '🏠';
    }
  }

  String get typeLabel {
    const labels = {
      'hotel': 'Hotel',
      'motel': 'Motel',
      'hostel': 'Hostel',
      'guest_house': 'Pension',
      'bed_and_breakfast': 'B&B',
      'apartment': 'Ferienwohnung',
      'chalet': 'Chalet',
      'alpine_hut': 'Berghütte',
      'wilderness_hut': 'Schutzhütte',
      'camp_site': 'Campingplatz',
      'caravan_site': 'Wohnmobilplatz',
    };
    return labels[type] ?? type;
  }
}

class AccommodationService {
  static const String baseUrl = 'https://wegwiesel.app/overpass/api/interpreter';

  static Future<List<Accommodation>> findNear(
    double lat,
    double lon, {
    double radiusMeters = 5000,
  }) async {
    final query = '''
[out:json][timeout:25];
(
  node["tourism"~"^(hotel|motel|hostel|guest_house|bed_and_breakfast|apartment|chalet|alpine_hut|wilderness_hut|camp_site|caravan_site)\$"](around:$radiusMeters,$lat,$lon);
  way["tourism"~"^(hotel|motel|hostel|guest_house|bed_and_breakfast|apartment|chalet|alpine_hut|wilderness_hut|camp_site|caravan_site)\$"](around:$radiusMeters,$lat,$lon);
);
out center tags;
''';
    final response = await http.post(
      Uri.parse(baseUrl),
      body: {'data': query},
      headers: {'User-Agent': 'Wegwiesel/1.0 (wegwiesel.app)'},
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Overpass failed: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (data['elements'] as List).cast<Map<String, dynamic>>();
    final result = <Accommodation>[];
    for (final e in elements) {
      double? eLat;
      double? eLon;
      if (e['type'] == 'node') {
        eLat = (e['lat'] as num?)?.toDouble();
        eLon = (e['lon'] as num?)?.toDouble();
      } else {
        final center = e['center'] as Map?;
        eLat = (center?['lat'] as num?)?.toDouble();
        eLon = (center?['lon'] as num?)?.toDouble();
      }
      if (eLat == null || eLon == null) continue;
      final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
      final type = tags['tourism'] as String?;
      if (type == null) continue;
      result.add(Accommodation(
        id: (e['id'] as num).toInt(),
        type: type,
        lat: eLat,
        lon: eLon,
        name: tags['name'] as String?,
        website: (tags['website'] ?? tags['contact:website'] ?? tags['url']) as String?,
        phone: (tags['phone'] ?? tags['contact:phone']) as String?,
        stars: tags['stars'] as String?,
        distanceKm: _haversine(lat, lon, eLat, eLon),
      ));
    }
    result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return result;
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
