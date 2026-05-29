import 'dart:math';

import '../models/route_result.dart';
import '../models/route_poi.dart';
import 'ebike_prefs.dart';
import 'route_poi_search_service.dart';

/// Picks a single charging-station POI along the route that's a
/// sensible place to stop for a top-up. "Sensible" means: the battery
/// will still have a comfortable buffer when the rider arrives, and
/// the station sits as close to the route as possible so the detour
/// is minimal.
class EbikeChargingPlanner {
  /// Returns a charging-station hit to suggest as a stop, or null
  /// when nothing fits the window (no station along the route, or the
  /// tour is too long for a single mid-ride charge to save).
  ///
  /// Strategy:
  ///   1. Walk the route segment-by-segment, building a cumulative
  ///      Wh-spend curve (7 Wh/flat-km + 0.5 Wh/Hm, same model as the
  ///      stats-bar badge).
  ///   2. Find the route-km where the cumulative spend hits ~70% of
  ///      the user's pack — that's the ideal stop position (still a
  ///      30% buffer to detour off-route if needed).
  ///   3. Search amenity=charging_station along the route via the
  ///      existing Overpass-backed POI service.
  ///   4. Filter hits to the window [50%, 95%] of the ideal stop km
  ///      — earlier wastes battery, later risks not making it.
  ///   5. Of the survivors, pick the one with the smallest side-
  ///      distance to the route.
  static Future<RoutePoiHit?> suggestStop(RouteResult route) async {
    if (route.coordinates.length < 2) return null;
    final capacityWh = EbikePrefs.capacityWh;
    final totalWhNeeded = EbikePrefs.estimateWhForRoute(
      distanceKm: route.distance,
      ascentM: route.ascent.round(),
    );
    // If the tour fits inside the pack we don't need a stop.
    if (totalWhNeeded <= capacityWh) return null;

    // Build cumulative km + cumulative Wh tracking per coord.
    final coords = route.coordinates;
    var cumKm = 0.0;
    var cumWh = 0.0;
    double idealStopKm = -1;
    for (int i = 1; i < coords.length; i++) {
      final segKm = _haversineKm(
        coords[i - 1][1], coords[i - 1][0],
        coords[i][1], coords[i][0],
      );
      final elevPrev = coords[i - 1].length >= 3 ? coords[i - 1][2] : 0.0;
      final elevCur = coords[i].length >= 3 ? coords[i][2] : 0.0;
      final dEl = elevCur - elevPrev;
      final ascentM = dEl > 0 ? dEl : 0.0;
      final segWh = segKm * 7 + ascentM * 0.5;
      cumKm += segKm;
      cumWh += segWh;
      // Cross the 70%-of-pack threshold → mark the route-km here as
      // the ideal stop, but keep iterating so we know the total.
      if (idealStopKm < 0 && cumWh >= capacityWh * 0.70) {
        idealStopKm = cumKm;
      }
    }
    if (idealStopKm < 0) idealStopKm = cumKm * 0.5;

    final windowMinKm = idealStopKm * 0.5;
    final windowMaxKm = min(idealStopKm * 0.95, cumKm * 0.95);

    // POI search expects coordinates as [lon, lat] pairs — that's
    // what RouteResult ships in already.
    final hits = await RoutePoiSearchService.searchAlongRoute(
      coordinates: route.coordinates,
      categories: {PoiCategory.charging},
    );
    final eligible = hits
        .where((h) => h.routeKm >= windowMinKm && h.routeKm <= windowMaxKm)
        .toList()
      ..sort((a, b) => a.sideMeters.compareTo(b.sideMeters));
    if (eligible.isEmpty) return null;
    return eligible.first;
  }

  /// Pure-Dart haversine — same algorithm the navigation screen uses,
  /// inlined here to avoid pulling in the geolocator package just for
  /// a single km calculation.
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
