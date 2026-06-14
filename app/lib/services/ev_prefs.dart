import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Electric-car battery + consumption settings for the EV range estimator and
/// charging-stop planner on the car / car-trailer profiles. The kWh twin of
/// [EbikePrefs]. The energy model is deliberately simple — per-km consumption
/// plus a small climb surcharge; real draw swings ±30 % with speed, payload,
/// HVAC and regen, hence the disclaimer in the UI.
class EvPrefs {
  static const _keyEnabled = 'ev_enabled_v1';
  static const _keyBatteryKwh = 'ev_battery_kwh_v1';
  static const _keyConsumption = 'ev_consumption_kwh100_v1';
  static const _keyStartPct = 'ev_start_pct_v1';

  static const defaultBatteryKwh = 58.0; // typical 2020s mid-size usable pack
  static const defaultConsumption = 18.0; // kWh / 100 km, mixed driving
  static const defaultStartPct = 90; // assume you set off near-full
  // Uphill surcharge: lifting ~1.8 t one metre is ~0.005 kWh, but regen claws
  // a chunk back on the way down, so net ~0.003 kWh per ascended metre. Rough.
  static const climbKwhPerM = 0.003;
  // Fallback charger power when a station has no usable power tag — used for the
  // charge-time estimate in the planner dialog.
  static const defaultChargerKw = 50.0;

  static bool _enabled = false;
  static double _batteryKwh = defaultBatteryKwh;
  static double _consumption = defaultConsumption;
  static int _startPct = defaultStartPct;
  static bool _loaded = false;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _enabled = p.getBool(_keyEnabled) ?? false;
    _batteryKwh = p.getDouble(_keyBatteryKwh) ?? defaultBatteryKwh;
    _consumption = p.getDouble(_keyConsumption) ?? defaultConsumption;
    _startPct = p.getInt(_keyStartPct) ?? defaultStartPct;
    _loaded = true;
  }

  static bool get isLoaded => _loaded;
  static bool get enabled => _enabled;
  static double get batteryKwh => _batteryKwh;
  static double get consumptionKwh100 => _consumption;
  static int get startPct => _startPct;

  /// Energy available from the current charge (kWh).
  static double get usableKwh => _batteryKwh * _startPct / 100.0;

  static Future<void> setEnabled(bool v) async {
    _enabled = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyEnabled, v);
  }

  static Future<void> setConfig({
    required double batteryKwh,
    required double consumptionKwh100,
    required int startPct,
  }) async {
    _batteryKwh = batteryKwh;
    _consumption = consumptionKwh100;
    _startPct = startPct;
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_keyBatteryKwh, batteryKwh);
    await p.setDouble(_keyConsumption, consumptionKwh100);
    await p.setInt(_keyStartPct, startPct);
  }

  /// kWh the route draws: per-km consumption + a small climb surcharge.
  static double estimateKwhForRoute({
    required double distanceKm,
    required int ascentM,
  }) {
    return distanceKm * _consumption / 100.0 + ascentM * climbKwhPerM;
  }

  /// kWh for the worst single leg of a route that has charging stops — each
  /// stop refills the pack, so "will I make it?" is the most-demanding stretch
  /// between start / charge / finish. Mirrors EbikePrefs.estimateWorstLegWh.
  static double estimateWorstLegKwh({
    required List<List<double>> coords,
    required List<List<double>> stopLatLngs,
  }) {
    if (coords.length < 2) return 0;
    final splitIdx = <int>[];
    for (final s in stopLatLngs) {
      final idx = _nearestCoordIndex(coords, s[0], s[1]);
      if (idx > 0 && idx < coords.length - 1) splitIdx.add(idx);
    }
    splitIdx.sort();

    var worst = 0.0;
    var leg = 0.0;
    var next = 0;
    for (int i = 1; i < coords.length; i++) {
      final segKm = _haversineKm(
          coords[i - 1][1], coords[i - 1][0], coords[i][1], coords[i][0]);
      final elevPrev = coords[i - 1].length >= 3 ? coords[i - 1][2] : 0.0;
      final elevCur = coords[i].length >= 3 ? coords[i][2] : 0.0;
      final dEl = elevCur - elevPrev;
      final ascentM = dEl > 0 ? dEl : 0.0;
      leg += segKm * _consumption / 100.0 + ascentM * climbKwhPerM;
      if (next < splitIdx.length && i == splitIdx[next]) {
        if (leg > worst) worst = leg;
        leg = 0;
        next++;
      }
    }
    if (leg > worst) worst = leg;
    return worst;
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
