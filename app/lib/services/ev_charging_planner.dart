import 'dart:math';

import '../models/route_result.dart';
import '../models/route_poi.dart';
import 'charging_price_service.dart';
import 'ev_prefs.dart';
import 'route_poi_search_service.dart';

/// Result of planning EV charging stops for an over-range car tour.
class EvChargingPlan {
  /// Stops to insert, in route order. Empty when the tour already fits the
  /// usable charge or no usable station was found.
  final List<RoutePoiHit> stops;

  /// Other reachable stations near each stop (same index as [stops]), so the
  /// user can pick a different one — e.g. one with a known ad-hoc price.
  final List<List<RoutePoiHit>> alternatives;

  /// True when a leg had no reachable station — the stops we found don't fully
  /// cover the tour and the car will still run flat somewhere.
  final bool incomplete;

  const EvChargingPlan({
    required this.stops,
    required this.incomplete,
    this.alternatives = const [],
  });

  bool get isEmpty => stops.isEmpty;
}

/// Plans charging stops along a route so no single leg between charges exceeds
/// the car's usable charge. The kWh twin of [EbikeChargingPlanner]: greedy,
/// pushing each stop as late as the battery safely allows, then recharging.
class EvChargingPlanner {
  // Arrive at each charge with ~10 % reserve for detours / HVAC / the hop to
  // the station itself.
  static const _usableFraction = 0.9;
  // Don't suggest a charge in the first half of a leg's reachable range.
  static const _earliestFraction = 0.5;
  // Cars happily detour further than e-bikes for a charger.
  static const _maxSideMeters = 3000.0;
  static const _maxStops = 6;

  static Future<EvChargingPlan> plan(RouteResult route) async {
    if (route.coordinates.length < 2) {
      return const EvChargingPlan(stops: [], incomplete: false);
    }
    final usableKwh = EvPrefs.usableKwh;
    if (usableKwh <= 0) {
      return const EvChargingPlan(stops: [], incomplete: false);
    }

    // Cumulative km + kWh per coordinate — the spend curve.
    final cumKm = <double>[0];
    final cumKwh = <double>[0];
    final coords = route.coordinates;
    var km = 0.0;
    var e = 0.0;
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
      e += segKm * EvPrefs.consumptionKwh100 / 100.0 +
          ascentM * EvPrefs.climbKwhPerM;
      cumKm.add(km);
      cumKwh.add(e);
    }
    final totalKm = cumKm.last;
    final totalKwh = cumKwh.last;
    if (totalKwh <= usableKwh) {
      return const EvChargingPlan(stops: [], incomplete: false);
    }

    final hits = await RoutePoiSearchService.searchAlongRoute(
      coordinates: route.coordinates,
      categories: {PoiCategory.charging},
    );
    final usable = hits.where((h) => h.sideMeters <= _maxSideMeters).toList()
      ..sort((a, b) => a.routeKm.compareTo(b.routeKm));

    // Load real ad-hoc prices for the candidate stations so we can prefer a
    // priced one (and show priced alternatives). Best-effort.
    await ChargingPriceService.instance
        .loadAround(usable.map((h) => (lat: h.lat, lon: h.lon)));
    bool priced(RoutePoiHit h) =>
        ChargingPriceService.instance.lookup(h.lat, h.lon) != null;

    final budget = usableKwh * _usableFraction;
    final stops = <RoutePoiHit>[];
    final alternatives = <List<RoutePoiHit>>[];
    var legStartKwh = 0.0;
    var legStartKm = 0.0;
    var incomplete = false;

    while (stops.length < _maxStops) {
      final limit = legStartKwh + budget;
      final reachKm = _kmAt(cumKm, cumKwh, limit);
      if (_at(cumKm, cumKwh, totalKm) - legStartKwh <= budget ||
          reachKm >= totalKm) {
        break;
      }
      final windowMinKm =
          legStartKm + (reachKm - legStartKm) * _earliestFraction;
      final candidates = usable
          .where((h) => h.routeKm > windowMinKm && h.routeKm <= reachKm)
          .where((h) => !stops.any((s) => s.osmId == h.osmId))
          .toList();
      if (candidates.isEmpty) {
        incomplete = true;
        break;
      }
      // Prefer stations with a known ad-hoc price; among the chosen pool take
      // the one furthest along the leg (latest safe charge). Reachability is
      // preserved because every candidate is within the reachable window.
      final pricedCandidates = candidates.where(priced).toList();
      final pool = pricedCandidates.isNotEmpty ? pricedCandidates : candidates;
      pool.sort((a, b) {
        final byKm = b.routeKm.compareTo(a.routeKm);
        if (byKm != 0) return byKm;
        return a.sideMeters.compareTo(b.sideMeters);
      });
      final chosen = pool.first;
      stops.add(chosen);

      // Up to 3 nearby alternatives (priced first, then closest along route).
      final alts = candidates.where((h) => h.osmId != chosen.osmId).toList()
        ..sort((a, b) {
          final pa = priced(a) ? 0 : 1;
          final pb = priced(b) ? 0 : 1;
          if (pa != pb) return pa - pb;
          return (a.routeKm - chosen.routeKm)
              .abs()
              .compareTo((b.routeKm - chosen.routeKm).abs());
        });
      alternatives.add(alts.take(3).toList());

      legStartKm = chosen.routeKm;
      legStartKwh = _at(cumKm, cumKwh, chosen.routeKm);
    }

    return EvChargingPlan(
      stops: stops,
      alternatives: alternatives,
      incomplete: incomplete,
    );
  }

  /// Operator / network / brand of a charging station from OSM tags (e.g.
  /// "EnBW", "Ionity", "Tesla"), or null when untagged.
  static String? operatorName(RoutePoiHit hit) {
    for (final k in const ['operator', 'network', 'brand']) {
      final v = hit.tags[k];
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  /// Rough charge-time (minutes) to put [kwh] back at [hit]'s station, using the
  /// station's advertised power when tagged, else a default fast charger.
  static int chargeMinutes(RoutePoiHit hit, double kwh) {
    final powerKw = chargerKw(hit);
    if (powerKw <= 0 || kwh <= 0) return 0;
    return (kwh / powerKw * 60).round();
  }

  /// Charger power in kW parsed from common OSM tags, falling back to the
  /// default. Handles `maxpower`/`charging_station:output`/`socket:*:output`
  /// values like "150 kW", "150000" (watts) or "22".
  static double chargerKw(RoutePoiHit hit) {
    for (final key in const [
      'maxpower',
      'charging_station:output',
      'socket:type2_combo:output',
      'socket:type2:output',
      'socket:chademo:output',
    ]) {
      final raw = hit.tags[key];
      final v = _parsePower(raw);
      if (v != null) return v;
    }
    return EvPrefs.defaultChargerKw;
  }

  static double? _parsePower(String? raw) {
    if (raw == null) return null;
    final m = RegExp(r'([\d.]+)').firstMatch(raw);
    if (m == null) return null;
    final n = double.tryParse(m.group(1)!);
    if (n == null) return null;
    // Values without "kW" and ≥ 1000 are almost certainly watts.
    if (!raw.toLowerCase().contains('kw') && n >= 1000) return n / 1000.0;
    return n;
  }

  static double _kmAt(List<double> cumKm, List<double> cumE, double target) {
    for (int i = 1; i < cumE.length; i++) {
      if (cumE[i] >= target) {
        final span = cumE[i] - cumE[i - 1];
        final t = span > 0 ? (target - cumE[i - 1]) / span : 0.0;
        return cumKm[i - 1] + (cumKm[i] - cumKm[i - 1]) * t;
      }
    }
    return cumKm.last;
  }

  static double _at(List<double> cumKm, List<double> cumE, double km) {
    for (int i = 1; i < cumKm.length; i++) {
      if (cumKm[i] >= km) {
        final span = cumKm[i] - cumKm[i - 1];
        final t = span > 0 ? (km - cumKm[i - 1]) / span : 0.0;
        return cumE[i - 1] + (cumE[i] - cumE[i - 1]) * t;
      }
    }
    return cumE.last;
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
