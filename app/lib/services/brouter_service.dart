import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/nogo_area.dart';
import '../models/route_result.dart';
import 'profile_speed_prefs.dart';
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
      final avoidUnpaved = profile == 'car-trailer' ? 1 : 0;
      final shortestRoute = shortestCarRoute ? 1 : 0;
      final avoidMotorways = avoidMotorwaysCarRoute ? 1 : 0;
      // add_beeline lets BRouter draw a beeline from the user's clicked
      // waypoint to the nearest car-accessible road. Without it, taps that
      // land on bike paths or footways trigger "target island failed".
      return 'profile=wegwiesel-car'
          '&profile:vmax=$vmax'
          '&profile:totalweight=$totalweight'
          '&profile:avoid_motorways=$avoidMotorways'
          '&profile:avoid_unpaved=$avoidUnpaved'
          '&profile:shortest_route=$shortestRoute'
          '&profile:add_beeline=1';
    }
    return 'profile=$profile';
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

  static Future<RouteResult> calculateRoundtrip({
    required List<double> start,
    required String profile,
    required int distanceKm,
    required int direction,
    List<NogoArea> nogos = const [],
  }) async {
    final targetDistance = distanceKm * 1000.0; // meters
    var radius = (targetDistance / pi).round();

    RouteResult? result;
    for (var i = 0; i < 3; i++) {
      result = await _fetchRoundtripOnce(
        start: start, profile: profile, radius: radius, direction: direction,
        nogos: nogos,
      );
      final ratio = (result.distance * 1000) / targetDistance;
      if ((ratio - 1.0).abs() < 0.10) break;
      radius = (radius / ratio).round();
    }
    return result!;
  }

  static Future<RouteResult> calculateRoundtripByTime({
    required List<double> start,
    required String profile,
    required int timeMinutes,
    required int avgSpeedKmh,
    required int direction,
    List<NogoArea> nogos = const [],
  }) async {
    final targetSeconds = timeMinutes * 60.0;
    var estimatedKm = (timeMinutes / 60.0 * avgSpeedKmh);
    var radius = (estimatedKm * 1000 / pi).round();

    RouteResult? result;
    for (var i = 0; i < 3; i++) {
      result = await _fetchRoundtripOnce(
        start: start, profile: profile, radius: radius, direction: direction,
        nogos: nogos,
      );
      final ratio = result.time / targetSeconds;
      if ((ratio - 1.0).abs() < 0.10) break;
      radius = (radius / ratio).round();
    }
    return result!;
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
