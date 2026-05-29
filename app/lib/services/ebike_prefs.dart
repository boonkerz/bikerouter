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
}
