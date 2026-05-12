import 'dart:typed_data';

import 'package:http/http.dart' as http;

class RouteUrlImportException implements Exception {
  final String code;
  final String? detail;
  const RouteUrlImportException(this.code, [this.detail]);
  @override
  String toString() => detail ?? code;
}

class RouteUrlImport {
  static final RegExp _komootTour =
      RegExp(r'komoot\.(?:com|de|fr|es|it|nl|pl)/tour/(\d+)', caseSensitive: false);
  static final RegExp _stravaActivity =
      RegExp(r'strava\.com/activities/(\d+)', caseSensitive: false);
  static final RegExp _stravaRoute =
      RegExp(r'strava\.com/routes/(\d+)', caseSensitive: false);

  /// Convert a user-pasted URL into a direct GPX download URL.
  ///
  /// Returns null if the URL is unsupported. Strava activity/route URLs
  /// require OAuth, so we throw an explicit hint rather than silently
  /// trying a URL that always 401s.
  static Uri _resolveGpxUrl(String input) {
    final raw = input.trim();
    if (raw.isEmpty) {
      throw const RouteUrlImportException('empty_url');
    }

    final komoot = _komootTour.firstMatch(raw);
    if (komoot != null) {
      return Uri.parse(
          'https://www.komoot.com/api/v007/tours/${komoot.group(1)}.gpx');
    }

    if (_stravaActivity.hasMatch(raw) || _stravaRoute.hasMatch(raw)) {
      throw const RouteUrlImportException('strava_login_required');
    }

    // Fall back to fetching the URL as-is. Any service that hosts a public
    // .gpx file (RideWithGPS public route export links, AllTrails public
    // GPX, gpsies.com archives etc.) lands here.
    Uri parsed;
    try {
      parsed = Uri.parse(raw);
    } catch (_) {
      throw const RouteUrlImportException('invalid_url');
    }
    if (!parsed.hasScheme || (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      throw const RouteUrlImportException('invalid_url');
    }
    return parsed;
  }

  /// Fetch a GPX from a user-pasted URL. Throws RouteUrlImportException on
  /// network errors, 4xx, or unsupported services.
  static Future<({String name, Uint8List bytes})> fetch(String input) async {
    final url = _resolveGpxUrl(input);

    final http.Response response;
    try {
      response = await http.get(
        url,
        headers: const {
          'User-Agent': 'Wegwiesel/1.9 (wegwiesel.app)',
          'Accept': 'application/gpx+xml, application/xml, text/xml, */*',
        },
      ).timeout(const Duration(seconds: 25));
    } catch (e) {
      throw RouteUrlImportException('network', e.toString());
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const RouteUrlImportException('forbidden');
    }
    if (response.statusCode == 404) {
      throw const RouteUrlImportException('not_found');
    }
    if (response.statusCode != 200) {
      throw RouteUrlImportException('http_${response.statusCode}');
    }

    final bytes = response.bodyBytes;
    if (bytes.isEmpty) {
      throw const RouteUrlImportException('empty_body');
    }

    // Cheap sanity check: GPX is XML. Reject obvious HTML responses (login
    // walls love to return 200 + HTML).
    final preview = String.fromCharCodes(
        bytes.sublist(0, bytes.length > 200 ? 200 : bytes.length).toList());
    final lower = preview.toLowerCase().trimLeft();
    if (lower.startsWith('<!doctype html') || lower.startsWith('<html')) {
      throw const RouteUrlImportException('not_gpx');
    }

    final name = _nameFrom(url);
    return (name: name, bytes: bytes);
  }

  static String _nameFrom(Uri url) {
    final last = url.pathSegments.isNotEmpty ? url.pathSegments.last : url.host;
    return last.endsWith('.gpx') ? last : '$last.gpx';
  }
}
