import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

/// Test variants we score routes for. Each implies a target effort
/// duration which we translate into a target segment length below.
enum FtpTestType {
  twentyMinute('20-Minuten-Test'),
  eightMinute('8-Minuten-Test (2×)'),
  ramp('Stufentest'),
  sweetSpot('Sweet Spot (≥ 30 min)');

  const FtpTestType(this.label);
  final String label;
}

/// Terrain preference. Climb mode picks steady uphill stretches (typical
/// for hard-effort tests outside city traffic); flat picks low-gradient
/// stretches where pace stays controlled.
enum FtpRouteMode {
  flat('Flach'),
  climb('Bergauf'),
  either('Egal');

  const FtpRouteMode(this.label);
  final String label;
}

/// One scored candidate ride. `coords` is the way's polyline (lon/lat
/// pairs) as returned by Overpass; we ship it through to the map widget
/// for rendering.
class FtpTestCandidate {
  final int osmWayId;
  final String? name;
  final List<List<double>> coords; // [lon, lat] per node
  final double lengthKm;
  final double avgGradientPercent;
  final double gradientStdDev;
  final String? surface;
  final String highway;
  final double score; // 0..100
  final FtpRouteMode chosenMode;

  const FtpTestCandidate({
    required this.osmWayId,
    required this.name,
    required this.coords,
    required this.lengthKm,
    required this.avgGradientPercent,
    required this.gradientStdDev,
    required this.surface,
    required this.highway,
    required this.score,
    required this.chosenMode,
  });
}

class FtpRouteFinder {
  static const String _overpassUrl =
      'https://wegwiesel.app/overpass/api/interpreter';
  // Open-Topodata's free tier rate-limits at 1000 calls/day per IP; for
  // our use that's plenty (~30 candidate ways × 1 batch call = 30/day).
  // SRTM 30 m is the highest-resolution global dataset they expose for
  // free — accurate enough for the gradient stats we report.
  static const String _topodataUrl =
      'https://api.opentopodata.org/v1/srtm30m';

  /// Searches for top training-route candidates around [lat]/[lon] within
  /// the given radius. Returns at most [limit] candidates sorted by score.
  static Future<List<FtpTestCandidate>> findCandidates({
    required double lat,
    required double lon,
    required double radiusKm,
    required FtpTestType test,
    required FtpRouteMode mode,
    int limit = 5,
  }) async {
    final ways = await _fetchCandidateWays(lat: lat, lon: lon, radiusKm: radiusKm);
    if (ways.isEmpty) return const [];

    final targetKm = _targetLengthKm(test);
    // First-pass length filter: drop ways that can't host the effort.
    final usable = ways
        .where((w) => w.length >= targetKm * 0.6 && w.length <= targetKm * 4)
        .toList()
      ..sort((a, b) => (a.length - targetKm).abs().compareTo(
          (b.length - targetKm).abs()));
    final shortlist = usable.take(min(30, usable.length)).toList();
    if (shortlist.isEmpty) return const [];

    // Sample 10 elevation points per way (start, end, 8 interior).
    final samplePoints = <(int wayIdx, List<double> coord)>[];
    for (var i = 0; i < shortlist.length; i++) {
      for (final pt in _samplePoints(shortlist[i].coords, count: 10)) {
        samplePoints.add((i, pt));
      }
    }
    final elevations = await _batchElevations(
      samplePoints.map((s) => s.$2).toList(),
    );
    // Group elevations back per way.
    final eleByWay = <int, List<double>>{};
    for (var k = 0; k < samplePoints.length; k++) {
      eleByWay
          .putIfAbsent(samplePoints[k].$1, () => <double>[])
          .add(elevations[k]);
    }

    final scored = <FtpTestCandidate>[];
    for (var i = 0; i < shortlist.length; i++) {
      final w = shortlist[i];
      final eles = eleByWay[i] ?? const <double>[];
      final stats = _gradientStats(w.length, eles);
      final effectiveMode = mode == FtpRouteMode.either
          ? (stats.avgPct.abs() > 2.5 ? FtpRouteMode.climb : FtpRouteMode.flat)
          : mode;
      final score = _score(
        lengthKm: w.length,
        targetKm: targetKm,
        gradientStats: stats,
        mode: effectiveMode,
        surface: w.surface,
        highway: w.highway,
      );
      if (score < 30) continue; // not worth listing
      scored.add(FtpTestCandidate(
        osmWayId: w.id,
        name: w.name,
        coords: w.coords,
        lengthKm: w.length,
        avgGradientPercent: stats.avgPct,
        gradientStdDev: stats.stdDev,
        surface: w.surface,
        highway: w.highway,
        score: score,
        chosenMode: effectiveMode,
      ));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).toList();
  }

  /// Target effort length in km, converted from the test duration using
  /// a moderate-amateur cruising speed. 20-min @ 30 km/h = 10 km; ramp
  /// is shorter because most riders bail before the 15-min mark.
  static double _targetLengthKm(FtpTestType test) {
    switch (test) {
      case FtpTestType.twentyMinute:
        return 10.0;
      case FtpTestType.eightMinute:
        return 4.0;
      case FtpTestType.ramp:
        return 8.0;
      case FtpTestType.sweetSpot:
        return 18.0;
    }
  }

  static Future<List<_Way>> _fetchCandidateWays({
    required double lat,
    required double lon,
    required double radiusKm,
  }) async {
    // Cycleways + low-traffic roads with a usable surface. We exclude
    // motorways/trunks (no cyclists allowed in DE) and footways/paths
    // (no road bike).
    final r = (radiusKm * 1000).round();
    final query = '''
[out:json][timeout:60];
(
  way["highway"~"^(cycleway|tertiary|secondary|unclassified|residential|primary)\$"]
     ["surface"~"^(asphalt|paved|concrete|paving_stones)\$"]
     (around:$r,$lat,$lon);
);
out geom tags;
''';
    final response = await http.post(
      Uri.parse(_overpassUrl),
      body: {'data': query},
      headers: {'User-Agent': 'Wegwiesel/2.1 (wegwiesel.app)'},
    ).timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw Exception('Overpass failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (json['elements'] as List?) ?? const [];
    final out = <_Way>[];
    for (final e in elements) {
      if (e is! Map || e['type'] != 'way') continue;
      final geom = e['geometry'] as List?;
      if (geom == null || geom.length < 2) continue;
      final coords = <List<double>>[];
      for (final g in geom) {
        if (g is! Map) continue;
        final la = (g['lat'] as num?)?.toDouble();
        final lo = (g['lon'] as num?)?.toDouble();
        if (la == null || lo == null) continue;
        coords.add([lo, la]);
      }
      if (coords.length < 2) continue;
      final length = _polylineKm(coords);
      // Hard floor — Overpass returns a lot of stub ways for residential
      // areas, but our shortest test (8-min half) needs at least 1.5 km.
      if (length < 1.5) continue;
      final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
      out.add(_Way(
        id: (e['id'] as num).toInt(),
        coords: coords,
        length: length,
        name: tags['name'] as String? ?? tags['ref'] as String?,
        surface: tags['surface'] as String?,
        highway: tags['highway'] as String? ?? 'unclassified',
      ));
    }
    return out;
  }

  /// Returns [count] evenly-spaced points along the polyline (including
  /// start and end). Used to sample elevation cheaply — no point feeding
  /// Open-Topodata the full 200-node geometry of a long way.
  static List<List<double>> _samplePoints(List<List<double>> coords,
      {required int count}) {
    if (coords.length <= count) return coords;
    final out = <List<double>>[];
    for (var i = 0; i < count; i++) {
      final idx = ((coords.length - 1) * i / (count - 1)).round();
      out.add(coords[idx]);
    }
    return out;
  }

  /// Calls Open-Topodata's batch endpoint. Splits the request into chunks
  /// of 100 (their per-call limit) and concatenates the result.
  static Future<List<double>> _batchElevations(
      List<List<double>> points) async {
    if (points.isEmpty) return const [];
    final out = <double>[];
    for (var i = 0; i < points.length; i += 100) {
      final batch = points.sublist(i, min(i + 100, points.length));
      final encoded = batch.map((p) => '${p[1]},${p[0]}').join('|');
      final uri = Uri.parse('$_topodataUrl?locations=$encoded');
      try {
        final r = await http.get(uri).timeout(const Duration(seconds: 15));
        if (r.statusCode != 200) {
          // Pad with zeros to keep index alignment with the request.
          out.addAll(List<double>.filled(batch.length, 0));
          continue;
        }
        final json = jsonDecode(r.body) as Map<String, dynamic>;
        final results = (json['results'] as List?) ?? const [];
        for (final res in results) {
          if (res is Map) {
            out.add((res['elevation'] as num?)?.toDouble() ?? 0);
          } else {
            out.add(0);
          }
        }
      } catch (_) {
        out.addAll(List<double>.filled(batch.length, 0));
      }
    }
    return out;
  }

  /// Computes mean gradient (signed) and segment-to-segment std-dev over
  /// the sampled elevation profile. Both expressed in percent.
  static _GradientStats _gradientStats(double lengthKm, List<double> eles) {
    if (eles.length < 2 || lengthKm <= 0) {
      return const _GradientStats(0, 0);
    }
    final segLengthKm = lengthKm / (eles.length - 1);
    final gradients = <double>[];
    for (var i = 1; i < eles.length; i++) {
      final rise = eles[i] - eles[i - 1];
      final run = segLengthKm * 1000;
      if (run > 0) gradients.add((rise / run) * 100);
    }
    if (gradients.isEmpty) return const _GradientStats(0, 0);
    final avg = gradients.reduce((a, b) => a + b) / gradients.length;
    final variance = gradients
            .map((g) => (g - avg) * (g - avg))
            .reduce((a, b) => a + b) /
        gradients.length;
    return _GradientStats(avg, sqrt(variance));
  }

  /// Weighted composite score. Length match is the heaviest factor —
  /// a way that's too short can't host the effort; too long means the
  /// rider would have to stop mid-test. Gradient match is mode-dependent.
  static double _score({
    required double lengthKm,
    required double targetKm,
    required _GradientStats gradientStats,
    required FtpRouteMode mode,
    required String? surface,
    required String highway,
  }) {
    final lengthScore = (1 - (lengthKm - targetKm).abs() / targetKm)
        .clamp(0.0, 1.0);

    double gradientScore;
    if (mode == FtpRouteMode.climb) {
      // Sweet spot: 3-8 % steady uphill. Penalize flat (boring) and
      // very steep (unsustainable). Negative average gradient is
      // downhill — useless for a climb test.
      final g = gradientStats.avgPct;
      if (g < 0.5) {
        gradientScore = 0;
      } else if (g < 3) {
        gradientScore = g / 3 * 0.5;
      } else if (g <= 8) {
        gradientScore = 1.0;
      } else if (g <= 12) {
        gradientScore = 1.0 - (g - 8) / 4 * 0.5;
      } else {
        gradientScore = 0;
      }
    } else {
      // Flat mode: any direction OK as long as |grade| stays low.
      final g = gradientStats.avgPct.abs();
      gradientScore = (1.0 - g / 2.0).clamp(0.0, 1.0);
    }

    // Consistency: low standard deviation = predictable effort.
    final consistencyScore = (1.0 - gradientStats.stdDev / 3.0).clamp(0.0, 1.0);

    final surfaceScore = switch (surface) {
      'asphalt' || 'paved' => 1.0,
      'concrete' => 0.85,
      'paving_stones' => 0.7,
      _ => 0.6,
    };

    final highwayScore = switch (highway) {
      'cycleway' => 1.0,
      'unclassified' || 'tertiary' => 0.85,
      'residential' => 0.7, // intersections + parked cars
      'secondary' || 'primary' => 0.6, // traffic
      _ => 0.5,
    };

    final composite = 0.35 * lengthScore +
        0.25 * gradientScore +
        0.20 * consistencyScore +
        0.10 * surfaceScore +
        0.10 * highwayScore;
    return composite * 100;
  }

  static double _polylineKm(List<List<double>> coords) {
    double total = 0;
    for (var i = 1; i < coords.length; i++) {
      total += _haversineKm(
        coords[i - 1][1], coords[i - 1][0],
        coords[i][1], coords[i][0],
      );
    }
    return total;
  }

  static double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return 2 * r * asin(sqrt(a));
  }
}

class _Way {
  final int id;
  final List<List<double>> coords;
  final double length;
  final String? name;
  final String? surface;
  final String highway;
  const _Way({
    required this.id,
    required this.coords,
    required this.length,
    required this.name,
    required this.surface,
    required this.highway,
  });
}

class _GradientStats {
  final double avgPct;
  final double stdDev;
  const _GradientStats(this.avgPct, this.stdDev);
}
