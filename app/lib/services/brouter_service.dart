import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/route_result.dart';

class BRouterService {
  static String baseUrl = kIsWeb
      ? '/brouter'
      : 'https://bikerouter.thomas-peterson.de/brouter';

  static Future<RouteResult> calculateRoute({
    required List<List<double>> waypoints,
    required String profile,
    int alternativeIdx = 0,
  }) async {
    final lonlats = waypoints.map((w) => '${w[0]},${w[1]}').join('|');
    final uri = Uri.parse('$baseUrl?lonlats=$lonlats'
        '&profile=$profile'
        '&alternativeidx=$alternativeIdx'
        '&format=geojson'
        '&timode=3');

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Routing failed: ${response.body}');
    }

    final geojson = jsonDecode(response.body) as Map<String, dynamic>;
    return RouteResult.fromGeojson(geojson);
  }

  static Future<RouteResult> calculateRoundtrip({
    required List<double> start,
    required String profile,
    required int distanceKm,
    required int direction,
  }) async {
    final targetDistance = distanceKm * 1000.0; // meters
    var radius = (targetDistance / pi).round();

    RouteResult? result;
    // Iteratively adjust radius to match target distance
    for (var i = 0; i < 3; i++) {
      final uri = Uri.parse('$baseUrl?lonlats=${start[0]},${start[1]}'
          '&profile=$profile'
          '&engineMode=4'
          '&roundTripDistance=$radius'
          '&direction=$direction'
          '&format=geojson'
          '&timode=3');

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Roundtrip failed: ${response.body}');
      }

      final geojson = jsonDecode(response.body) as Map<String, dynamic>;
      result = RouteResult.fromGeojson(geojson);

      final actualDistance = result.distance * 1000; // km → m
      final ratio = actualDistance / targetDistance;
      // Close enough (within 10%)
      if ((ratio - 1.0).abs() < 0.10) break;
      // Adjust radius inversely proportional to the deviation
      radius = (radius / ratio).round();
    }

    return result!;
  }

  static Future<String> fetchGpx({
    required List<List<double>> waypoints,
    required String profile,
  }) async {
    final lonlats = waypoints.map((w) => '${w[0]},${w[1]}').join('|');
    final uri = Uri.parse('$baseUrl?lonlats=$lonlats'
        '&profile=$profile'
        '&format=gpx'
        '&timode=3');

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
  }) async {
    final radius = (distanceKm * 1000 / pi).round();
    final uri = Uri.parse('$baseUrl?lonlats=${start[0]},${start[1]}'
        '&profile=$profile'
        '&engineMode=4'
        '&roundTripDistance=$radius'
        '&direction=$direction'
        '&format=gpx'
        '&timode=3');

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('GPX export failed');
    }
    return response.body;
  }
}
