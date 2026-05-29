import 'package:shared_preferences/shared_preferences.dart';

/// Stable identifiers for features that get a "NEU" / "NEW" pill on
/// their UI affordance until the user has interacted with them once.
/// Adding a new entry here ships the badge automatically — removing
/// one retires it (leaves a stale prefs entry, harmless).
enum NewFeature {
  daylightHint('daylight_hint_v1'),
  routingOptionsDialog('routing_options_dialog_v1'),
  ebikeBatteryBadge('ebike_battery_badge_v1'),
  ebikeChargingPlanner('ebike_charging_planner_v1'),
  watchSend('watch_send_v1'),
  batteryBudgetPhone('battery_budget_phone_v1'),
  myRoutesOverlay('my_routes_overlay_v1'),
  resupplyOpenNow('resupply_open_now_v1');

  const NewFeature(this.key);
  final String key;
}

/// Per-feature first-seen tracker. The map screen and other widgets
/// look up [isFresh] before painting; calling [markSeen] hides the
/// pill from then on. Persistent across launches so a user only sees
/// each NEU badge once.
class NewFeaturePrefs {
  static const _prefix = 'new_feature_seen_';
  // In-memory cache so a tap doesn't roundtrip through prefs to know
  // whether to repaint without the pill.
  static final Set<String> _seen = {};
  static bool _loaded = false;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _seen
      ..clear()
      ..addAll(NewFeature.values
          .map((f) => f.key)
          .where((k) => p.getBool('$_prefix$k') == true));
    _loaded = true;
  }

  static bool get isLoaded => _loaded;

  /// True when the feature has *not* yet been seen and the badge
  /// should still be drawn. Returns false until [load] has run so a
  /// pre-load build doesn't flash a badge for already-seen features.
  static bool isFresh(NewFeature f) =>
      _loaded && !_seen.contains(f.key);

  static Future<void> markSeen(NewFeature f) async {
    if (_seen.add(f.key)) {
      final p = await SharedPreferences.getInstance();
      await p.setBool('$_prefix${f.key}', true);
    }
  }
}
