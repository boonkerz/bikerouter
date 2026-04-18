import 'dart:convert';
import 'package:http/http.dart' as http;

class OsmRouteInfo {
  final int id;
  final String routeType; // bicycle, hiking, mtb, foot
  final String? name;
  final String? ref;
  final String? network;
  final String? operator;
  final String? website;
  final String? wikipedia;
  final String? description;
  final String? distance;
  final String? from;
  final String? to;
  final String? colour;
  final String? symbol;
  final String? osmcSymbol;

  const OsmRouteInfo({
    required this.id,
    required this.routeType,
    this.name,
    this.ref,
    this.network,
    this.operator,
    this.website,
    this.wikipedia,
    this.description,
    this.distance,
    this.from,
    this.to,
    this.colour,
    this.symbol,
    this.osmcSymbol,
  });

  String get displayName {
    if (name != null && ref != null) return '$ref · $name';
    if (name != null) return name!;
    if (ref != null) return ref!;
    return typeLabel;
  }

  String get typeLabel {
    switch (routeType) {
      case 'bicycle':
        return 'Radroute';
      case 'hiking':
      case 'foot':
        return 'Wanderweg';
      case 'mtb':
        return 'MTB-Route';
      default:
        return routeType;
    }
  }

  String get networkLabel {
    switch (network) {
      case 'icn':
        return 'International';
      case 'ncn':
        return 'National';
      case 'rcn':
        return 'Regional';
      case 'lcn':
        return 'Lokal';
      case 'iwn':
        return 'International (Wandern)';
      case 'nwn':
        return 'National (Wandern)';
      case 'rwn':
        return 'Regional (Wandern)';
      case 'lwn':
        return 'Lokal (Wandern)';
      default:
        return network ?? '';
    }
  }
}

class RouteInfoService {
  static const String baseUrl = 'https://wegwiesel.app/overpass/api/interpreter';

  static Future<List<OsmRouteInfo>> fetchAtPoint(
    double lat,
    double lon, {
    double radiusMeters = 15,
  }) async {
    final query = '''
[out:json][timeout:25];
way(around:$radiusMeters,$lat,$lon);
rel(bw)["route"~"bicycle|hiking|foot|mtb"];
out tags;
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
    final seen = <int>{};
    final result = <OsmRouteInfo>[];
    for (final e in elements) {
      if (e['type'] != 'relation') continue;
      final id = (e['id'] as num).toInt();
      if (!seen.add(id)) continue;
      final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
      final route = tags['route'] as String?;
      if (route == null) continue;
      result.add(OsmRouteInfo(
        id: id,
        routeType: route,
        name: (tags['name:de'] ?? tags['name']) as String?,
        ref: tags['ref'] as String?,
        network: tags['network'] as String?,
        operator: tags['operator'] as String?,
        website: (tags['website'] ?? tags['url']) as String?,
        wikipedia: tags['wikipedia'] as String?,
        description: (tags['description:de'] ?? tags['description']) as String?,
        distance: tags['distance'] as String?,
        from: tags['from'] as String?,
        to: tags['to'] as String?,
        colour: (tags['colour'] ?? tags['color']) as String?,
        symbol: tags['symbol'] as String?,
        osmcSymbol: tags['osmc:symbol'] as String?,
      ));
    }
    return result;
  }
}
