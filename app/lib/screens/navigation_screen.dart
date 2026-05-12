import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/map_style.dart';
import '../models/nogo_area.dart';
import '../models/route_result.dart';
import '../models/turn_hint.dart';
import '../services/brouter_service.dart';
import '../services/navigation_voice_service.dart';
import '../services/ride_recorder.dart';
import '../services/ride_storage.dart';

const double _offRouteThresholdM = 50.0;
const double _arrivalThresholdM = 30.0;

class NavigationScreen extends StatefulWidget {
  final RouteResult route;
  final List<LatLng> waypoints;
  final String profile;
  final List<NogoArea> nogos;
  final MapStyle mapStyle;

  const NavigationScreen({
    super.key,
    required this.route,
    required this.waypoints,
    required this.profile,
    required this.nogos,
    required this.mapStyle,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  RouteResult? _route;
  StreamSubscription<Position>? _gpsSub;
  Position? _pos;
  int _coordIdx = 0;
  bool _headingUp = true;
  bool _rerouting = false;
  bool _arrived = false;
  DateTime? _lastReroute;
  // Smoothing to keep the map from twitching on every GPS sample.
  double? _smoothedHeading;
  double _lastRecenterLat = 0;
  double _lastRecenterLon = 0;
  double _lastAppliedRotation = 0;
  // Voice tracking: which (hintCoordIdx, phase) keys have already been
  // announced this session. Re-routes reset the set by clearing it in
  // _maybeReroute when a fresh route is installed.
  final Set<String> _spokenPhases = {};
  bool _voiceMuted = false;

  @override
  void initState() {
    super.initState();
    _route = widget.route;
    WakelockPlus.enable();
    _startGps();
    _initVoice();
  }

  Future<void> _initVoice() async {
    final tag = WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
    await NavigationVoiceService.instance.init(tag);
    if (!mounted) return;
    setState(() => _voiceMuted = NavigationVoiceService.instance.muted);
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    NavigationVoiceService.instance.stop();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _startGps() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm != LocationPermission.always &&
        perm != LocationPermission.whileInUse) {
      return;
    }
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);
  }

  void _onPosition(Position pos) {
    if (!mounted || _route == null) return;
    final wasArrived = _arrived;
    _pos = pos;
    _coordIdx = _nearestCoordIdx(pos.latitude, pos.longitude);
    _checkArrival();
    _maybeReroute();
    _recenter();
    _speakTurnIfNeeded();
    if (!wasArrived && _arrived) {
      final l = AppLocalizations.of(context);
      NavigationVoiceService.instance.speak(l.voiceArrived);
    }
    setState(() {});
  }

  void _speakTurnIfNeeded() {
    if (_voiceMuted || _arrived) return;
    final hint = _nextHint;
    if (hint == null) return;
    final l = AppLocalizations.of(context);
    final distM = _distanceToNextHintM();
    // Pick the current "phase" — the closest threshold that the distance has
    // crossed. A given (hint, phase) pair is only spoken once.
    int? phase;
    if (distM <= 40) {
      phase = 0; // "now"
    } else if (distM <= 220) {
      phase = 200;
    } else if (distM <= 520) {
      phase = 500;
    }
    if (phase == null) return;
    final key = '${hint.coordIndex}:$phase';
    if (!_spokenPhases.add(key)) return;
    final action = _textForCmd(hint.cmd, l);
    final String spoken;
    if (phase == 0) {
      spoken = '${l.voiceNow} $action';
    } else {
      spoken = '${l.voiceInMeters(phase)} $action';
    }
    NavigationVoiceService.instance.speak(spoken);
  }

  int _nearestCoordIdx(double lat, double lon) {
    final coords = _route!.coordinates;
    int best = 0;
    double bestD = double.infinity;
    // Prefer indices forward of where we already are so we don't snap
    // backwards onto an earlier passage of the route.
    final start = max(0, _coordIdx - 5);
    for (int i = start; i < coords.length; i++) {
      final dlat = coords[i][1] - lat;
      final dlon = coords[i][0] - lon;
      final d = dlat * dlat + dlon * dlon; // squared planar distance is fine for nearest
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  double _distanceToRouteM() {
    if (_pos == null || _route == null) return 0;
    final c = _route!.coordinates[_coordIdx];
    return _haversineM(_pos!.latitude, _pos!.longitude, c[1], c[0]);
  }

  void _checkArrival() {
    if (_pos == null || _route == null || _arrived) return;
    final last = widget.waypoints.last;
    final d = _haversineM(_pos!.latitude, _pos!.longitude,
        last.latitude, last.longitude);
    if (d < _arrivalThresholdM) {
      _arrived = true;
      _gpsSub?.cancel();
    }
  }

  Future<void> _maybeReroute() async {
    if (_pos == null || _rerouting || _arrived) return;
    if (_distanceToRouteM() < _offRouteThresholdM) return;
    final now = DateTime.now();
    if (_lastReroute != null && now.difference(_lastReroute!).inSeconds < 15) {
      return;
    }
    _rerouting = true;
    _lastReroute = now;
    if (mounted) {
      final l = AppLocalizations.of(context);
      NavigationVoiceService.instance.speak(l.voiceRerouting);
    }
    try {
      final wpsLonLat = <List<double>>[
        [_pos!.longitude, _pos!.latitude],
        [widget.waypoints.last.longitude, widget.waypoints.last.latitude],
      ];
      final newRoute = await BRouterService.calculateRoute(
        waypoints: wpsLonLat,
        profile: widget.profile,
        nogos: widget.nogos,
      );
      if (!mounted) return;
      setState(() {
        _route = newRoute;
        _coordIdx = 0;
        _spokenPhases.clear();
      });
    } catch (_) {
      // swallow; user stays on the visual route until next attempt
    } finally {
      _rerouting = false;
    }
  }

  void _recenter() {
    if (_pos == null) return;
    // Heading from GPS is noisy below walking speed; only refresh when we're
    // actually moving, and EMA-smooth what we keep.
    if (_headingUp && _pos!.speed >= 1.5) {
      final raw = _pos!.heading;
      if (_smoothedHeading == null) {
        _smoothedHeading = raw;
      } else {
        // Circular EMA via shortest-angle delta.
        var delta = raw - _smoothedHeading!;
        while (delta > 180) {
          delta -= 360;
        }
        while (delta < -180) {
          delta += 360;
        }
        _smoothedHeading = (_smoothedHeading! + delta * 0.25) % 360;
      }
    }
    final rotation = _headingUp ? -(_smoothedHeading ?? 0) : 0.0;
    final movedM = _haversineM(
        _lastRecenterLat, _lastRecenterLon, _pos!.latitude, _pos!.longitude);
    final rotChanged = (rotation - _lastAppliedRotation).abs() > 6;
    if (movedM < 8 && !rotChanged && _lastRecenterLat != 0) return;
    _lastRecenterLat = _pos!.latitude;
    _lastRecenterLon = _pos!.longitude;
    _lastAppliedRotation = rotation;
    final pt = LatLng(_pos!.latitude, _pos!.longitude);
    _mapController.moveAndRotate(pt, 17, rotation);
  }

  Duration _remainingDuration() {
    final r = _route;
    if (r == null) return Duration.zero;
    final remainingM = _remainingDistanceM();
    final totalM = r.distance * 1000;
    if (totalM <= 0 || r.time <= 0) return Duration.zero;
    // Prefer live speed when we're actually moving above noise.
    final liveSpeed = _pos?.speed ?? 0;
    if (liveSpeed >= 2.0) {
      return Duration(seconds: (remainingM / liveSpeed).round());
    }
    final routeSpeed = totalM / r.time;
    return Duration(seconds: (remainingM / routeSpeed).round());
  }

  String _formatEta() {
    final d = _remainingDuration();
    final eta = DateTime.now().add(d);
    return '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
  }

  TurnHint? get _nextHint {
    final r = _route;
    if (r == null) return null;
    for (final h in r.turnHints) {
      if (h.coordIndex >= _coordIdx) return h;
    }
    return null;
  }

  double _distanceToNextHintM() {
    final r = _route;
    final hint = _nextHint;
    if (r == null || hint == null) return 0;
    double d = 0;
    final coords = r.coordinates;
    final end = min(hint.coordIndex, coords.length - 1);
    for (int i = _coordIdx; i < end; i++) {
      d += _haversineM(coords[i][1], coords[i][0],
          coords[i + 1][1], coords[i + 1][0]);
    }
    return d;
  }

  double _remainingDistanceM() {
    final r = _route;
    if (r == null) return 0;
    double d = 0;
    final coords = r.coordinates;
    for (int i = _coordIdx; i < coords.length - 1; i++) {
      d += _haversineM(coords[i][1], coords[i][0],
          coords[i + 1][1], coords[i + 1][0]);
    }
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final route = _route;
    if (route == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final routeLatLngs = route.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList(growable: false);

    final hint = _nextHint;
    final hintDist = _distanceToNextHintM();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: routeLatLngs.first,
              initialZoom: 17,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: widget.mapStyle.urlTemplate,
                userAgentPackageName: 'app.wegwiesel',
              ),
              PolylineLayer(polylines: [
                Polyline(
                  points: routeLatLngs,
                  strokeWidth: 8,
                  color: Colors.blueAccent,
                ),
              ]),
              if (_pos != null)
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(_pos!.latitude, _pos!.longitude),
                    width: 36,
                    height: 36,
                    child: Transform.rotate(
                      angle: (_pos!.heading * pi / 180),
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.blue,
                        size: 36,
                      ),
                    ),
                  ),
                ]),
            ],
          ),

          // Top banner: next turn
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(blurRadius: 8, color: Colors.black26),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(_iconForCmd(hint?.cmd),
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hint == null
                                ? l.navigateContinue
                                : '${_formatDistance(hintDist)} ${_textForCmd(hint.cmd, l)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_rerouting)
                            Text(l.navigateRerouting,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                                    fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right: rotation toggle + voice mute
          Positioned(
            top: 100, right: 12,
            child: SafeArea(
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'nav_rotate',
                    onPressed: () {
                      setState(() => _headingUp = !_headingUp);
                      _recenter();
                    },
                    tooltip: _headingUp ? l.navigateNorthUp : l.navigateHeadingUp,
                    child: Icon(_headingUp
                        ? Icons.explore_outlined
                        : Icons.navigation_outlined),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'nav_voice',
                    onPressed: () async {
                      await NavigationVoiceService.instance.toggleMuted();
                      if (!mounted) return;
                      setState(() => _voiceMuted = NavigationVoiceService.instance.muted);
                    },
                    tooltip: _voiceMuted ? l.navigateVoiceOff : l.navigateVoiceOn,
                    child: Icon(_voiceMuted
                        ? Icons.volume_off
                        : Icons.volume_up),
                  ),
                  const SizedBox(height: 8),
                  ListenableBuilder(
                    listenable: RideRecorder.instance,
                    builder: (ctx, _) {
                      final rec = RideRecorder.instance;
                      return FloatingActionButton.small(
                        heroTag: 'nav_rec',
                        backgroundColor: rec.isActive
                            ? const Color(0xFFc62828)
                            : null,
                        foregroundColor: rec.isActive ? Colors.white : null,
                        onPressed: () async {
                          if (rec.isActive) {
                            final name =
                                'Navigation ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
                            final ride = await rec.stop(name: name);
                            if (ride != null) {
                              await RideStorage.save(ride);
                            }
                          } else {
                            await rec.start();
                          }
                          if (mounted) setState(() {});
                        },
                        tooltip: rec.isActive ? l.recordingStop : l.recordingStart,
                        child: Icon(rec.isActive
                            ? Icons.stop
                            : Icons.fiber_manual_record),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom: stats + stop
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _arrived
                                ? l.navigateArrived
                                : _formatDistance(_remainingDistanceM()),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!_arrived)
                            Text(l.navigateRemaining,
                                style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (!_arrived) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatEta(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(l.navigateEta,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(width: 12),
                    ],
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: Text(l.navigateStop),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double m) {
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(m < 10000 ? 1 : 0)} km';
  }

  IconData _iconForCmd(TurnCmd? cmd) {
    switch (cmd) {
      case TurnCmd.uTurnLeft:
      case TurnCmd.uTurnRight:
      case TurnCmd.uTurn:
        return Icons.u_turn_left;
      case TurnCmd.turnLeft:
        return Icons.turn_left;
      case TurnCmd.turnSlightLeft:
      case TurnCmd.keepLeft:
        return Icons.turn_slight_left;
      case TurnCmd.turnRight:
        return Icons.turn_right;
      case TurnCmd.turnSlightRight:
      case TurnCmd.keepRight:
        return Icons.turn_slight_right;
      case TurnCmd.straight:
        return Icons.straight;
      case TurnCmd.roundabout1:
      case TurnCmd.roundabout2:
      case TurnCmd.roundabout3:
      case TurnCmd.roundabout4:
      case TurnCmd.roundabout5:
      case TurnCmd.roundabout6:
      case TurnCmd.roundaboutLeft:
        return Icons.roundabout_right;
      case TurnCmd.exit:
        return Icons.exit_to_app;
      default:
        return Icons.straight;
    }
  }

  String _textForCmd(TurnCmd cmd, AppLocalizations l) {
    switch (cmd) {
      case TurnCmd.turnLeft:
      case TurnCmd.turnSlightLeft:
        return l.navigateTurnLeft;
      case TurnCmd.keepLeft:
        return l.navigateKeepLeft;
      case TurnCmd.turnRight:
      case TurnCmd.turnSlightRight:
        return l.navigateTurnRight;
      case TurnCmd.keepRight:
        return l.navigateKeepRight;
      case TurnCmd.uTurn:
      case TurnCmd.uTurnLeft:
      case TurnCmd.uTurnRight:
        return l.navigateUTurn;
      case TurnCmd.straight:
        return l.navigateStraight;
      case TurnCmd.roundabout1:
      case TurnCmd.roundabout2:
      case TurnCmd.roundabout3:
      case TurnCmd.roundabout4:
      case TurnCmd.roundabout5:
      case TurnCmd.roundabout6:
        return l.navigateRoundabout(cmd.index - TurnCmd.roundabout1.index + 1);
      case TurnCmd.roundaboutLeft:
        return l.navigateRoundabout(1);
      case TurnCmd.exit:
        return l.navigateExit;
      default:
        return l.navigateContinue;
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
