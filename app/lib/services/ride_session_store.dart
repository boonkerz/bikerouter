import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import '../models/recorded_ride.dart';

/// Persists an in-progress recording to disk so a crash mid-recording
/// doesn't lose the track. The recorder flushes every ~10 points; on
/// app launch we recover any orphan session and convert it to a regular
/// [RecordedRide] in the rides list.
class RideSessionStore {
  static const _fileName = 'active_ride_session.json';
  static File? _cachedFile;

  static Future<File> _file() async {
    final cached = _cachedFile;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final f = File('${docs.path}/$_fileName');
    _cachedFile = f;
    return f;
  }

  /// Returns true if a session file exists. Cheap (no parse).
  static Future<bool> hasOrphanSession() async {
    try {
      return await (await _file()).exists();
    } catch (_) {
      return false;
    }
  }

  /// Writes the current session snapshot. Atomic via tmp + rename so a
  /// crash mid-write doesn't leave a half-written file.
  static Future<void> writeSession({
    required DateTime startedAt,
    required Duration pausedAccumulated,
    required double bodyKg,
    required List<RecordedPoint> points,
  }) async {
    final f = await _file();
    final tmp = File('${f.path}.tmp');
    final payload = jsonEncode({
      'startedAt': startedAt.toIso8601String(),
      'pausedMs': pausedAccumulated.inMilliseconds,
      'bodyKg': bodyKg,
      'points': points.map((p) => p.toJson()).toList(),
    });
    await tmp.writeAsString(payload, flush: true);
    await tmp.rename(f.path);
  }

  /// Clears the session file. Idempotent.
  static Future<void> clearSession() async {
    try {
      final f = await _file();
      if (await f.exists()) await f.delete();
    } catch (_) {
      // best-effort
    }
  }

  /// Reads an orphan session and converts it to a RecordedRide ready for
  /// the rides list. Returns null when no session exists, the file is
  /// corrupt, or the session has no points worth keeping.
  static Future<RecordedRide?> recoverAsRide(String displayName) async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      final raw = await f.readAsString();
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final pts = (j['points'] as List?)
              ?.map((p) => RecordedPoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const <RecordedPoint>[];
      if (pts.length < 2) return null; // not worth keeping

      final startedAt = DateTime.parse(j['startedAt'] as String);
      final pausedMs = (j['pausedMs'] as num?)?.toInt() ?? 0;
      final endedAt =
          DateTime.fromMillisecondsSinceEpoch(pts.last.t, isUtc: false);
      final movingMs = endedAt.difference(startedAt).inMilliseconds - pausedMs;
      final movingSec = movingMs > 0 ? (movingMs / 1000).round() : 0;

      // Recompute totals from the points list — cheaper than persisting them.
      double distM = 0;
      double ascent = 0;
      double descent = 0;
      double? lastEle;
      double? maxSpeed;
      for (var i = 0; i < pts.length; i++) {
        if (i > 0) {
          distM += _haversineM(
              pts[i - 1].lat, pts[i - 1].lon, pts[i].lat, pts[i].lon);
        }
        final ele = pts[i].ele;
        if (ele != null) {
          if (lastEle != null) {
            final d = ele - lastEle;
            if (d.abs() >= 2.0) {
              if (d > 0) {
                ascent += d;
              } else {
                descent += -d;
              }
              lastEle = ele;
            }
          } else {
            lastEle = ele;
          }
        }
        final s = pts[i].speed;
        if (s != null && s.isFinite && s > (maxSpeed ?? 0)) maxSpeed = s;
      }

      final hours = movingSec / 3600.0;
      final distKm = distM / 1000.0;
      final avgKmh = hours > 0.001 ? distKm / hours : 0.0;

      return RecordedRide(
        id: 'recovered-${startedAt.millisecondsSinceEpoch}',
        name: displayName,
        startedAt: startedAt,
        endedAt: endedAt,
        movingSeconds: movingSec,
        distanceKm: distKm,
        ascent: ascent.round(),
        descent: descent.round(),
        avgSpeedKmh: avgKmh,
        // Body weight may have changed since the crash; skip kcal rather
        // than guessing.
        kcal: null,
        maxSpeedKmh: maxSpeed == null ? null : maxSpeed * 3.6,
        points: pts,
      );
    } catch (_) {
      return null;
    }
  }

  static double _haversineM(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return 2 * r * asin(sqrt(a));
  }
}
