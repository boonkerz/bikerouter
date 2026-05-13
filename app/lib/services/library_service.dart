import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LibraryItem {
  final String code;
  final String title;
  final String description;
  final String profile;
  final int distanceM;
  final int ascent;
  final double centerLat;
  final double centerLon;
  final DateTime publishedAt;

  const LibraryItem({
    required this.code,
    required this.title,
    required this.description,
    required this.profile,
    required this.distanceM,
    required this.ascent,
    required this.centerLat,
    required this.centerLon,
    required this.publishedAt,
  });

  double get distanceKm => distanceM / 1000.0;

  factory LibraryItem.fromJson(Map<String, dynamic> j) => LibraryItem(
        code: j['code'] as String,
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        profile: j['profile'] as String? ?? '',
        distanceM: (j['distanceM'] as num?)?.toInt() ?? 0,
        ascent: (j['ascent'] as num?)?.toInt() ?? 0,
        centerLat: (j['centerLat'] as num?)?.toDouble() ?? 0,
        centerLon: (j['centerLon'] as num?)?.toDouble() ?? 0,
        publishedAt: DateTime.tryParse(j['publishedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class LibraryService {
  static String get baseUrl =>
      kIsWeb ? '/api/share' : 'https://wegwiesel.app/api/share';
  static String get libraryUrl =>
      kIsWeb ? '/api/library' : 'https://wegwiesel.app/api/library';
  static String get gpxBaseUrl =>
      kIsWeb ? '/api/share' : 'https://wegwiesel.app/api/share';

  /// Mark an existing share as published in the public library.
  /// Returns true on success.
  static Future<bool> publish({
    required String code,
    required String editToken,
    required String title,
    required String description,
    required String profile,
    required int distanceM,
    required int ascent,
    required double centerLat,
    required double centerLon,
  }) async {
    final res = await http
        .patch(
          Uri.parse('$baseUrl/$code'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'editToken': editToken,
            'published': true,
            'title': title,
            'description': description,
            'profile': profile,
            'ascent': ascent,
            'centerLat': centerLat,
            'centerLon': centerLon,
          }),
        )
        .timeout(const Duration(seconds: 12));
    return res.statusCode == 200;
  }

  static Future<bool> unpublish({
    required String code,
    required String editToken,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/$code'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'editToken': editToken, 'published': false}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> delete({
    required String code,
    required String editToken,
  }) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/$code?editToken=$editToken'),
    );
    return res.statusCode == 204;
  }

  static Future<List<LibraryItem>> list({
    String? profile,
    double? minKm,
    double? maxKm,
    List<double>? bbox,
    String? search,
    int page = 0,
  }) async {
    final qp = <String, String>{'page': page.toString()};
    if (profile != null && profile.isNotEmpty) qp['profile'] = profile;
    if (minKm != null) qp['minKm'] = minKm.toString();
    if (maxKm != null) qp['maxKm'] = maxKm.toString();
    if (bbox != null && bbox.length == 4) qp['bbox'] = bbox.join(',');
    if (search != null && search.isNotEmpty) qp['q'] = search;
    final uri = Uri.parse(libraryUrl).replace(queryParameters: qp);
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return const [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (json['items'] as List).cast<Map<String, dynamic>>();
    return items.map(LibraryItem.fromJson).toList();
  }

  /// Fetch the raw GPX bytes for a published route.
  static Future<List<int>?> fetchGpx(String code) async {
    final res = await http
        .get(Uri.parse('$gpxBaseUrl/$code/course.gpx'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    return res.bodyBytes;
  }
}

/// Persists per-share edit_tokens locally so the user can later
/// unpublish/delete their own publications across app restarts.
class EditTokenStore {
  static const _key = 'share_edit_tokens_v1';

  static Future<Map<String, String>> _read() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map).cast<String, String>();
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(String code, String token) async {
    final m = await _read();
    m[code] = token;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(m));
  }

  static Future<String?> get(String code) async {
    final m = await _read();
    return m[code];
  }

  static Future<void> remove(String code) async {
    final m = await _read();
    m.remove(code);
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(m));
  }

  static Future<Map<String, String>> all() => _read();
}
