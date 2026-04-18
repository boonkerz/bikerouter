import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingResult {
  final String displayName;
  final double lat;
  final double lon;

  GeocodingResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      displayName: json['display_name'] as String,
      lat: double.parse(json['lat'] as String),
      lon: double.parse(json['lon'] as String),
    );
  }
}

class GeocodingService {
  static Future<String?> reverse(double lat, double lon) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=$lat&lon=$lon'
      '&format=json'
      '&zoom=16'
      '&addressdetails=1',
    );
    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'Wegwiesel/1.0 (wegwiesel.app)',
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final addr = (json['address'] as Map?)?.cast<String, dynamic>() ?? {};
      // Prefer a concise label: "Landmark, City" or "Road, City" or the first
      // available place-level name.
      final primary = (json['name'] as String?)?.trim();
      final road = addr['road'] as String?;
      final suburb = addr['suburb'] as String?;
      final village = addr['village'] as String?;
      final town = addr['town'] as String?;
      final city = addr['city'] as String?;
      final county = addr['county'] as String?;
      final locality = village ?? town ?? city ?? suburb ?? county;
      if (primary != null && primary.isNotEmpty && locality != null) {
        return '$primary, $locality';
      }
      if (road != null && locality != null) return '$road, $locality';
      if (primary != null && primary.isNotEmpty) return primary;
      if (road != null) return road;
      if (locality != null) return locality;
      return (json['display_name'] as String?)?.split(',').take(2).join(',');
    } catch (_) {
      return null;
    }
  }

  static Future<List<GeocodingResult>> search(String query) async {
    if (query.trim().length < 2) return [];

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&limit=5'
      '&addressdetails=0',
    );

    final response = await http.get(uri, headers: {
      'User-Agent': 'Wegwiesel/1.0 (wegwiesel.app)',
    });

    if (response.statusCode != 200) return [];

    final results = jsonDecode(response.body) as List;
    return results
        .map((r) => GeocodingResult.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
