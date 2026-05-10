import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/nogo_area.dart';
import '../models/route_result.dart';
import 'profile_speed_prefs.dart';

class BRouterService {
  static String baseUrl = kIsWeb
      ? '/brouter'
      : 'https://wegwiesel.app/brouter';

  static String _nogosParam(List<NogoArea> nogos) {
    if (nogos.isEmpty) return '';
    return '&nogos=${nogos.map((n) => n.toBRouterParam()).join('|')}';
  }

  /// Wegwiesel exposes "car" and "car-trailer" as user-facing profiles.
  /// Both ride on top of BRouter's parametric `car-vario` profile, just
  /// with different defaults for vmax (incl. user override), totalweight
  /// and avoid_unpaved.
  static String _profileParam(String profile) {
    if (profile == 'car' || profile == 'car-trailer') {
      final vmax = ProfileSpeedPrefs.speedFor(profile);
      final totalweight = profile == 'car-trailer' ? 2640 : 1640;
      final avoidUnpaved = profile == 'car-trailer' ? 1 : 0;
      return 'profile=car-vario'
          '&profile:vmax=$vmax'
          '&profile:totalweight=$totalweight'
          '&profile:avoid_unpaved=$avoidUnpaved';
    }
    return 'profile=$profile';
  }

  static Future<RouteResult> calculateRoute({
    required List<List<double>> waypoints,
    required String profile,
    int alternativeIdx = 0,
    List<NogoArea> nogos = const [],
  }) async {
    final lonlats = waypoints.map((w) => '${w[0]},${w[1]}').join('|');
    final uri = Uri.parse('$baseUrl?lonlats=$lonlats'
        '&${_profileParam(profile)}'
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
    final uri = Uri.parse('$baseUrl?lonlats=${start[0]},${start[1]}'
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
    final lonlats = waypoints.map((w) => '${w[0]},${w[1]}').join('|');
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
    final uri = Uri.parse('$baseUrl?lonlats=${start[0]},${start[1]}'
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
