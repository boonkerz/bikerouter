import 'dart:math';

import '../models/route_result.dart';
import '../models/route_poi.dart';
import 'ebike_prefs.dart';
import 'route_poi_search_service.dart';

/// Result of planning charging stops for an over-budget e-bike tour.
class ChargingPlan {
  /// Stops to insert, in route order. Empty when the tour already
  /// fits the pack or no usable station was found at all.
  final List<RoutePoiHit> stops;

  /// True when the greedy planner ran out of reachable stations on
  /// some leg — i.e. the stops we *did* find don't fully cover the
  /// tour and the rider will still run dry somewhere. The UI warns
  /// about this instead of pretending the tour is solved.
  final bool incomplete;

  const ChargingPlan({required this.stops, required this.incomplete});

  bool get isEmpty => stops.isEmpty;
}

/// Plans charging stops along a route so no single leg between charges
/// (or between start/charge/finish) exceeds the rider's pack capacity.
///
/// The old version placed a single stop at ~70% of the pack, which is
/// wrong for tours that need more than one charge: to *reach* a stop
/// you must spend ≤ capacity, and the *remainder* after charging must
/// also be ≤ capacity, so a tour over ~2× the pack genuinely needs
/// multiple stops. This planner is greedy — it pushes each stop as
/// late as the battery safely allows, then recharges and repeats.
class EbikeChargingPlanner {
  // Charge before the pack is fully empty — keep a 10% reserve for
  // detours / headwind / the off-route hop to the station itself.
  static const _usableFraction = 0.9;
  // Don't suggest a charge in the first half of a leg's reachable
  // range — stopping that early wastes the pack.
  static const _earliestFraction = 0.5;
  // Stations further than this from the route aren't worth the detour.
  static const _maxSideMeters = 1500.0;
  // Safety cap so a pathological route can't loop forever.
  static const _maxStops = 6;

  /// Builds a [ChargingPlan] for [route]. Returns an empty plan when
  /// the tour fits the pack outright.
  static Future<ChargingPlan> plan(RouteResult route) async {
    if (route.coordinates.length < 2) {
      return const ChargingPlan(stops: [], incomplete: false);
    }
    final capacityWh = EbikePrefs.capacityWh.toDouble();
    if (capacityWh <= 0) {
      return const ChargingPlan(stops: [], incomplete: false);
    }

    // Cumulative km + Wh per coordinate — the spend curve we walk to
    // map "km along route" <-> "Wh consumed so far".
    final cumKm = <double>[0];
    final cumWh = <double>[0];
    final coords = route.coordinates;
    var km = 0.0;
    var wh = 0.0;
    for (int i = 1; i < coords.length; i++) {
      final segKm = _haversineKm(
        coords[i - 1][1], coords[i - 1][0],
        coords[i][1], coords[i][0],
      );
      final elevPrev = coords[i - 1].length >= 3 ? coords[i - 1][2] : 0.0;
      final elevCur = coords[i].length >= 3 ? coords[i][2] : 0.0;
      final dEl = elevCur - elevPrev;
      final ascentM = dEl > 0 ? dEl : 0.0;
      km += segKm;
      wh += segKm * 7 + ascentM * 0.5;
      cumKm.add(km);
      cumWh.add(wh);
    }
    final totalKm = cumKm.last;
    final totalWh = cumWh.last;
    if (totalWh <= capacityWh) {
      return const ChargingPlan(stops: [], incomplete: false);
    }

    // Pull every charging station along the route once; the greedy
    // loop filters per leg from this list.
    final hits = await RoutePoiSearchService.searchAlongRoute(
      coordinates: route.coordinates,
      categories: {PoiCategory.charging},
    );
    final usable = hits.where((h) => h.sideMeters <= _maxSideMeters).toList()
      ..sort((a, b) => a.routeKm.compareTo(b.routeKm));

    final budget = capacityWh * _usableFraction;
    final stops = <RoutePoiHit>[];
    var legStartWh = 0.0; // Wh consumed at the last charge / start.
    var legStartKm = 0.0;
    var incomplete = false;

    while (stops.length < _maxStops) {
      // Where does this leg run out? cumWh reaching legStartWh + budget.
      final limitWh = legStartWh + budget;
      final reachKm = _kmAtWh(cumKm, cumWh, limitWh);
      // Whole remainder fits the pack → done.
      if (_whAtKm(cumKm, cumWh, totalKm) - legStartWh <= budget ||
          reachKm >= totalKm) {
        break;
      }
      // Search window: don't stop too early, never past the reach.
      final windowMinKm =
          legStartKm + (reachKm - legStartKm) * _earliestFraction;
      final candidates = usable
          .where((h) => h.routeKm > windowMinKm && h.routeKm <= reachKm)
          .toList();
      if (candidates.isEmpty) {
        // No station before the battery dies on this leg.
        incomplete = true;
        break;
      }
      // Push the stop as late as safely possible (max routeKm), so we
      // use the most range before charging; break near-ties by detour.
      candidates.sort((a, b) {
        final byKm = b.routeKm.compareTo(a.routeKm);
        if (byKm != 0) return byKm;
        return a.sideMeters.compareTo(b.sideMeters);
      });
      final chosen = candidates.first;
      // Avoid picking the same station twice (degenerate geometry).
      if (stops.any((s) => s.osmId == chosen.osmId)) {
        incomplete = true;
        break;
      }
      stops.add(chosen);
      legStartKm = chosen.routeKm;
      legStartWh = _whAtKm(cumKm, cumWh, chosen.routeKm);
    }

    // Re-order stops by route position for insertion.
    stops.sort((a, b) => a.routeKm.compareTo(b.routeKm));
    return ChargingPlan(stops: stops, incomplete: incomplete);
  }

  /// First km at which cumulative Wh reaches [targetWh] (linear
  /// interpolation between samples). Clamps to the route end.
  static double _kmAtWh(List<double> cumKm, List<double> cumWh, double targetWh) {
    for (int i = 1; i < cumWh.length; i++) {
      if (cumWh[i] >= targetWh) {
        final span = cumWh[i] - cumWh[i - 1];
        final t = span > 0 ? (targetWh - cumWh[i - 1]) / span : 0.0;
        return cumKm[i - 1] + (cumKm[i] - cumKm[i - 1]) * t;
      }
    }
    return cumKm.last;
  }

  /// Cumulative Wh consumed at [km] along the route.
  static double _whAtKm(List<double> cumKm, List<double> cumWh, double km) {
    for (int i = 1; i < cumKm.length; i++) {
      if (cumKm[i] >= km) {
        final span = cumKm[i] - cumKm[i - 1];
        final t = span > 0 ? (km - cumKm[i - 1]) / span : 0.0;
        return cumWh[i - 1] + (cumWh[i] - cumWh[i - 1]) * t;
      }
    }
    return cumWh.last;
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
