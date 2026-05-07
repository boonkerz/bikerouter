import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class GarminShareResult {
  final String code;
  final DateTime expiresAt;
  final String gpxUrl;

  const GarminShareResult({
    required this.code,
    required this.expiresAt,
    required this.gpxUrl,
  });
}

class GarminShareService {
  static String baseUrl = kIsWeb ? '/api/share' : 'https://wegwiesel.app/api/share';

  static Future<GarminShareResult> upload({
    required String name,
    required String gpx,
    required int distanceMeters,
  }) async {
    final res = await http
        .post(
          Uri.parse(baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'gpx': gpx,
            'distanceM': distanceMeters,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('share upload failed (${res.statusCode}): ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final code = json['code'] as String;
    final expiresAt = DateTime.parse(json['expiresAt'] as String);
    final base = kIsWeb ? '' : 'https://wegwiesel.app';
    return GarminShareResult(
      code: code,
      expiresAt: expiresAt,
      gpxUrl: '$base/api/share/$code/course.gpx',
    );
  }
}
