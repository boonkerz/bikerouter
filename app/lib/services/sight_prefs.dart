import 'package:shared_preferences/shared_preferences.dart';
import '../models/osm_sight.dart';

class SightPrefs {
  static const _key = 'sight_enabled_types_v1';

  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key);
    if (list == null) return allSightTypes;
    return list.toSet();
  }

  static Future<void> save(Set<String> enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, enabled.toList());
  }
}
