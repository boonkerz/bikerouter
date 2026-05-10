import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Snaps a coordinate to the nearest publicly drivable road.
///
/// The geocoder regularly drops pins inside private grounds — campsites
/// behind gates, factory yards, parks. BRouter's car profile then says
/// "target island failed". Pre-snapping every car waypoint to the nearest
/// `highway=*` way that allows motor vehicles avoids this entirely.
class RoadSnapService {
  static String overpassUrl = kIsWeb
      ? '/overpass/api/interpreter'
      : 'https://wegwiesel.app/overpass/api/interpreter';

  /// Returns [lat, lon] of the nearest publicly drivable road within
  /// [searchRadiusM] metres. Returns null if nothing matches or Overpass
  /// is unreachable (in which case the caller should fall back to the
  /// original coordinate).
  static Future<List<double>?> snap(
    double lat,
    double lon, {
    int searchRadiusM = 300,
  }) async {
    final query = '''
[out:json][timeout:10];
way(around:$searchRadiusM,$lat,$lon)
  ["highway"~"^(motorway|motorway_link|trunk|trunk_link|primary|primary_link|secondary|secondary_link|tertiary|tertiary_link|unclassified|residential|service|living_street)\$"]
  ["access"!~"^(no|private|forestry|agricultural)\$"]
  ["motor_vehicle"!~"^(no|private)\$"]
  ["motorcar"!~"^(no|private)\$"];
node(w);
out;
''';
    try {
      final response = await http
          .post(
            Uri.parse(overpassUrl),
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = json['elements'] as List?;
      if (elements == null || elements.isEmpty) return null;

      double bestD = double.infinity;
      double bestLat = lat;
      double bestLon = lon;
      for (final el in elements) {
        if (el is! Map) continue;
        if (el['type'] != 'node') continue;
        final eLat = (el['lat'] as num?)?.toDouble();
        final eLon = (el['lon'] as num?)?.toDouble();
        if (eLat == null || eLon == null) continue;
        final d = _haversineM(lat, lon, eLat, eLon);
        if (d < bestD) {
          bestD = d;
          bestLat = eLat;
          bestLon = eLon;
        }
      }
      if (bestD == double.infinity) return null;
      return [bestLat, bestLon];
    } catch (_) {
      return null;
    }
  }

  static double _haversineM(double a, double b, double c, double d) {
    const r = 6371000.0;
    final dLat = (c - a) * pi / 180;
    final dLon = (d - b) * pi / 180;
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(a * pi / 180) *
            cos(c * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return 2 * r * asin(sqrt(h));
  }
}
