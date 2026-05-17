import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class Stage {
  final int index; // 1-based stage number
  final int startCoordIdx;
  final int endCoordIdx;
  final double startKm;
  final double endKm;
  final double ascentM;
  final double lat; // endpoint
  final double lon;
  final String? townName;
  final String? nearestPlaceType;

  const Stage({
    required this.index,
    required this.startCoordIdx,
    required this.endCoordIdx,
    required this.startKm,
    required this.endKm,
    required this.ascentM,
    required this.lat,
    required this.lon,
    this.townName,
    this.nearestPlaceType,
  });

  double get lengthKm => endKm - startKm;
}

class StagePlanner {
  static const String overpassUrl = 'https://wegwiesel.app/overpass/api/interpreter';

  /// Splits a route into day stages of approximately [targetKm] each.
  /// For each stage end, finds the nearest OSM place (town/village) within
  /// [placeRadiusMeters] and snaps the endpoint to it.
  static Future<List<Stage>> plan({
    required List<List<double>> coordinates, // [lon, lat, elev]
    required double targetKm,
    double placeRadiusMeters = 8000,
  }) async {
    if (coordinates.length < 2 || targetKm <= 0) return const [];

    final cumKm = <double>[0];
    for (int i = 1; i < coordinates.length; i++) {
      cumKm.add(cumKm.last + _haversine(coordinates[i - 1], coordinates[i]));
    }
    final total = cumKm.last;
    if (total <= 0) return const [];

    final stageCount = max(1, (total / targetKm).round());
    if (stageCount == 1) {
      final ascent = _ascent(coordinates, 0, coordinates.length - 1);
      final end = coordinates.last;
      final place = await _findNearestPlace(end[1], end[0], placeRadiusMeters);
      return [
        Stage(
          index: 1,
          startCoordIdx: 0,
          endCoordIdx: coordinates.length - 1,
          startKm: 0,
          endKm: total,
          ascentM: ascent,
          lat: end[1],
          lon: end[0],
          townName: place?.name,
          nearestPlaceType: place?.type,
        ),
      ];
    }

    final stages = <Stage>[];
    int prevIdx = 0;
    double prevKm = 0;

    for (int n = 1; n <= stageCount; n++) {
      final targetCum = total * n / stageCount;
      int endIdx;
      if (n == stageCount) {
        endIdx = coordinates.length - 1;
      } else {
        endIdx = _findIdxForDistance(cumKm, targetCum);
      }

      // Try to snap endpoint to a nearby town; if found, use its route index.
      final anchor = coordinates[endIdx];
      final place = n == stageCount
          ? await _findNearestPlace(anchor[1], anchor[0], placeRadiusMeters)
          : await _findNearestPlace(anchor[1], anchor[0], placeRadiusMeters);

      double endLat = anchor[1];
      double endLon = anchor[0];

      if (place != null && n != stageCount) {
        // Snap to nearest route coord to the place.
        final snapIdx = _nearestRouteIdx(coordinates, place.lat, place.lon);
        if (snapIdx > prevIdx && snapIdx < coordinates.length - 1) {
          endIdx = snapIdx;
          endLat = coordinates[endIdx][1];
          endLon = coordinates[endIdx][0];
        }
      }

      final startKm = prevKm;
      final endKm = cumKm[endIdx];
      final ascent = _ascent(coordinates, prevIdx, endIdx);

      stages.add(Stage(
        index: n,
        startCoordIdx: prevIdx,
        endCoordIdx: endIdx,
        startKm: startKm,
        endKm: endKm,
        ascentM: ascent,
        lat: endLat,
        lon: endLon,
        townName: place?.name,
        nearestPlaceType: place?.type,
      ));
      prevIdx = endIdx;
      prevKm = endKm;
    }
    return stages;
  }

  static int _findIdxForDistance(List<double> cumKm, double target) {
    for (int i = 0; i < cumKm.length; i++) {
      if (cumKm[i] >= target) return i;
    }
    return cumKm.length - 1;
  }

  static int _nearestRouteIdx(List<List<double>> coords, double lat, double lon) {
    int best = 0;
    double bestD = double.infinity;
    for (int i = 0; i < coords.length; i++) {
      final d = _haversine([lon, lat, 0], coords[i]);
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  static double _ascent(List<List<double>> coords, int from, int to) {
    double a = 0;
    for (int i = from + 1; i <= to && i < coords.length; i++) {
      final diff = coords[i][2] - coords[i - 1][2];
      if (diff > 0) a += diff;
    }
    return a;
  }

  static Future<_Place?> _findNearestPlace(
    double lat,
    double lon,
    double radiusMeters,
  ) async {
    final query = '''
[out:json][timeout:20];
(
  node["place"~"^(city|town|village)\$"](around:$radiusMeters,$lat,$lon);
);
out;
''';
    try {
      final r = await http.post(
        Uri.parse(overpassUrl),
        body: {'data': query},
        headers: {'User-Agent': 'Wegwiesel/1.0 (wegwiesel.app)'},
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return null;
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final elements = (data['elements'] as List).cast<Map<String, dynamic>>();
      _Place? best;
      double bestD = double.infinity;
      for (final e in elements) {
        final eLat = (e['lat'] as num?)?.toDouble();
        final eLon = (e['lon'] as num?)?.toDouble();
        final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
        final name = tags['name'] as String?;
        final type = tags['place'] as String?;
        if (eLat == null || eLon == null || name == null || type == null) continue;
        final d = _haversine([lon, lat, 0], [eLon, eLat, 0]);
        // Prefer towns over villages when close enough — weight by type.
        final weight = switch (type) {
          'city' => 0.5,
          'town' => 0.75,
          _ => 1.0,
        };
        final score = d * weight;
        if (score < bestD) {
          bestD = score;
          best = _Place(name, eLat, eLon, type);
        }
      }
      return best;
    } catch (_) {
      return null;
    }
  }

  static double _haversine(List<double> a, List<double> b) {
    const r = 6371.0;
    final dLat = (b[1] - a[1]) * pi / 180;
    final dLon = (b[0] - a[0]) * pi / 180;
    final lat1 = a[1] * pi / 180;
    final lat2 = b[1] * pi / 180;
    final x = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(x), sqrt(1 - x));
  }
}

class _Place {
  final String name;
  final double lat;
  final double lon;
  final String type;
  _Place(this.name, this.lat, this.lon, this.type);
}

/// A suggested overnight stop near a stage endpoint. Ranked by category
/// (camping cheaper-than-hotel for bikepackers) and then by distance.
class OvernightAnchor {
  /// OSM `tourism=...` value: camp_site, alpine_hut, wilderness_hut, hostel, hotel, guest_house.
  final String type;
  final String? name;
  final double lat;
  final double lon;
  final double distanceMeters;

  const OvernightAnchor({
    required this.type,
    required this.name,
    required this.lat,
    required this.lon,
    required this.distanceMeters,
  });
}

class OvernightAnchorFinder {
  static const String overpassUrl = 'https://wegwiesel.app/overpass/api/interpreter';

  /// Searches a single Overpass query around [lat]/[lon] for camping/hut/
  /// hostel/hotel POIs and returns the best-ranked one (or null if none).
  static Future<OvernightAnchor?> findNear({
    required double lat,
    required double lon,
    double radiusMeters = 5000,
  }) async {
    final query = '''
[out:json][timeout:20];
(
  node["tourism"~"^(camp_site|alpine_hut|wilderness_hut|hostel|hotel|guest_house)\$"](around:$radiusMeters,$lat,$lon);
  way["tourism"~"^(camp_site|alpine_hut|wilderness_hut|hostel|hotel|guest_house)\$"](around:$radiusMeters,$lat,$lon);
);
out center tags;
''';
    try {
      final r = await http.post(
        Uri.parse(overpassUrl),
        body: {'data': query},
        headers: {'User-Agent': 'Wegwiesel/1.0 (wegwiesel.app)'},
      ).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return null;
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final elements = (data['elements'] as List).cast<Map<String, dynamic>>();
      OvernightAnchor? best;
      double bestScore = double.infinity;
      for (final e in elements) {
        double? eLat;
        double? eLon;
        if (e['type'] == 'node') {
          eLat = (e['lat'] as num?)?.toDouble();
          eLon = (e['lon'] as num?)?.toDouble();
        } else {
          final c = e['center'] as Map?;
          eLat = (c?['lat'] as num?)?.toDouble();
          eLon = (c?['lon'] as num?)?.toDouble();
        }
        final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
        final type = tags['tourism'] as String?;
        if (eLat == null || eLon == null || type == null) continue;
        // Distance in meters via haversine; the stage_planner.dart helper
        // expects [lon, lat, _] triples, hence the throwaway 0 elevation.
        final d = StagePlanner._haversine([lon, lat, 0], [eLon, eLat, 0]) * 1000;
        // Rank: cheaper overnight types beat fancier ones, then closer beats
        // farther. Camping is 1.0, hostels 1.5, hotels 2.5.
        final categoryWeight = switch (type) {
          'camp_site' || 'alpine_hut' || 'wilderness_hut' => 1.0,
          'hostel' => 1.5,
          _ => 2.5,
        };
        final score = d * categoryWeight;
        if (score < bestScore) {
          bestScore = score;
          best = OvernightAnchor(
            type: type,
            name: tags['name'] as String?,
            lat: eLat,
            lon: eLon,
            distanceMeters: d,
          );
        }
      }
      return best;
    } catch (_) {
      return null;
    }
  }
}
