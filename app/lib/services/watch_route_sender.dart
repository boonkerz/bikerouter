import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_result.dart';

/// Sends a complete route from the phone to the paired Apple Watch
/// so the watch can later navigate it standalone (Phase 1 just stores
/// the route on the watch — actual standalone-navigation is Phase 2).
///
/// The payload is a JSON object with:
///   * id: UUID-ish string (timestamp + hash)
///   * name: user-visible label
///   * profile: BRouter profile id (only used for icon on the watch)
///   * distanceKm / ascentM / timeMinutes
///   * waypoints: [{lat, lon, name?}]
///   * polyline: encoded Google polyline of every routed point
///   * turnHints: [{idx, cmd, street?}]
///
/// We use `transferFile` on the native side (not `transferUserInfo`
/// which is capped at ~65KB) so 100+ km routes go through cleanly.
class WatchRouteSender {
  WatchRouteSender._();
  static final WatchRouteSender instance = WatchRouteSender._();

  static const MethodChannel _channel = MethodChannel('wegwiesel/watch');

  bool get _isSupportedPlatform => Platform.isIOS || Platform.isAndroid;

  /// Serialize and ship the route. Returns true if the platform side
  /// accepted the payload — that only means it's queued for delivery,
  /// not that the watch has received it (no good way to know without
  /// a watch-side ack channel, deferred to Phase 2).
  Future<bool> sendRoute({
    required RouteResult route,
    required List<LatLng> waypoints,
    Map<String, String> waypointNames = const {},
    required String profile,
    required String name,
  }) async {
    if (!_isSupportedPlatform) return false;
    final payload = _serialise(
      route: route,
      waypoints: waypoints,
      waypointNames: waypointNames,
      profile: profile,
      name: name,
    );
    try {
      final ok = await _channel.invokeMethod<bool>('sendRoute', payload);
      return ok ?? false;
    } catch (e, st) {
      if (kDebugMode) debugPrint('watch sendRoute failed: $e\n$st');
      return false;
    }
  }

  Map<String, Object?> _serialise({
    required RouteResult route,
    required List<LatLng> waypoints,
    required Map<String, String> waypointNames,
    required String profile,
    required String name,
  }) {
    final encoded = _encodePolyline(route.coordinates);
    // Time is in seconds on RouteResult — present as minutes which is
    // what the watch UI wants.
    final timeMin = (route.time / 60).round();
    return {
      'id': _generateId(name),
      'name': name,
      'profile': profile,
      'distanceKm': route.distance,
      'ascentM': route.ascent.round(),
      'timeMinutes': timeMin,
      'waypoints': [
        for (final w in waypoints)
          {
            'lat': w.latitude,
            'lon': w.longitude,
            if (waypointNames['${w.latitude.toStringAsFixed(5)},'
                    '${w.longitude.toStringAsFixed(5)}'] !=
                null)
              'name': waypointNames['${w.latitude.toStringAsFixed(5)},'
                  '${w.longitude.toStringAsFixed(5)}']!,
          },
      ],
      'polyline': encoded,
      'turnHints': [
        for (final h in route.turnHints)
          {
            'idx': h.coordIndex,
            'cmd': h.cmd.name,
          },
      ],
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Generates a short, stable-ish id from name + timestamp. The watch
  /// uses this for de-duplication when the same route gets sent twice.
  String _generateId(String name) {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final h = name.codeUnits.fold<int>(0, (a, c) => (a * 31 + c) & 0xffff)
        .toRadixString(16)
        .padLeft(4, '0');
    return '$ts-$h';
  }

  /// Google encoded-polyline format. RouteResult coordinates are
  /// [lon, lat, elev] triples — we only encode lat/lon, elevation is
  /// dropped (the watch doesn't need it for navigation, and dropping
  /// it cuts payload size by a third).
  String _encodePolyline(List<List<double>> coords) {
    final buf = StringBuffer();
    int prevLat = 0, prevLon = 0;
    for (final c in coords) {
      final lat = (c[1] * 1e5).round();
      final lon = (c[0] * 1e5).round();
      _encodeVarint(buf, lat - prevLat);
      _encodeVarint(buf, lon - prevLon);
      prevLat = lat;
      prevLon = lon;
    }
    return buf.toString();
  }

  /// Single-value polyline varint encoder. See
  /// developers.google.com/maps/documentation/utilities/polylinealgorithm
  void _encodeVarint(StringBuffer buf, int v) {
    int s = v < 0 ? ~(v << 1) : v << 1;
    while (s >= 0x20) {
      buf.writeCharCode((0x20 | (s & 0x1f)) + 63);
      s >>= 5;
    }
    buf.writeCharCode(s + 63);
  }

  /// For debugging — log the JSON the bridge would receive.
  String debugSerialise({
    required RouteResult route,
    required List<LatLng> waypoints,
    Map<String, String> waypointNames = const {},
    required String profile,
    required String name,
  }) {
    return jsonEncode(_serialise(
      route: route,
      waypoints: waypoints,
      waypointNames: waypointNames,
      profile: profile,
      name: name,
    ));
  }
}
