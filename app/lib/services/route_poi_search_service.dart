import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/route_poi.dart';

class RoutePoiHit {
  final int osmId;
  final String osmType;
  final PoiCategory category;
  final double lat;
  final double lon;
  final String? name;
  final String? subtype;
  final Map<String, String> tags;
  final double routeKm;
  final double sideMeters;

  const RoutePoiHit({
    required this.osmId,
    required this.osmType,
    required this.category,
    required this.lat,
    required this.lon,
    required this.routeKm,
    required this.sideMeters,
    required this.tags,
    this.name,
    this.subtype,
  });
}

class RoutePoiSearchService {
  static const String _baseUrl =
      'https://wegwiesel.app/overpass/api/interpreter';

  static const Map<PoiCategory, List<String>> _filters = {
    PoiCategory.fuel: ['[amenity=fuel]'],
    PoiCategory.charging: ['[amenity=charging_station]'],
    PoiCategory.shop: [
      '[shop~"^(supermarket|convenience|bakery|butcher|greengrocer|department_store|mall)\$"]',
    ],
    PoiCategory.sights: [
      '[tourism~"^(attraction|museum|monument|gallery|artwork|theme_park|zoo)\$"]',
      '[historic~"^(castle|monument|memorial|ruins|archaeological_site|fort)\$"]',
    ],
    PoiCategory.food: [
      '[amenity~"^(restaurant|cafe|fast_food|biergarten|ice_cream|pub)\$"]',
    ],
    PoiCategory.water: ['[amenity=drinking_water]'],
    PoiCategory.scenic: ['[tourism=viewpoint]'],
    PoiCategory.camping: ['[tourism~"^(camp_site|caravan_site)\$"]'],
    PoiCategory.lodging: [
      '[tourism~"^(hotel|motel|hostel|guest_house|bed_and_breakfast|apartment|chalet|alpine_hut|wilderness_hut)\$"]',
    ],
    PoiCategory.info: ['[tourism=information]'],
  };

  static Future<List<RoutePoiHit>> searchAlongRoute({
    required List<List<double>> coordinates, // [lon, lat, ...] from BRouter
    required Set<PoiCategory> categories,
    double corridorMeters = 1500,
  }) async {
    if (coordinates.isEmpty || categories.isEmpty) return const [];

    // Bbox with buffer matching the corridor.
    double minLat = coordinates.first[1];
    double maxLat = coordinates.first[1];
    double minLon = coordinates.first[0];
    double maxLon = coordinates.first[0];
    for (final c in coordinates) {
      final lat = c[1];
      final lon = c[0];
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lon < minLon) minLon = lon;
      if (lon > maxLon) maxLon = lon;
    }
    final midLat = (minLat + maxLat) / 2;
    final dLat = corridorMeters / 111320.0;
    final dLon = corridorMeters / (111320.0 * cos(midLat * pi / 180).abs());
    minLat -= dLat;
    maxLat += dLat;
    minLon -= dLon;
    maxLon += dLon;

    final bbox = '$minLat,$minLon,$maxLat,$maxLon';
    final buffer = StringBuffer('[out:json][timeout:30];(');
    for (final cat in categories) {
      final filters = _filters[cat];
      if (filters == null) continue;
      for (final f in filters) {
        buffer.write('node$f($bbox);');
        buffer.write('way$f($bbox);');
      }
    }
    buffer.write(');out center tags;');

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          body: {'data': buffer.toString()},
          headers: {'User-Agent': 'Wegwiesel/1.0 (wegwiesel.app)'},
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw Exception('Overpass failed: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (data['elements'] as List).cast<Map<String, dynamic>>();

    // Cumulative kilometers along the route, indexed per coordinate.
    final cumKm = List<double>.filled(coordinates.length, 0);
    for (int i = 1; i < coordinates.length; i++) {
      cumKm[i] = cumKm[i - 1] +
          _haversineKm(
            coordinates[i - 1][1],
            coordinates[i - 1][0],
            coordinates[i][1],
            coordinates[i][0],
          );
    }

    final seen = <String>{};
    final out = <RoutePoiHit>[];
    for (final e in elements) {
      double? lat;
      double? lon;
      if (e['type'] == 'node') {
        lat = (e['lat'] as num?)?.toDouble();
        lon = (e['lon'] as num?)?.toDouble();
      } else {
        final center = e['center'] as Map?;
        lat = (center?['lat'] as num?)?.toDouble();
        lon = (center?['lon'] as num?)?.toDouble();
      }
      if (lat == null || lon == null) continue;

      final tagsRaw = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
      final tags = tagsRaw.map((k, v) => MapEntry(k, v.toString()));
      final cat = _classify(tags);
      if (cat == null || !categories.contains(cat)) continue;

      final id = e['id'] as int;
      final osmType = e['type'] as String;
      final key = '$osmType/$id';
      if (!seen.add(key)) continue;

      // Nearest coordinate index along the route.
      double bestSq = double.infinity;
      int bestIdx = 0;
      for (int i = 0; i < coordinates.length; i++) {
        final dla = coordinates[i][1] - lat;
        final dlo = coordinates[i][0] - lon;
        final sq = dla * dla + dlo * dlo;
        if (sq < bestSq) {
          bestSq = sq;
          bestIdx = i;
        }
      }
      final side = _haversineKm(lat, lon,
              coordinates[bestIdx][1], coordinates[bestIdx][0]) *
          1000;
      if (side > corridorMeters) continue;

      out.add(RoutePoiHit(
        osmId: id,
        osmType: osmType,
        category: cat,
        lat: lat,
        lon: lon,
        name: tags['name'],
        subtype: tags[_primaryTagKey(cat)],
        tags: tags,
        routeKm: cumKm[bestIdx],
        sideMeters: side,
      ));
    }
    out.sort((a, b) => a.routeKm.compareTo(b.routeKm));
    return out;
  }

  static PoiCategory? _classify(Map<String, String> tags) {
    final amenity = tags['amenity'];
    if (amenity == 'fuel') return PoiCategory.fuel;
    if (amenity == 'charging_station') return PoiCategory.charging;
    if (amenity == 'drinking_water') return PoiCategory.water;
    if (amenity == 'restaurant' ||
        amenity == 'cafe' ||
        amenity == 'fast_food' ||
        amenity == 'biergarten' ||
        amenity == 'ice_cream' ||
        amenity == 'pub') {
      return PoiCategory.food;
    }

    final shop = tags['shop'];
    if (shop != null) return PoiCategory.shop;

    final tourism = tags['tourism'];
    if (tourism == 'viewpoint') return PoiCategory.scenic;
    if (tourism == 'information') return PoiCategory.info;
    if (tourism == 'camp_site' || tourism == 'caravan_site') {
      return PoiCategory.camping;
    }
    if (tourism == 'hotel' ||
        tourism == 'motel' ||
        tourism == 'hostel' ||
        tourism == 'guest_house' ||
        tourism == 'bed_and_breakfast' ||
        tourism == 'apartment' ||
        tourism == 'chalet' ||
        tourism == 'alpine_hut' ||
        tourism == 'wilderness_hut') {
      return PoiCategory.lodging;
    }
    if (tourism == 'attraction' ||
        tourism == 'museum' ||
        tourism == 'monument' ||
        tourism == 'gallery' ||
        tourism == 'artwork' ||
        tourism == 'theme_park' ||
        tourism == 'zoo') {
      return PoiCategory.sights;
    }

    if (tags['historic'] != null) return PoiCategory.sights;

    return null;
  }

  static String _primaryTagKey(PoiCategory cat) {
    switch (cat) {
      case PoiCategory.fuel:
      case PoiCategory.charging:
      case PoiCategory.water:
      case PoiCategory.food:
        return 'amenity';
      case PoiCategory.shop:
        return 'shop';
      case PoiCategory.sights:
      case PoiCategory.scenic:
      case PoiCategory.camping:
      case PoiCategory.lodging:
      case PoiCategory.info:
        return 'tourism';
      case PoiCategory.other:
        return 'name';
    }
  }

  static double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
