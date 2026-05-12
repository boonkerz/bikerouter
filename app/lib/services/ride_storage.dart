import 'package:shared_preferences/shared_preferences.dart';

import '../models/recorded_ride.dart';

class RideStorage {
  static const _key = 'recorded_rides_v1';

  static Future<List<RecordedRide>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map(RecordedRide.fromJsonString).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  static Future<void> save(RecordedRide ride) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.removeWhere((s) => RecordedRide.fromJsonString(s).id == ride.id);
    list.add(ride.toJsonString());
    await prefs.setStringList(_key, list);
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.removeWhere((s) => RecordedRide.fromJsonString(s).id == id);
    await prefs.setStringList(_key, list);
  }
}
