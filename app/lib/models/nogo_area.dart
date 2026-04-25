class NogoArea {
  final String id;
  final double lat;
  final double lon;
  final int radiusMeters;

  const NogoArea({
    required this.id,
    required this.lat,
    required this.lon,
    required this.radiusMeters,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lon': lon,
        'radius': radiusMeters,
      };

  factory NogoArea.fromJson(Map<String, dynamic> j) => NogoArea(
        id: j['id'] as String,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        radiusMeters: (j['radius'] as num).toInt(),
      );

  /// BRouter `nogos` URL fragment: `lon,lat,radius`
  String toBRouterParam() => '$lon,$lat,$radiusMeters';
}
