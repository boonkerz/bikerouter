import 'package:shared_preferences/shared_preferences.dart';

/// Presets bundle the SAC difficulty limit plus matching knobs into a single
/// user-facing choice. Stored as the enum index so the schema survives
/// reorderings as long as we don't insert in the middle.
enum HikingPreset {
  /// Easy walking, paved/gravel paths and trails up to SAC T1 only.
  comfortable,

  /// Default: trails up to T3 (demanding mountain hiking). Matches the
  /// hiking-beta out-of-the-box behaviour.
  sporty,

  /// Anything goes, up to T6 (difficult alpine hiking). Use at own risk.
  mountain,
}

/// User-tunable BRouter knobs for the hiking profile.
class HikingPrefs {
  static const _keyPreferRoutes = 'hiking_prefer_routes_v1';
  static const _keyPreset = 'hiking_preset_v1';
  static bool _preferRoutes = true;
  static HikingPreset _preset = HikingPreset.sporty;
  static bool _loaded = false;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _preferRoutes = p.getBool(_keyPreferRoutes) ?? true;
    final idx = p.getInt(_keyPreset);
    if (idx != null && idx >= 0 && idx < HikingPreset.values.length) {
      _preset = HikingPreset.values[idx];
    }
    _loaded = true;
  }

  static bool get preferHikingRoutes => _preferRoutes;
  static HikingPreset get preset => _preset;
  static bool get isLoaded => _loaded;

  /// Highest SAC level (1..6) the router is allowed to use.
  /// See https://wiki.openstreetmap.org/wiki/Key:sac_scale.
  static int get sacScaleLimit {
    switch (_preset) {
      case HikingPreset.comfortable:
        return 1;
      case HikingPreset.sporty:
        return 3;
      case HikingPreset.mountain:
        return 6;
    }
  }

  static Future<void> setPreferHikingRoutes(bool value) async {
    _preferRoutes = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyPreferRoutes, value);
  }

  static Future<void> setPreset(HikingPreset preset) async {
    _preset = preset;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyPreset, preset.index);
  }
}
