import 'dart:convert';
import 'route_poi.dart';

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
      );

  String toJsonString() => jsonEncode(toJson());
  factory SavedRoute.fromJsonString(String s) =>
      SavedRoute.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
