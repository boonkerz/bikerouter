import 'dart:convert';

/// Compact wire format for share URLs.
/// Example encoded payload (URL-safe base64):
///   { "w": [[48.13,11.57],[48.20,11.65]], "p": "trekking", "rt": 0|1, "d": 30, "dir": 90 }
class SharedRoute {
  final List<List<double>> waypoints; // [lat, lon]
  final String profile;
  final bool roundtrip;
  final int? roundtripDistanceKm;
  final int? roundtripDirection;

  const SharedRoute({
    required this.waypoints,
    required this.profile,
    this.roundtrip = false,
    this.roundtripDistanceKm,
    this.roundtripDirection,
  });

  String encode() {
    final json = <String, dynamic>{
      'w': waypoints
          .map((p) => [double.parse(p[0].toStringAsFixed(5)), double.parse(p[1].toStringAsFixed(5))])
          .toList(),
      'p': profile,
    };
    if (roundtrip) {
      json['rt'] = 1;
      if (roundtripDistanceKm != null) json['d'] = roundtripDistanceKm;
      if (roundtripDirection != null) json['dir'] = roundtripDirection;
    }
    final raw = utf8.encode(jsonEncode(json));
    return base64Url.encode(raw).replaceAll('=', '');
  }

  static SharedRoute? decode(String encoded) {
    try {
      // Restore base64 padding
      var s = encoded;
      while (s.length % 4 != 0) {
        s += '=';
      }
      final raw = base64Url.decode(s);
      final json = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
      final wRaw = json['w'] as List?;
      if (wRaw == null || wRaw.isEmpty) return null;
      final wps = wRaw
          .map((e) => (e as List).map((v) => (v as num).toDouble()).toList())
          .where((p) => p.length >= 2)
          .toList();
      if (wps.isEmpty) return null;
      return SharedRoute(
        waypoints: wps,
        profile: (json['p'] as String?) ?? 'trekking',
        roundtrip: json['rt'] == 1,
        roundtripDistanceKm: (json['d'] as num?)?.toInt(),
        roundtripDirection: (json['dir'] as num?)?.toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  String toUrl({String base = 'https://wegwiesel.app/'}) {
    return '${base.endsWith('/') ? base : '$base/'}?r=${encode()}';
  }
}
