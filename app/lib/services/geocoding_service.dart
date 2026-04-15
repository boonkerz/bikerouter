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
