import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// E-bike battery sizing for the range estimator. Users dial in
/// their own pack capacity in Watt-hours (500 Wh / 625 Wh are the
/// common 2020s sizes). The estimator then derives a "this tour
/// costs X% of your battery" badge on E-bike routes.
class EbikePrefs {
  static const _keyCapacityWh = 'ebike_capacity_wh_v1';
  // 500 Wh is the de-facto baseline pedelec battery and what most
  // mid-range Bosch / Yamaha / Shimano systems shipped with through
  // 2024. Easy to override in Settings.
  static const defaultCapacityWh = 500;

  static int _capacityWh = defaultCapacityWh;
  static bool _loaded = false;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _capacityWh = p.getInt(_keyCapacityWh) ?? defaultCapacityWh;
    _loaded = true;
  }

  static bool get isLoaded => _loaded;
  static int get capacityWh => _capacityWh;

  static Future<void> setCapacityWh(int wh) async {
    _capacityWh = wh;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyCapacityWh, wh);
  }

  /// Energy a Wegwiesel-style e-bike tour draws from the pack. The
  /// model is intentionally simple — a flat-ground baseline plus a
  /// per-metre climb cost. Numbers come from a Bosch Performance Line
  /// mid-motor in Tour mode (which is what the kinematic profile in
  /// wegwiesel-ebike.brf is tuned for):
  ///
  ///   * 7 Wh per flat km    (≈ 70 km on a 500 Wh pack)
  ///   * 0.5 Wh per ascended metre (10 Hm ≈ 5 Wh extra)
  ///
  /// Returns Wh as int — the caller compares it against [capacityWh].
  /// Tailwind, payload and assist-level changes can shift the real
  /// draw ±30%, hence the disclaimer in the UI.
  static int estimateWhForRoute({
    required double distanceKm,
    required int ascentM,
  }) {
    final wh = distanceKm * 7 + ascentM * 0.5;
    return wh.round();
  }

  /// Wh for the worst single leg of a route that has charging stops.
  /// Each stop resets the battery to full, so the relevant figure for
  /// "will I make it?" is the most-demanding stretch between
  /// start / stop / finish — not the whole-tour total. With no stops
  /// this is just the whole-route estimate.
  ///
  /// [coords] are BRouter [lon, lat, elev] triples; [stopLatLngs] are
  /// the charging-stop positions (each [lat, lon]). We split the spend
  /// curve at the coordinate nearest each stop and return the max leg.
  static int estimateWorstLegWh({
    required List<List<double>> coords,
    required List<List<double>> stopLatLngs,
  }) {
    if (coords.length < 2) return 0;
    // Index of the coordinate nearest each stop, sorted ascending.
    final splitIdx = <int>[];
    for (final s in stopLatLngs) {
      final idx = _nearestCoordIndex(coords, s[0], s[1]);
      if (idx > 0 && idx < coords.length - 1) splitIdx.add(idx);
    }
    splitIdx.sort();

    var worst = 0.0;
    var legWh = 0.0;
    var nextSplit = 0;
    for (int i = 1; i < coords.length; i++) {
      final segKm = _haversineKm(
        coords[i - 1][1], coords[i - 1][0], coords[i][1], coords[i][0]);
      final elevPrev = coords[i - 1].length >= 3 ? coords[i - 1][2] : 0.0;
      final elevCur = coords[i].length >= 3 ? coords[i][2] : 0.0;
      final dEl = elevCur - elevPrev;
      final ascentM = dEl > 0 ? dEl : 0.0;
      legWh += segKm * 7 + ascentM * 0.5;
      // Crossing a charging stop closes the current leg (battery full
      // again afterwards).
      if (nextSplit < splitIdx.length && i == splitIdx[nextSplit]) {
        if (legWh > worst) worst = legWh;
        legWh = 0;
        nextSplit++;
      }
    }
    if (legWh > worst) worst = legWh;
    return worst.round();
  }

  static int _nearestCoordIndex(
      List<List<double>> coords, double lat, double lon) {
    var best = 0;
    var bestD = double.infinity;
    for (int i = 0; i < coords.length; i++) {
      final dLat = coords[i][1] - lat;
      final dLon = coords[i][0] - lon;
      final d = dLat * dLat + dLon * dLon;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
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
