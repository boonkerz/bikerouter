import 'dart:math';

class RouteResult {
  final Map<String, dynamic> geojson;
  final double distance; // km
  final double ascent; // m
  final double descent; // m
  final double time; // seconds
  final List<List<double>> coordinates; // [lon, lat, elevation]

  RouteResult({
    required this.geojson,
    required this.distance,
    required this.ascent,
    required this.descent,
    required this.time,
    required this.coordinates,
  });

  factory RouteResult.fromGeojson(Map<String, dynamic> geojson) {
    final features = geojson['features'] as List;
    if (features.isEmpty) throw Exception('No route found');

    final feature = features[0] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final props = feature['properties'] as Map<String, dynamic>? ?? {};

    final rawCoords = (geometry['coordinates'] as List)
        .map((c) => (c as List).map((v) => (v as num).toDouble()).toList())
        .toList();

    double distance = 0;
    if (props.containsKey('track-length')) {
      distance = double.parse(props['track-length'].toString()) / 1000;
    } else {
      for (int i = 1; i < rawCoords.length; i++) {
        distance += _haversine(rawCoords[i - 1], rawCoords[i]);
      }
    }

    double ascent = 0;
    double descent = 0;
    if (props.containsKey('filtered ascend')) {
      ascent = double.parse(props['filtered ascend'].toString());
    } else if (props.containsKey('plain-ascend')) {
      ascent = double.parse(props['plain-ascend'].toString());
    }

    for (int i = 1; i < rawCoords.length; i++) {
      final diff = rawCoords[i][2] - rawCoords[i - 1][2];
      if (ascent == 0 && diff > 0) ascent += diff;
      if (diff < 0) descent += diff.abs();
    }

    final time = props.containsKey('total-time')
        ? double.parse(props['total-time'].toString())
        : (distance / 20) * 3600;

    return RouteResult(
      geojson: geojson,
      distance: distance,
      ascent: ascent,
      descent: descent,
      time: time,
      coordinates: rawCoords,
    );
  }

  static double _haversine(List<double> a, List<double> b) {
    const r = 6371.0;
    final dLat = (b[1] - a[1]) * pi / 180;
    final dLon = (b[0] - a[0]) * pi / 180;
    final lat1 = a[1] * pi / 180;
    final lat2 = b[1] * pi / 180;
    final x = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(x), sqrt(1 - x));
  }
}
