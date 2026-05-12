import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ride_recorder.dart';

class LiveTrackingSession {
  final String id;
  final String viewerUrl;
  final DateTime expiresAt;

  const LiveTrackingSession({
    required this.id,
    required this.viewerUrl,
    required this.expiresAt,
  });
}

/// Posts the recorder's latest GPS position to the live-tracking endpoint
/// every `interval`. Stop() deletes the session server-side. Intended to be
/// driven by the RideRecorder — when recording stops, tracking should too.
class LiveTrackingService {
  LiveTrackingService._();
  static final LiveTrackingService instance = LiveTrackingService._();

  static const _baseUrl = 'https://wegwiesel.app';
  static const _interval = Duration(seconds: 20);

  LiveTrackingSession? _session;
  Timer? _timer;
  int _lastSentT = 0;

  LiveTrackingSession? get session => _session;
  bool get isActive => _session != null;

  Future<LiveTrackingSession?> start({String? name}) async {
    if (_session != null) return _session;
    final res = await http
        .post(
          Uri.parse('$_baseUrl/api/track'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            if (name != null) 'name': name,
            'ttl_hours': 12,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 201) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    _session = LiveTrackingSession(
      id: j['id'] as String,
      viewerUrl: '$_baseUrl${j['viewer_path']}',
      expiresAt: DateTime.parse(j['expires_at'] as String),
    );
    _lastSentT = 0;
    _timer = Timer.periodic(_interval, (_) => _flush());
    // Send an immediate first ping so the viewer doesn't sit on "waiting".
    _flush();
    return _session;
  }

  Future<void> stop() async {
    final s = _session;
    _session = null;
    _timer?.cancel();
    _timer = null;
    if (s == null) return;
    try {
      await http
          .delete(Uri.parse('$_baseUrl/api/track/${s.id}'))
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Server-side TTL will clean it up regardless.
    }
  }

  Future<void> _flush() async {
    final s = _session;
    if (s == null) return;
    final pts = RideRecorder.instance.points;
    if (pts.isEmpty) return;
    final p = pts.last;
    if (p.t == _lastSentT) return;
    _lastSentT = p.t;
    try {
      await http
          .put(
            Uri.parse('$_baseUrl/api/track/${s.id}'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'lat': p.lat,
              'lon': p.lon,
              if (p.ele != null) 'ele': p.ele,
              if (p.speed != null) 'speed': p.speed,
              't': p.t,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Drop this tick silently — next tick will catch up.
    }
  }
}
