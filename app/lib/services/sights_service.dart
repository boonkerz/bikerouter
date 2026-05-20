import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/osm_sight.dart';
import 'poi_image_resolver.dart';

class SightsService {
  static const String baseUrl = 'https://wegwiesel.app/overpass/api/interpreter';

  static Future<List<OsmSight>> fetchAlongRoute(
    List<LatLng> route, {
    // Wide enough to catch landmarks in the neighbouring village (a real
    // user complaint surfaced for Schloss Ranzin), still narrow enough
    // that city-centre searches don't drown in food/shops.
    double bufferMeters = 1500,
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
    // Query both nodes AND ways — castles, museums and many landmarks are
    // mapped as building-outline ways rather than POI nodes. `out center`
    // gives the way's centroid lat/lon so we can render it as a point.
    final filters = byCategory.entries
        .expand((e) => [
              '  node["${e.key}"~"${e.value.join('|')}"]($bbox);',
              '  way["${e.key}"~"${e.value.join('|')}"]($bbox);',
            ])
        .join('\n');

    final query = '''
[out:json][timeout:25];
(
$filters
);
out center body;
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
    final nearby = all.where((s) => _minDistToRoute(s, route) <= bufMeters).toList();
    return _resolveCommonsThumbs(nearby);
  }

  /// Replaces wikimedia_commons-derived URLs with CORS-friendly direct
  /// upload.wikimedia.org thumbnails via MediaWiki's imageinfo API. Runs
  /// in one batched call regardless of how many sights are involved.
  /// Sights without a usable Commons tag pass through untouched.
  static Future<List<OsmSight>> _resolveCommonsThumbs(List<OsmSight> sights) async {
    final commonsValues = <String>{};
    for (final s in sights) {
      final c = s.wikimediaCommons;
      if (c != null && c.startsWith('File:')) commonsValues.add(c);
      // Some POIs put the File:... reference into `image=` instead of
      // wikimedia_commons=; treat those identically.
      final img = s.image;
      if (img != null && img.startsWith('File:')) commonsValues.add(img);
    }
    if (commonsValues.isEmpty) return sights;
    Map<String, String> resolved;
    try {
      resolved = await PoiImageResolver.resolveCommonsBatch(commonsValues);
    } catch (_) {
      return sights;
    }
    if (resolved.isEmpty) return sights;
    return [
      for (final s in sights)
        () {
          final tag = s.wikimediaCommons ?? s.image;
          final url = tag == null ? null : resolved[tag];
          return url == null ? s : s.withDirectImageUrl(url);
        }(),
    ];
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

    // Nodes carry lat/lon directly; ways (and relations) only have a
    // server-computed `center` block. Read whichever exists.
    final centerMap = e['center'] as Map?;
    final lat = (e['lat'] ?? centerMap?['lat']) as num?;
    final lon = (e['lon'] ?? centerMap?['lon']) as num?;
    if (lat == null || lon == null) return null;
    return OsmSight(
      id: (e['id'] as num).toInt(),
      lat: lat.toDouble(),
      lon: lon.toDouble(),
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
