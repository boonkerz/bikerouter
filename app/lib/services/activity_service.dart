import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity.dart';
import 'bikepacking_prefs.dart';
import 'routing_prefs.dart';

/// Applies an [Activity] preset across the various pref stores and
/// remembers the last-selected activity so the map screen can restore
/// it on launch and highlight it in the picker.
class ActivityService {
  static const _keyLastActivity = 'last_activity_v1';

  static String? _lastActivityId;
  static bool _loaded = false;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _lastActivityId = p.getString(_keyLastActivity);
    _loaded = true;
  }

  static bool get isLoaded => _loaded;
  static String? get lastActivityId => _lastActivityId;

  /// Configures routing flags + bikepacking for [activity] and records
  /// it as the current selection. Returns the underlying profile id so
  /// the caller can feed it into its existing `_setProfile` path
  /// (which owns the profile-string state + reroute).
  ///
  /// Only ever *enables* flags — never disables — so an activity tap
  /// is additive over whatever the user toggled by hand. This matches
  /// the principle in [Activity.enableFlags].
  static Future<String> apply(Activity activity) async {
    for (final flag in activity.enableFlags) {
      await RoutingPrefs.setFlag(activity.profileId, flag, true);
    }
    await BikepackingPrefs.setActive(activity.bikepacking);

    _lastActivityId = activity.id;
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyLastActivity, activity.id);

    return activity.profileId;
  }
}
