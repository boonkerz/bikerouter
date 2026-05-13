import 'dart:async';

import '../../models/route_result.dart';

/// Abstract interface for a router that operates fully offline. Mirrors the
/// online BRouter call signature so the higher layers (map_screen,
/// navigation_screen) can swap providers transparently.
///
/// v2.0 ships a Pure-Dart port of the BRouter routing core. The first
/// release supports the `trekking` profile against pre-downloaded `.rd5`
/// segment files; additional profiles and broader region coverage land
/// in subsequent point releases.
abstract class OfflineRouter {
  /// Returns true if there is enough downloaded data on disk to plausibly
  /// route between the given lon/lat pair. Used by the routing facade to
  /// decide whether to attempt an offline calculation or fall back to the
  /// network.
  Future<bool> canRoute({
    required double startLon,
    required double startLat,
    required double endLon,
    required double endLat,
  });

  /// Compute a route between the waypoints. Throws [OfflineRoutingException]
  /// when the request cannot be served from the local segments.
  Future<RouteResult> calculate({
    required List<List<double>> waypoints, // [[lon, lat], …]
    required String profile,
  });
}

class OfflineRoutingException implements Exception {
  final String code;
  final String message;
  const OfflineRoutingException(this.code, this.message);

  @override
  String toString() => 'OfflineRoutingException($code): $message';
}
