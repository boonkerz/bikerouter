import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/nogo_area.dart';
import '../models/route_result.dart';
import 'hiking_prefs.dart';
import 'profile_speed_prefs.dart';
import 'routing_prefs.dart';
import 'road_snap_service.dart';
import 'offline_routing/offline_router.dart';

class BRouterService {
  static String baseUrl = kIsWeb
      ? '/brouter'
      : 'https://wegwiesel.app/brouter';
  static OfflineRouter? offlineRouter;

  static String _nogosParam(List<NogoArea> nogos) {
    if (nogos.isEmpty) return '';
    return '&nogos=${nogos.map((n) => n.toBRouterParam()).join('|')}';
  }

  /// Wegwiesel exposes "car" and "car-trailer" as user-facing profiles.
  /// Both ride on top of our custom wegwiesel-car profile (class-based
  /// costfactor, no kinematic eco-bias, so long routes stay on the
  /// autobahn instead of taking Bundesstrasse shortcuts the way the
  /// stock car-vario does).
  static String _profileParam(
    String profile, {
    bool shortestCarRoute = false,
    bool avoidMotorwaysCarRoute = false,
  }) {
    if (profile == 'car' || profile == 'car-trailer') {
      final vmax = ProfileSpeedPrefs.speedFor(profile);
      final totalweight = profile == 'car-trailer' ? 2640 : 1640;
      // User toggles override the trailer-default for unpaved. The
      // alternative-route requests (shortest, avoid-motorways) still
      // win when explicitly passed.
      final trailerDefaultAvoidUnpaved = profile == 'car-trailer';
      final flagAvoidUnpaved =
          RoutingPrefs.flagValue(profile, RoutingFlag.avoidUnpaved);
      final avoidUnpaved =
          (flagAvoidUnpaved || trailerDefaultAvoidUnpaved) ? 1 : 0;
      final shortestRoute = (shortestCarRoute ||
              RoutingPrefs.flagValue(profile, RoutingFlag.shortestRoute))
          ? 1
          : 0;
      final avoidMotorways = (avoidMotorwaysCarRoute ||
              RoutingPrefs.flagValue(profile, RoutingFlag.avoidMotorways))
          ? 1
          : 0;
      final avoidToll =
          RoutingPrefs.flagValue(profile, RoutingFlag.avoidToll)
              ? '&profile:avoid_toll=true'
              : '';
      // The trailer profile bakes in stronger motorway/trunk preference,
      // trailer=/caravan=/maxweight= hard-blocks and Gespann-realistic
      // maxspeed defaults. Solo car keeps the lighter wegwiesel-car
      // profile which matches typical Google-Maps-style behaviour.
      final brouterProfile = profile == 'car-trailer'
          ? 'wegwiesel-car-trailer'
          : 'wegwiesel-car';
      // add_beeline lets BRouter draw a beeline from the user's clicked
      // waypoint to the nearest car-accessible road. Without it, taps that
      // land on bike paths or footways trigger "target island failed".
      return 'profile=$brouterProfile'
          '&profile:vmax=$vmax'
          '&profile:totalweight=$totalweight'
          '&profile:avoid_motorways=$avoidMotorways'
          '&profile:avoid_unpaved=$avoidUnpaved'
          '&profile:shortest_route=$shortestRoute'
          '$avoidToll'
          '&profile:add_beeline=1';
    }
    if (profile == 'hiking-beta') {
      final prefer = HikingPrefs.preferHikingRoutes ? 1 : 0;
      final sac = HikingPrefs.sacScaleLimit;
      return 'profile=hiking-beta'
          '&profile:prefer_hiking_routes=$prefer'
          '&profile:SAC_scale_limit=$sac'
          '${RoutingPrefs.buildBRouterParams(profile)}';
    }
    return 'profile=$profile${RoutingPrefs.buildBRouterParams(profile)}';
  }

  static bool _isCar(String profile) =>
      profile == 'car' || profile == 'car-trailer';

  /// For car profiles, snap each waypoint to the nearest publicly drivable
  /// road via Overpass. Geocoded destinations (campsites, business parks)
  /// often sit on private driveways behind gates — BRouter won't route to
  /// those. Falls back to the original waypoint if Overpass is unreachable
  /// or finds nothing nearby.
  static Future<List<List<double>>> _snapForCar(
    List<List<double>> waypoints,
    String profile,
  ) async {
    if (!_isCar(profile)) return waypoints;
    final snapped = await Future.wait(waypoints.map((w) async {
      final s = await RoadSnapService.snap(w[1], w[0]);
      if (s == null) return w;
      return [s[1], s[0]]; // [lon, lat]
    }));
    return snapped;
  }

  static Future<RouteResult> calculateRoute({
    required List<List<double>> waypoints,
    required String profile,
    int alternativeIdx = 0,
    bool shortestCarRoute = false,
    bool avoidMotorwaysCarRoute = false,
    List<NogoArea> nogos = const [],
  }) async {
    final wps = await _snapForCar(waypoints, profile);
    if (alternativeIdx == 0 &&
        !shortestCarRoute &&
        !avoidMotorwaysCarRoute &&
        nogos.isEmpty &&
        wps.length >= 2) {
      final offline = offlineRouter;
      if (offline != null &&
          await offline.canRoute(
            startLon: wps.first[0],
            startLat: wps.first[1],
            endLon: wps.last[0],
            endLat: wps.last[1],
          )) {
        try {
          return await offline.calculate(waypoints: wps, profile: profile);
        } on OfflineRoutingException {
          // Local data can be incomplete even when both endpoints snap to the
          // graph. Fall back to the server route for the production app.
        }
      }
    }
    return _fetchOne(
      wps: wps,
      profile: profile,
      alternativeIdx: alternativeIdx,
      shortestCarRoute: shortestCarRoute,
      avoidMotorwaysCarRoute: avoidMotorwaysCarRoute,
      nogos: nogos,
    );
  }

  /// Fetches the primary route plus up to two alternatives in parallel.
  /// Routes whose distance differs by less than 1% from the primary are
  /// dropped as duplicates — BRouter sometimes returns the same path for
  /// alternativeidx 0/1/2 when no real alternative exists.
  static Future<List<RouteResult>> calculateRoutesWithAlternatives({
    required List<List<double>> waypoints,
    required String profile,
    List<NogoArea> nogos = const [],
  }) async {
    final wps = await _snapForCar(waypoints, profile);
    final futures = [0, 1, 2].map((idx) =>
        _fetchOne(wps: wps, profile: profile, alternativeIdx: idx, nogos: nogos)
            .then<RouteResult?>((r) => r)
            .catchError((_) => null));
    final results = await Future.wait(futures);
    final primary = results[0];
    if (primary == null) {
      throw Exception('Routing failed');
    }
    final out = <RouteResult>[primary];
    for (int i = 1; i < results.length; i++) {
      final r = results[i];
      if (r == null) continue;
      final dup = out.any((existing) =>
          ((r.distance - existing.distance).abs() / existing.distance) < 0.01);
      if (!dup) out.add(r);
    }
    return out;
  }

  static Future<RouteResult> _fetchOne({
    required List<List<double>> wps,
    required String profile,
    required int alternativeIdx,
    bool shortestCarRoute = false,
    bool avoidMotorwaysCarRoute = false,
    required List<NogoArea> nogos,
  }) async {
    final lonlats = wps.map((w) => '${w[0]},${w[1]}').join('|');
    final uri = Uri.parse('$baseUrl?lonlats=$lonlats'
        '&${_profileParam(
          profile,
          shortestCarRoute: shortestCarRoute,
          avoidMotorwaysCarRoute: avoidMotorwaysCarRoute,
        )}'
        '&alternativeidx=$alternativeIdx'
        '&format=geojson'
        '&timode=3'
        '${_nogosParam(nogos)}');

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Routing failed: ${response.body}');
    }
    final geojson = jsonDecode(response.body) as Map<String, dynamic>;
    return RouteResult.fromGeojson(geojson);
  }

  static Future<RouteResult> _fetchRoundtripOnce({
    required List<double> start,
    required String profile,
    required int radius,
    required int direction,
    List<NogoArea> nogos = const [],
  }) async {
    final snapped = (await _snapForCar([start], profile)).first;
    final uri = Uri.parse('$baseUrl?lonlats=${snapped[0]},${snapped[1]}'
        '&${_profileParam(profile)}'
        '&engineMode=4'
        '&roundTripDistance=$radius'
        '&direction=$direction'
        '&format=geojson'
        '&timode=3'
        '${_nogosParam(nogos)}');

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Roundtrip failed: ${response.body}');
    }

    final geojson = jsonDecode(response.body) as Map<String, dynamic>;
    return RouteResult.fromGeojson(geojson);
  }

  // BRouter's engineMode=4 `roundTripDistance` parameter is a search radius;
  // the actual route circumference is roughly radius × 4–8 depending on
  // profile and how curvy the local network is. We start from radius =
  // target / 5, then iterate with a square-root-dampened correction so a
  // 10× first miss doesn't collapse the radius to a useless value on the
  // next try. The hiking profile in particular detours to reach trails,
  // so a single naive correction would either overshoot or oscillate.
  static const _roundtripRadiusDivisor = 5.0;
  static const _roundtripMinRadius = 150;
  static const _roundtripMaxIters = 8;
  static const _roundtripAcceptToleranceLow = 0.85;
  static const _roundtripAcceptToleranceHigh = 1.15;
  static const _roundtripFailToleranceLow = 0.5;
  static const _roundtripFailToleranceHigh = 1.8;

  static Future<RouteResult> calculateRoundtrip({
    required List<double> start,
    required String profile,
    required int distanceKm,
    required int direction,
    List<NogoArea> nogos = const [],
  }) {
    final targetM = distanceKm * 1000.0;
    return _convergeRoundtrip(
      target: targetM,
      metricOf: (r) => r.distance * 1000,
      initialRadius: max(
        _roundtripMinRadius,
        (targetM / _roundtripRadiusDivisor).round(),
      ),
      start: start,
      profile: profile,
      direction: direction,
      nogos: nogos,
    );
  }

  static Future<RouteResult> calculateRoundtripByTime({
    required List<double> start,
    required String profile,
    required int timeMinutes,
    required int avgSpeedKmh,
    required int direction,
    List<NogoArea> nogos = const [],
  }) {
    final targetSeconds = timeMinutes * 60.0;
    final estimatedKm = timeMinutes / 60.0 * avgSpeedKmh;
    return _convergeRoundtrip(
      target: targetSeconds,
      metricOf: (r) => r.time,
      initialRadius: max(
        _roundtripMinRadius,
        (estimatedKm * 1000 / _roundtripRadiusDivisor).round(),
      ),
      start: start,
      profile: profile,
      direction: direction,
      nogos: nogos,
    );
  }

  /// Finds the `roundTripDistance` radius whose loop hits [target] (metres for
  /// distance plans, seconds for time plans via [metricOf]). BRouter's
  /// radius→length relation is monotonic but nonlinear and location-dependent,
  /// so we *bracket* the target — one radius that comes up short, one that
  /// overshoots — and then converge by false position, falling back to
  /// bisection whenever a step would leave the bracket. This replaces the old
  /// sqrt-damped single-variable correction, which oscillated and failed to
  /// converge on sparse road networks (e.g. rural roundtrips returning nothing).
  static Future<RouteResult> _convergeRoundtrip({
    required double target,
    required double Function(RouteResult) metricOf,
    required int initialRadius,
    required List<double> start,
    required String profile,
    required int direction,
    required List<NogoArea> nogos,
  }) async {
    var radius = max(_roundtripMinRadius, initialRadius);

    RouteResult? best;
    var bestErr = double.infinity;

    // Bracket endpoints: lo = a radius whose loop is too short, hi = too long.
    int? loR;
    double? loV;
    int? hiR;
    double? hiV;

    for (var i = 0; i < _roundtripMaxIters; i++) {
      final result = await _fetchRoundtripOnce(
        start: start,
        profile: profile,
        radius: radius,
        direction: direction,
        nogos: nogos,
      );
      final v = metricOf(result);
      final ratio = v / target;
      final err = (ratio - 1.0).abs();
      if (err < bestErr) {
        bestErr = err;
        best = result;
      }
      if (ratio >= _roundtripAcceptToleranceLow &&
          ratio <= _roundtripAcceptToleranceHigh) {
        break;
      }

      if (v < target) {
        loR = radius;
        loV = v;
      } else {
        hiR = radius;
        hiV = v;
      }

      int next;
      if (loR != null && hiR != null) {
        // Both sides known → false position on (radius → metric), clamped
        // strictly inside the bracket so the interval always shrinks.
        final lo = loR;
        final hi = hiR;
        final lv = loV!;
        final hv = hiV!;
        final span = hv - lv;
        final fp = span.abs() < 1e-6
            ? (lo + hi) / 2
            : lo + (hi - lo) * (target - lv) / span;
        next = fp.round();
        if (next <= lo || next >= hi) {
          next = ((lo + hi) / 2).round();
        }
      } else if (hiR != null) {
        next = (radius * 0.6).round(); // only overshoots seen → shrink
      } else {
        next = (radius * 1.7).round(); // only short loops seen → grow
      }
      next = max(_roundtripMinRadius, next);
      if (next == radius) break; // converged onto the radius grid; keep best
      radius = next;
    }

    final finalRatio = metricOf(best!) / target;
    if (finalRatio < _roundtripFailToleranceLow ||
        finalRatio > _roundtripFailToleranceHigh) {
      throw Exception(
        'roundtrip_off_target:${best.distance.toStringAsFixed(1)}',
      );
    }
    return best;
  }

  static Future<String> fetchGpx({
    required List<List<double>> waypoints,
    required String profile,
    List<NogoArea> nogos = const [],
  }) async {
    final wps = await _snapForCar(waypoints, profile);
    final lonlats = wps.map((w) => '${w[0]},${w[1]}').join('|');
    final uri = Uri.parse('$baseUrl?lonlats=$lonlats'
        '&${_profileParam(profile)}'
        '&format=gpx'
        '&timode=3'
        '${_nogosParam(nogos)}');

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('GPX export failed');
    }
    return response.body;
  }

  static Future<String> fetchRoundtripGpx({
    required List<double> start,
    required String profile,
    required int distanceKm,
    required int direction,
    List<NogoArea> nogos = const [],
  }) async {
    final radius = (distanceKm * 1000 / pi).round();
    final snapped = (await _snapForCar([start], profile)).first;
    final uri = Uri.parse('$baseUrl?lonlats=${snapped[0]},${snapped[1]}'
        '&${_profileParam(profile)}'
        '&engineMode=4'
        '&roundTripDistance=$radius'
        '&direction=$direction'
        '&format=gpx'
        '&timode=3'
        '${_nogosParam(nogos)}');

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('GPX export failed');
    }
    return response.body;
  }
}
