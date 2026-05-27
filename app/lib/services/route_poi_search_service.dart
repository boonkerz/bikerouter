import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/route_poi.dart';
import 'poi_image_resolver.dart';

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
  /// Pre-resolved thumbnail URL: filled in by the search service via
  /// PoiImageResolver (image=/wikimedia_commons=) plus an optional
  /// Wikipedia PageImages batch lookup. Callers should prefer this
  /// over re-resolving from [tags] so they get the wikipedia fallback
  /// for free.
  final String? imageUrl;

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
    this.imageUrl,
  });

  RoutePoiHit withImageUrl(String? url) => RoutePoiHit(
        osmId: osmId,
        osmType: osmType,
        category: category,
        lat: lat,
        lon: lon,
        routeKm: routeKm,
        sideMeters: sideMeters,
        tags: tags,
        name: name,
        subtype: subtype,
        imageUrl: url,
      );
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
      // Match any historic-tagged feature — there's a long tail of niche
      // values (tower, manor, palace, fortified_house, wayside_cross,
      // citywalls, battlefield, …) that we'd otherwise miss. _classify
      // already handles "any historic" so this just widens the dragnet.
      '[historic]',
      // Some castles in the wild are only tagged with castle_type=…
      // (defensive, manor, palace, …) without historic=castle. Pick
      // those up too — the classify pass groups them under sights.
      '[castle_type]',
      // Place-of-worship buildings are sometimes only tagged via
      // building=cathedral|chapel|church|… without amenity coverage.
      '[building~"^(cathedral|chapel|church|temple|mosque|synagogue|castle)\$"]',
    ],
    PoiCategory.food: [
      '[amenity~"^(restaurant|cafe|fast_food|biergarten|ice_cream|pub)\$"]',
    ],
    // Drinking water in all forms hikers/runners/bikepackers actually
    // rely on: public taps (drinking_water, water_point), private taps
    // marked drinkable (man_made=water_tap with drinking_water=yes),
    // and springs explicitly tagged as drinkable. We deliberately skip
    // amenity=fountain because most decorative fountains are *not*
    // drinkable in DE.
    PoiCategory.water: [
      '[amenity=drinking_water]',
      '[amenity=water_point]',
      '[man_made=water_tap][drinking_water=yes]',
      '[natural=spring][drinking_water=yes]',
      '[man_made=water_well][drinking_water=yes]',
    ],
    PoiCategory.scenic: ['[tourism=viewpoint]'],
    PoiCategory.shelter: [
      // tourism-tagged huts (alpine + wilderness) are full POIs; amenity=shelter
      // also covers picnic-shelters and rain shelters but we filter out bus
      // stops in _classify.
      '[tourism~"^(alpine_hut|wilderness_hut)\$"]',
      '[amenity=shelter][shelter_type!~"^public_transport\$"]',
    ],
    PoiCategory.picnic: ['[tourism=picnic_site]'],
    // camp_pitch is the OSM tag for informal/wild-ish pitches (individual
    // tent spots, often outside formal sites). Their density in Germany is
    // low so bundling them under "camping" doesn't pollute the result list,
    // and bikepackers explicitly want to see them in the same view.
    PoiCategory.camping: [
      '[tourism~"^(camp_site|caravan_site|camp_pitch)\$"]',
    ],
    PoiCategory.station: [
      // Mainline train stations + tram/light-rail stops + bus stations.
      // Halt-only entries (railway=halt) are tiny request-only stops and
      // typically what bikepackers actually rely on for a quick escape.
      '[railway~"^(station|halt)\$"]',
      '[public_transport=station]',
    ],
    PoiCategory.lodging: [
      // alpine_hut/wilderness_hut are intentionally excluded — they now have
      // their own PoiCategory.shelter so hikers can pick "rest huts" without
      // pulling in every hotel along the route.
      '[tourism~"^(hotel|motel|hostel|guest_house|bed_and_breakfast|apartment|chalet)\$"]',
    ],
    PoiCategory.info: ['[tourism=information]'],
  };

  static Future<List<RoutePoiHit>> searchAlongRoute({
    required List<List<double>> coordinates, // [lon, lat, ...] from BRouter
    required Set<PoiCategory> categories,
    // The corridor governs both the bbox padding for the Overpass query
    // and a post-filter that drops hits whose nearest-route-vertex
    // distance exceeds it. 2.5 km is wide enough that "ich fahr durchs
    // Nachbardorf"-cases catch the local landmark without flooding the
    // list in dense city centres (where the per-category filters already
    // do most of the trimming).
    double corridorMeters = 2500,
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
    return _enrichWithImages(out);
  }

  /// Three-pass image resolution:
  /// 1. Sync from `image=https://…` URLs (the only safe synchronous source
  ///    now that Special:FilePath is gone — it didn't carry CORS headers).
  /// 2. Batched Commons `imageinfo` API lookup for `wikimedia_commons=File:…`
  ///    (and `image=File:…`) tags → direct upload.wikimedia.org thumbs.
  /// 3. Batched MediaWiki PageImages API lookup for `wikipedia=lang:Title`
  ///    tags that still lack a photo.
  static Future<List<RoutePoiHit>> _enrichWithImages(
      List<RoutePoiHit> hits) async {
    final commonsRefs = <String>{};
    final synced = <RoutePoiHit>[];
    for (final h in hits) {
      final url = PoiImageResolver.resolve(h.tags);
      synced.add(url == null ? h : h.withImageUrl(url));
      if (url == null) {
        final ref = PoiImageResolver.extractCommonsReference(h.tags);
        if (ref != null) commonsRefs.add(ref);
      }
    }

    Map<String, String> commonsResolved = const {};
    if (commonsRefs.isNotEmpty) {
      try {
        commonsResolved =
            await PoiImageResolver.resolveCommonsBatch(commonsRefs);
      } catch (_) {}
    }

    final afterCommons = synced
        .map((h) {
          if (h.imageUrl != null) return h;
          final ref = PoiImageResolver.extractCommonsReference(h.tags);
          final url = ref == null ? null : commonsResolved[ref];
          return url == null ? h : h.withImageUrl(url);
        })
        .toList();

    final wikipediaTags = <String>{};
    for (final h in afterCommons) {
      if (h.imageUrl != null) continue;
      final wp = h.tags['wikipedia'];
      if (wp != null && wp.isNotEmpty) wikipediaTags.add(wp);
    }
    if (wikipediaTags.isEmpty) return afterCommons;

    Map<String, String> wikipediaResolved;
    try {
      wikipediaResolved =
          await PoiImageResolver.resolveWikipediaBatchWithFallback(wikipediaTags);
    } catch (_) {
      return afterCommons;
    }
    if (wikipediaResolved.isEmpty) return afterCommons;
    return afterCommons
        .map((h) {
          if (h.imageUrl != null) return h;
          final wp = h.tags['wikipedia'];
          if (wp == null) return h;
          final url = wikipediaResolved[wp];
          return url == null ? h : h.withImageUrl(url);
        })
        .toList();
  }

  static PoiCategory? _classify(Map<String, String> tags) {
    final railway = tags['railway'];
    if (railway == 'station' || railway == 'halt') return PoiCategory.station;
    if (tags['public_transport'] == 'station') return PoiCategory.station;

    final amenity = tags['amenity'];
    if (amenity == 'fuel') return PoiCategory.fuel;
    if (amenity == 'charging_station') return PoiCategory.charging;
    if (amenity == 'drinking_water' || amenity == 'water_point') {
      return PoiCategory.water;
    }
    // Drinkable taps / springs / wells. The Overpass query already
    // filters on drinking_water=yes so reaching here implies that, but
    // we double-check to stay robust against tag drift.
    final manMade = tags['man_made'];
    if ((manMade == 'water_tap' || manMade == 'water_well') &&
        tags['drinking_water'] == 'yes') {
      return PoiCategory.water;
    }
    if (tags['natural'] == 'spring' && tags['drinking_water'] == 'yes') {
      return PoiCategory.water;
    }
    if (amenity == 'shelter' && tags['shelter_type'] != 'public_transport') {
      return PoiCategory.shelter;
    }
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
    if (tourism == 'picnic_site') return PoiCategory.picnic;
    if (tourism == 'alpine_hut' || tourism == 'wilderness_hut') {
      return PoiCategory.shelter;
    }
    if (tourism == 'camp_site' ||
        tourism == 'caravan_site' ||
        tourism == 'camp_pitch') {
      return PoiCategory.camping;
    }
    if (tourism == 'hotel' ||
        tourism == 'motel' ||
        tourism == 'hostel' ||
        tourism == 'guest_house' ||
        tourism == 'bed_and_breakfast' ||
        tourism == 'apartment' ||
        tourism == 'chalet') {
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

    final historic = tags['historic'];
    if (historic != null && historic != 'no') return PoiCategory.sights;

    if (tags['castle_type'] != null) return PoiCategory.sights;

    final building = tags['building'];
    if (building == 'cathedral' ||
        building == 'chapel' ||
        building == 'church' ||
        building == 'temple' ||
        building == 'mosque' ||
        building == 'synagogue' ||
        building == 'castle') {
      return PoiCategory.sights;
    }

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
      case PoiCategory.picnic:
      case PoiCategory.camping:
      case PoiCategory.lodging:
      case PoiCategory.info:
        return 'tourism';
      case PoiCategory.station:
        return 'railway';
      case PoiCategory.shelter:
        // Mixed: alpine_hut/wilderness_hut sit under tourism, while
        // amenity=shelter belongs to amenity. The legend prefers tourism
        // since that's the more descriptive label when present.
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
