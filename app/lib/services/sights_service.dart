import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/osm_sight.dart';

class SightsService {
  static const String baseUrl = 'https://wegwiesel.app/overpass/api/interpreter';

  static Future<List<OsmSight>> fetchAlongRoute(
    List<LatLng> route, {
    double bufferMeters = 300,
    Set<String>? enabledTypes,
  }) async {
    if (route.isEmpty) return [];
    final types = enabledTypes ?? allSightTypes;
    if (types.isEmpty) return [];

    double minLat = route.first.latitude;
    double maxLat = route.first.latitude;
    double minLon = route.first.longitude;
    double maxLon = route.first.longitude;
    for (final p in route) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    // Buffer bbox by bufferMeters (approx)
    final latBuf = bufferMeters / 111000;
    final lonBuf = bufferMeters / (111000 * cos(minLat * pi / 180));
    minLat -= latBuf; maxLat += latBuf;
    minLon -= lonBuf; maxLon += lonBuf;

    final byCategory = <String, List<String>>{};
    for (final t in types) {
      final parts = t.split(':');
      if (parts.length != 2) continue;
      byCategory.putIfAbsent(parts[0], () => []).add(parts[1]);
    }
    final bbox = '$minLat,$minLon,$maxLat,$maxLon';
    final filters = byCategory.entries
        .map((e) => '  node["${e.key}"~"${e.value.join('|')}"]($bbox);')
        .join('\n');

    final query = '''
[out:json][timeout:25];
(
$filters
);
out body;
''';

    final response = await http.post(
      Uri.parse(baseUrl),
      body: {'data': query},
      headers: {'User-Agent': 'Wegwiesel/1.0 (wegwiesel.app)'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Overpass failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (data['elements'] as List).cast<Map<String, dynamic>>();

    final all = elements.map(_parseElement).whereType<OsmSight>().toList();

    // Filter by proximity to actual route polyline
    final bufMeters = bufferMeters;
    return all.where((s) => _minDistToRoute(s, route) <= bufMeters).toList();
  }

  static OsmSight? _parseElement(Map<String, dynamic> e) {
    final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
    String? category;
    String? subtype;
    for (final cat in sightTypes.keys) {
      final v = tags[cat];
      if (v is String && sightTypes[cat]!.contains(v)) {
        category = cat;
        subtype = v;
        break;
      }
    }
    if (category == null || subtype == null) return null;

    final addrParts = <String>[];
    final street = tags['addr:street'] as String?;
    final house = tags['addr:housenumber'] as String?;
    if (street != null) addrParts.add(house != null ? '$street $house' : street);
    final postcode = tags['addr:postcode'] as String?;
    final city = tags['addr:city'] as String?;
    if (postcode != null || city != null) {
      addrParts.add([postcode, city].whereType<String>().join(' '));
    }

    return OsmSight(
      id: (e['id'] as num).toInt(),
      lat: (e['lat'] as num).toDouble(),
      lon: (e['lon'] as num).toDouble(),
      category: category,
      subtype: subtype,
      name: (tags['name:de'] ?? tags['name']) as String?,
      wikipedia: tags['wikipedia'] as String?,
      wikidata: tags['wikidata'] as String?,
      website: (tags['website'] ?? tags['contact:website'] ?? tags['url']) as String?,
      description: (tags['description:de'] ?? tags['description']) as String?,
      phone: (tags['phone'] ?? tags['contact:phone']) as String?,
      email: (tags['email'] ?? tags['contact:email']) as String?,
      openingHours: tags['opening_hours'] as String?,
      fee: tags['fee'] as String?,
      charge: tags['charge'] as String?,
      wheelchair: tags['wheelchair'] as String?,
      address: addrParts.isEmpty ? null : addrParts.join(', '),
      image: tags['image'] as String?,
      wikimediaCommons: tags['wikimedia_commons'] as String?,
      ele: tags['ele'] as String?,
      startDate: tags['start_date'] as String?,
      heritage: tags['heritage'] as String?,
      operator: tags['operator'] as String?,
      artist: tags['artist_name'] as String?,
      artworkType: tags['artwork_type'] as String?,
      castleType: tags['castle_type'] as String?,
      material: tags['material'] as String?,
    );
  }

  static double _minDistToRoute(OsmSight s, List<LatLng> route) {
    double best = double.infinity;
    final sp = LatLng(s.lat, s.lon);
    for (var i = 0; i < route.length - 1; i++) {
      final d = _distToSegment(sp, route[i], route[i + 1]);
      if (d < best) best = d;
    }
    return best;
  }

  static double _distToSegment(LatLng p, LatLng a, LatLng b) {
    const dist = Distance();
    final dAB = dist.as(LengthUnit.Meter, a, b);
    if (dAB < 0.01) return dist.as(LengthUnit.Meter, p, a);
    final dAP = dist.as(LengthUnit.Meter, a, p);
    final dBP = dist.as(LengthUnit.Meter, b, p);
    // Project p onto line AB
    final ax = a.longitude, ay = a.latitude;
    final bx = b.longitude, by = b.latitude;
    final px = p.longitude, py = p.latitude;
    final t = ((px - ax) * (bx - ax) + (py - ay) * (by - ay)) /
        ((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
    if (t < 0) return dAP;
    if (t > 1) return dBP;
    final projX = ax + t * (bx - ax);
    final projY = ay + t * (by - ay);
    return dist.as(LengthUnit.Meter, p, LatLng(projY, projX));
  }
}
