import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_route.dart';

class RouteStorage {
  static const _key = 'saved_routes_v1';

  static Future<List<SavedRoute>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map(SavedRoute.fromJsonString).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> save(SavedRoute route) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.removeWhere((s) => SavedRoute.fromJsonString(s).id == route.id);
    list.add(route.toJsonString());
    await prefs.setStringList(_key, list);
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.removeWhere((s) => SavedRoute.fromJsonString(s).id == id);
    await prefs.setStringList(_key, list);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
