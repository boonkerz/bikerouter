import 'dart:convert';
import 'route_poi.dart';

/// Compact snapshot of the computed route geometry so the saved route can
/// be displayed and navigated without re-calling BRouter — works offline.
/// Coordinates are kept flat ([lon, lat, ele, lon, lat, ele, …]) to keep
/// the JSON small for large tracks.
class CachedRoute {
  final List<double> flatCoords;
  final double ascent;
  final double descent;
  final List<List<double>> turnHints; // [coordIdx, cmd, exit, distToNext, angle]

  const CachedRoute({
    required this.flatCoords,
    required this.ascent,
    required this.descent,
    this.turnHints = const [],
  });

  /// Restore the (lon, lat, ele) triples used elsewhere in the app.
  List<List<double>> get coordinates {
    final out = <List<double>>[];
    for (int i = 0; i + 2 < flatCoords.length; i += 3) {
      out.add([flatCoords[i], flatCoords[i + 1], flatCoords[i + 2]]);
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
        'c': flatCoords,
        'a': ascent,
        'd': descent,
        if (turnHints.isNotEmpty) 'th': turnHints,
      };

  factory CachedRoute.fromJson(Map<String, dynamic> j) => CachedRoute(
        flatCoords:
            (j['c'] as List).map((e) => (e as num).toDouble()).toList(),
        ascent: (j['a'] as num?)?.toDouble() ?? 0,
        descent: (j['d'] as num?)?.toDouble() ?? 0,
        turnHints: (j['th'] as List?)
                ?.map((row) =>
                    (row as List).map((v) => (v as num).toDouble()).toList())
                .toList() ??
            const [],
      );
}

class SavedRoute {
  final String id;
  final String name;
  final String profile;
  final List<List<double>> waypoints; // [[lon, lat], ...]
  final double distanceKm;
  final int durationSeconds;
  final int ascent;
  final DateTime createdAt;
  final bool isRoundtrip;
  final int? rtDistanceKm;
  final int? rtDirection;
  final List<RoutePoi> pois;
  final CachedRoute? cached;

  const SavedRoute({
    required this.id,
    required this.name,
    required this.profile,
    required this.waypoints,
    required this.distanceKm,
    required this.durationSeconds,
    required this.ascent,
    required this.createdAt,
    required this.isRoundtrip,
    this.rtDistanceKm,
    this.rtDirection,
    this.pois = const [],
    this.cached,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'profile': profile,
        'waypoints': waypoints,
        'distanceKm': distanceKm,
        'durationSeconds': durationSeconds,
        'ascent': ascent,
        'createdAt': createdAt.toIso8601String(),
        'isRoundtrip': isRoundtrip,
        'rtDistanceKm': rtDistanceKm,
        'rtDirection': rtDirection,
        'pois': pois.map((p) => p.toJson()).toList(),
        if (cached != null) 'cached': cached!.toJson(),
      };

  factory SavedRoute.fromJson(Map<String, dynamic> j) => SavedRoute(
        id: j['id'] as String,
        name: j['name'] as String,
        profile: j['profile'] as String,
        waypoints: (j['waypoints'] as List)
            .map((w) => (w as List).map((v) => (v as num).toDouble()).toList())
            .toList(),
        distanceKm: (j['distanceKm'] as num).toDouble(),
        durationSeconds: j['durationSeconds'] as int,
        ascent: j['ascent'] as int,
        createdAt: DateTime.parse(j['createdAt'] as String),
        isRoundtrip: j['isRoundtrip'] as bool,
        rtDistanceKm: j['rtDistanceKm'] as int?,
        rtDirection: j['rtDirection'] as int?,
        pois: (j['pois'] as List?)
                ?.map((p) => RoutePoi.fromJson(p as Map<String, dynamic>))
                .toList() ??
            const [],
        cached: j['cached'] == null
            ? null
            : CachedRoute.fromJson(j['cached'] as Map<String, dynamic>),
      );

  String toJsonString() => jsonEncode(toJson());
  factory SavedRoute.fromJsonString(String s) =>
      SavedRoute.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
