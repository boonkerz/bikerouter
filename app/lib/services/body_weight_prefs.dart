import 'package:shared_preferences/shared_preferences.dart';

class BodyWeightPrefs {
  static const _key = 'body_weight_kg_v1';
  static const defaultKg = 75;

  static Future<int> get() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_key) ?? defaultKg;
  }

  static Future<void> set(int kg) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_key, kg);
  }
}
