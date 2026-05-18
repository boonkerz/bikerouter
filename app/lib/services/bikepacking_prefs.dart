import 'package:shared_preferences/shared_preferences.dart';

import '../models/route_poi.dart';

/// Bikepacking mode is a global UX preference that nudges several features
/// toward multi-day-tour planning. Today it does two things:
///   1. Pre-selects the bikepacking-relevant POI categories in the POI sheet
///   2. Surfaces the toggle's state to the stages sheet so it can show
///      overnight suggestions automatically.
class BikepackingPrefs {
  static const _keyActive = 'bikepacking_active_v1';
  static const _keyWildCampSeen = 'bikepacking_wildcamp_disclaimer_seen_v1';
  static bool _active = false;
  static bool _wildCampDisclaimerSeen = false;
  static bool _loaded = false;

  /// Categories prioritized in POI suggestions while bikepacking mode is on.
  /// Camping for the night, water + shelter + picnic for the day, station
  /// as an escape hatch when something breaks.
  static const Set<PoiCategory> defaultCategories = {
    PoiCategory.camping,
    PoiCategory.water,
    PoiCategory.shelter,
    PoiCategory.picnic,
    PoiCategory.station,
  };

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _active = p.getBool(_keyActive) ?? false;
    _wildCampDisclaimerSeen = p.getBool(_keyWildCampSeen) ?? false;
    _loaded = true;
  }

  static bool get active => _active;
  static bool get isLoaded => _loaded;
  static bool get wildCampDisclaimerSeen => _wildCampDisclaimerSeen;

  static Future<void> setActive(bool value) async {
    _active = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyActive, value);
  }

  static Future<void> markWildCampDisclaimerSeen() async {
    _wildCampDisclaimerSeen = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyWildCampSeen, true);
  }
}
