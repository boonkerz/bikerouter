import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/recorded_ride.dart';
import 'body_weight_prefs.dart';

enum RecorderState { idle, recording, paused }

class RideStats {
  final double distanceKm;
  final Duration movingDuration;
  final double currentSpeedKmh;
  final double avgSpeedKmh;
  final double? maxSpeedKmh;
  final int ascentM;
  final int descentM;
  final int? kcal;
  final int pointCount;

  const RideStats({
    required this.distanceKm,
    required this.movingDuration,
    required this.currentSpeedKmh,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.ascentM,
    required this.descentM,
    required this.kcal,
    required this.pointCount,
  });

  static const empty = RideStats(
    distanceKm: 0,
    movingDuration: Duration.zero,
    currentSpeedKmh: 0,
    avgSpeedKmh: 0,
    maxSpeedKmh: null,
    ascentM: 0,
    descentM: 0,
    kcal: null,
    pointCount: 0,
  );
}

class RideRecorder extends ChangeNotifier {
  RideRecorder._();
  static final RideRecorder instance = RideRecorder._();

  RecorderState _state = RecorderState.idle;
  StreamSubscription<Position>? _gpsSub;
  final List<RecordedPoint> _points = [];
  DateTime? _startedAt;
  DateTime? _pausedAt;
  Duration _pausedAccumulated = Duration.zero;
  double _bodyKg = 75.0;

  // Running totals so per-tick math stays O(1).
  double _distanceM = 0;
  double _ascent = 0;
  double _descent = 0;
  double? _lastElevation;
  double? _maxSpeed;
  double _currentSpeed = 0;

  RecorderState get state => _state;
  bool get isRecording => _state == RecorderState.recording;
  bool get isPaused => _state == RecorderState.paused;
  bool get isActive => _state != RecorderState.idle;
  List<RecordedPoint> get points => List.unmodifiable(_points);

  RideStats get stats {
    final dur = _movingDuration();
    final hours = dur.inMilliseconds / 3600000.0;
    final distKm = _distanceM / 1000.0;
    final avgKmh = hours > 0.001 ? distKm / hours : 0.0;
    final kcal = hours > 0 ? (_metValueFor(avgKmh) * _bodyKg * hours).round() : null;
    return RideStats(
      distanceKm: distKm,
      movingDuration: dur,
      currentSpeedKmh: _currentSpeed * 3.6,
      avgSpeedKmh: avgKmh,
      maxSpeedKmh: _maxSpeed == null ? null : _maxSpeed! * 3.6,
      ascentM: _ascent.round(),
      descentM: _descent.round(),
      kcal: kcal,
      pointCount: _points.length,
    );
  }

  Future<bool> start() async {
    if (_state != RecorderState.idle) return false;
    final permission = await _ensurePermission();
    if (!permission) return false;

    _bodyKg = (await BodyWeightPrefs.get()).toDouble();
    _points.clear();
    _distanceM = 0;
    _ascent = 0;
    _descent = 0;
    _lastElevation = null;
    _maxSpeed = null;
    _currentSpeed = 0;
    _pausedAccumulated = Duration.zero;
    _pausedAt = null;
    _startedAt = DateTime.now();
    _state = RecorderState.recording;

    final settings = _buildLocationSettings();
    _gpsSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPosition);
    notifyListeners();
    return true;
  }

  void pause() {
    if (_state != RecorderState.recording) return;
    _state = RecorderState.paused;
    _pausedAt = DateTime.now();
    notifyListeners();
  }

  void resume() {
    if (_state != RecorderState.paused) return;
    final pausedAt = _pausedAt;
    if (pausedAt != null) {
      _pausedAccumulated += DateTime.now().difference(pausedAt);
    }
    _pausedAt = null;
    _state = RecorderState.recording;
    notifyListeners();
  }

  Future<RecordedRide?> stop({required String name}) async {
    if (_state == RecorderState.idle) return null;
    await _gpsSub?.cancel();
    _gpsSub = null;

    // Roll the current pause into accumulated time if we were paused.
    if (_state == RecorderState.paused && _pausedAt != null) {
      _pausedAccumulated += DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
    }

    final endedAt = DateTime.now();
    final started = _startedAt ?? endedAt;
    final dur = endedAt.difference(started) - _pausedAccumulated;
    final hours = dur.inMilliseconds / 3600000.0;
    final distKm = _distanceM / 1000.0;
    final avgKmh = hours > 0.001 ? distKm / hours : 0.0;
    final kcal = hours > 0 ? (_metValueFor(avgKmh) * _bodyKg * hours).round() : null;

    final ride = RecordedRide(
      id: 'rec-${started.millisecondsSinceEpoch}',
      name: name,
      startedAt: started,
      endedAt: endedAt,
      movingSeconds: dur.inSeconds < 0 ? 0 : dur.inSeconds,
      distanceKm: distKm,
      ascent: _ascent.round(),
      descent: _descent.round(),
      avgSpeedKmh: avgKmh,
      maxSpeedKmh: _maxSpeed == null ? null : _maxSpeed! * 3.6,
      kcal: kcal,
      points: List<RecordedPoint>.from(_points),
    );

    _state = RecorderState.idle;
    notifyListeners();
    return ride;
  }

  void _onPosition(Position pos) {
    if (_state != RecorderState.recording) return;
    final point = RecordedPoint(
      lat: pos.latitude,
      lon: pos.longitude,
      ele: pos.altitude,
      t: DateTime.now().millisecondsSinceEpoch,
      speed: pos.speed,
    );

    if (_points.isNotEmpty) {
      final prev = _points.last;
      _distanceM += _haversineM(prev.lat, prev.lon, point.lat, point.lon);
    }

    // Elevation deltas under 2 m are typically GPS noise — ignore them.
    if (point.ele != null) {
      if (_lastElevation != null) {
        final dEl = point.ele! - _lastElevation!;
        if (dEl.abs() >= 2.0) {
          if (dEl > 0) {
            _ascent += dEl;
          } else {
            _descent += -dEl;
          }
          _lastElevation = point.ele;
        }
      } else {
        _lastElevation = point.ele;
      }
    }

    _currentSpeed = pos.speed.isFinite ? pos.speed : 0;
    if (_currentSpeed > (_maxSpeed ?? 0)) _maxSpeed = _currentSpeed;

    _points.add(point);
    notifyListeners();
  }

  Duration _movingDuration() {
    final start = _startedAt;
    if (start == null) return Duration.zero;
    final now = _pausedAt ?? DateTime.now();
    final total = now.difference(start);
    final d = total - _pausedAccumulated;
    return d.isNegative ? Duration.zero : d;
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  LocationSettings _buildLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              'Wegwiesel zeichnet deine Fahrt auf — tippe, um zurückzukehren.',
          notificationTitle: 'Aufzeichnung läuft',
          enableWakeLock: true,
        ),
      );
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
  }

  /// METS-based estimate, calibrated to common cycling intensities.
  /// kcal = MET × weight (kg) × hours.
  double _metValueFor(double kmh) {
    if (kmh < 5) return 2.5; // standing/very slow
    if (kmh < 9) return 3.5; // walking pace
    if (kmh < 15) return 6.0; // casual cycling
    if (kmh < 20) return 8.0; // moderate cycling
    if (kmh < 26) return 10.0; // vigorous cycling
    return 12.0; // racing
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
