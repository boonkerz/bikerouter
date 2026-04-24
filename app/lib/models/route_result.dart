import 'dart:math';

import 'route_segment.dart';

class RouteResult {
  final Map<String, dynamic> geojson;
  final double distance; // km
  final double ascent; // m
  final double descent; // m
  final double time; // seconds
  final List<List<double>> coordinates; // [lon, lat, elevation]
  final List<RouteSegment> segments;

  RouteResult({
    required this.geojson,
    required this.distance,
    required this.ascent,
    required this.descent,
    required this.time,
    required this.coordinates,
    required this.segments,
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

    final segments = _parseSegments(props, rawCoords);

    return RouteResult(
      geojson: geojson,
      distance: distance,
      ascent: ascent,
      descent: descent,
      time: time,
      coordinates: rawCoords,
      segments: segments,
    );
  }

  /// Parses BRouter `messages` into segments. Each row is one OSM way
  /// segment (length in meters, not one-per-coordinate). We build cumulative
  /// distance along messages and independently along coordinates, then snap
  /// segment boundaries to the nearest coord index.
  ///
  /// BRouter message columns:
  ///   0 Longitude, 1 Latitude, 2 Elevation, 3 Distance (m, edge length),
  ///   9 WayTags (space-separated k=v), rest ignored.
  static List<RouteSegment> _parseSegments(
    Map<String, dynamic> props,
    List<List<double>> coords,
  ) {
    final messages = props['messages'];
    if (messages is! List || messages.length < 2 || coords.length < 2) {
      return const [];
    }

    final coordCumKm = List<double>.filled(coords.length, 0);
    for (int i = 1; i < coords.length; i++) {
      coordCumKm[i] = coordCumKm[i - 1] + _haversine(coords[i - 1], coords[i]);
    }
    final totalKm = coordCumKm.last;
    if (totalKm <= 0) return const [];

    final rows = messages.skip(1).toList();
    double msgTotalM = 0;
    for (final row in rows) {
      if (row is List && row.length > 3) {
        msgTotalM += double.tryParse(row[3].toString()) ?? 0;
      }
    }
    final scale = msgTotalM > 0 ? (totalKm * 1000) / msgTotalM : 1.0;

    int coordIdxForDistance(double distKm) {
      if (distKm <= 0) return 0;
      if (distKm >= totalKm) return coords.length - 1;
      int lo = 0, hi = coords.length - 1;
      while (lo < hi) {
        final mid = (lo + hi) ~/ 2;
        if (coordCumKm[mid] < distKm) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      return lo;
    }

    final segs = <RouteSegment>[];
    double cumDistKm = 0;
    double runStartDistKm = 0;
    int runStartCoord = 0;
    String? runTags;
    double runCostWeightedSum = 0; // sum of (costPerKm * edgeKm) in run
    double runEdgeKmSum = 0;

    for (final row in rows) {
      if (row is! List || row.length < 4) continue;
      final edgeKm = (double.tryParse(row[3].toString()) ?? 0) / 1000 * scale;
      final tags = row.length > 9 ? (row[9]?.toString() ?? '') : '';
      final edgeCost = row.length > 4
          ? (double.tryParse(row[4].toString()) ?? 0)
          : 0.0;
      final edgeEndKm = cumDistKm + edgeKm;

      if (runTags == null) {
        runTags = tags;
        runStartCoord = 0;
        runStartDistKm = 0;
        runCostWeightedSum = edgeCost * edgeKm;
        runEdgeKmSum = edgeKm;
      } else if (tags != runTags) {
        final endIdx = coordIdxForDistance(cumDistKm);
        if (endIdx > runStartCoord) {
          segs.add(RouteSegment(
            startCoordIdx: runStartCoord,
            endCoordIdx: endIdx,
            startDistanceKm: runStartDistKm,
            endDistanceKm: cumDistKm,
            wayTagsRaw: runTags,
            costPerKm: runEdgeKmSum > 0 ? runCostWeightedSum / runEdgeKmSum : 0,
          ));
        }
        runTags = tags;
        runStartCoord = endIdx;
        runStartDistKm = cumDistKm;
        runCostWeightedSum = edgeCost * edgeKm;
        runEdgeKmSum = edgeKm;
      } else {
        runCostWeightedSum += edgeCost * edgeKm;
        runEdgeKmSum += edgeKm;
      }
      cumDistKm = edgeEndKm;
    }

    if (runTags != null && runStartCoord < coords.length - 1) {
      segs.add(RouteSegment(
        startCoordIdx: runStartCoord,
        endCoordIdx: coords.length - 1,
        startDistanceKm: runStartDistKm,
        endDistanceKm: totalKm,
        wayTagsRaw: runTags,
        costPerKm: runEdgeKmSum > 0 ? runCostWeightedSum / runEdgeKmSum : 0,
      ));
    }

    return segs;
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
