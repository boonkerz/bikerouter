import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/nogo_area.dart';

class NogoStorage {
  static const _key = 'nogos.v1';

  static Future<List<NogoArea>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => NogoArea.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(List<NogoArea> nogos) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(nogos.map((n) => n.toJson()).toList()));
  }
}
