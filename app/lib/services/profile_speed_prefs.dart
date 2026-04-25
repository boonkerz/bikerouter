import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';

/// Per-profile average-speed overrides. Speeds drive ETA and time-based
/// roundtrip planning, so the user can dial e.g. gravel from 22 → 20 km/h
/// without forking BRouter profiles.
class ProfileSpeedPrefs {
  static const _key = 'profile_speed_overrides_v1';
  static final Map<String, int> _overrides = {};
  static bool _loaded = false;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        final m = (jsonDecode(raw) as Map).cast<String, dynamic>();
        _overrides
          ..clear()
          ..addEntries(m.entries.map((e) => MapEntry(e.key, (e.value as num).toInt())));
      } catch (_) {
        // ignore corrupt prefs
      }
    }
    _loaded = true;
  }

  static int speedFor(String profileId) {
    final override = _overrides[profileId];
    if (override != null) return override;
    return BikeProfile.byId(profileId)?.avgSpeedKmh ?? 20;
  }

  static int defaultSpeedFor(String profileId) {
    return BikeProfile.byId(profileId)?.avgSpeedKmh ?? 20;
  }

  static bool hasOverride(String profileId) => _overrides.containsKey(profileId);

  static Future<void> setOverride(String profileId, int kmh) async {
    _overrides[profileId] = kmh;
    await _persist();
  }

  static Future<void> clearOverride(String profileId) async {
    _overrides.remove(profileId);
    await _persist();
  }

  static Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(_overrides));
  }

  static bool get isLoaded => _loaded;
}
