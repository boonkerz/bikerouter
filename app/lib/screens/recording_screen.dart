import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/map_style.dart';
import '../models/recorded_ride.dart';
import '../services/gpx_export.dart';
import '../services/live_tracking_service.dart';
import '../services/ride_recorder.dart';
import '../services/ride_storage.dart';

class RecordingScreen extends StatefulWidget {
  final MapStyle mapStyle;

  const RecordingScreen({super.key, required this.mapStyle});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final MapController _mapController = MapController();
  Timer? _ticker;
  bool _mapFollowing = true;

  @override
  void initState() {
    super.initState();
    RideRecorder.instance.addListener(_onRecorderChange);
    WakelockPlus.enable();
    // Drive a 1-Hz ticker so the duration display updates even when no GPS
    // sample arrives (stationary at a red light).
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    RideRecorder.instance.removeListener(_onRecorderChange);
    WakelockPlus.disable();
    super.dispose();
  }

  void _onRecorderChange() {
    if (!mounted) return;
    setState(() {});
    final points = RideRecorder.instance.points;
    if (_mapFollowing && points.isNotEmpty) {
      final last = points.last;
      _mapController.move(LatLng(last.lat, last.lon), _mapController.camera.zoom);
    }
  }

  Future<void> _start() async {
    final ok = await RideRecorder.instance.start();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).recordingPermissionDenied)),
      );
    }
  }

  Future<void> _stop() async {
    final l = AppLocalizations.of(context);
    final defaultName = _defaultName(l);
    final name = await _askName(defaultName);
    if (name == null) return;
    await LiveTrackingService.instance.stop();
    final ride = await RideRecorder.instance.stop(name: name);
    if (ride == null || !mounted) return;
    await RideStorage.save(ride);
    if (!mounted) return;
    await _showSummary(ride);
  }

  Future<void> _toggleLiveTracking() async {
    final l = AppLocalizations.of(context);
    final svc = LiveTrackingService.instance;
    if (svc.isActive) {
      await svc.stop();
      if (!mounted) return;
      setState(() {});
      return;
    }
    final session = await svc.start();
    if (!mounted) return;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.liveTrackingError)),
      );
      return;
    }
    setState(() {});
    await _showShareLink(session.viewerUrl);
  }

  Future<void> _showShareLink(String url) async {
    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.liveTrackingTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.liveTrackingExplain),
            const SizedBox(height: 12),
            SelectableText(
              url,
              style: const TextStyle(
                color: Color(0xFF6a4a28),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: Text(l.liveTrackingCopy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
          ),
          FilledButton.icon(
            icon: const Icon(Icons.share),
            label: Text(l.liveTrackingShare),
            onPressed: () async {
              await SharePlus.instance
                  .share(ShareParams(text: '${l.liveTrackingShareBody} $url'));
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<String?> _askName(String suggestion) async {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: suggestion);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.recordingSaveTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: l.recordingSaveHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.urlImportCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim().isEmpty
                ? suggestion
                : ctrl.text.trim()),
            child: Text(l.recordingSave),
          ),
        ],
      ),
    );
  }

  Future<void> _showSummary(RecordedRide ride) async {
    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.recordingSummaryTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statRow(l.recordingDistance, '${ride.distanceKm.toStringAsFixed(2)} km'),
            _statRow(l.recordingDuration, _fmtDuration(Duration(seconds: ride.movingSeconds))),
            _statRow(l.recordingAvgSpeed, '${ride.avgSpeedKmh.toStringAsFixed(1)} km/h'),
            if (ride.maxSpeedKmh != null)
              _statRow(l.recordingMaxSpeed, '${ride.maxSpeedKmh!.toStringAsFixed(1)} km/h'),
            _statRow(l.recordingAscent, '${ride.ascent} m'),
            _statRow(l.recordingDescent, '${ride.descent} m'),
            if (ride.kcal != null)
              _statRow(l.recordingKcal, '${ride.kcal} kcal'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.recordingCloseSummary),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.share),
            label: Text(l.recordingExportGpx),
            onPressed: () async {
              await exportGpxFile('${ride.id}.gpx', ride.toGpx());
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  String _defaultName(AppLocalizations l) {
    final n = DateTime.now();
    final d = '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
    final t = '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
    return l.recordingDefaultName(d, t);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rec = RideRecorder.instance;
    final stats = rec.stats;
    final pts = rec.points;
    final trackLatLng = pts.map((p) => LatLng(p.lat, p.lon)).toList(growable: false);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: trackLatLng.isNotEmpty
                  ? trackLatLng.last
                  : const LatLng(52.0, 9.0),
              initialZoom: 16,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) setState(() => _mapFollowing = false);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: widget.mapStyle.urlTemplate,
                userAgentPackageName: 'app.wegwiesel',
              ),
              if (trackLatLng.length >= 2)
                PolylineLayer(polylines: [
                  Polyline(
                    points: trackLatLng,
                    strokeWidth: 6,
                    color: const Color(0xFFc62828),
                  ),
                ]),
              if (trackLatLng.isNotEmpty)
                MarkerLayer(markers: [
                  Marker(
                    point: trackLatLng.last,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFc62828),
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 3)),
                      ),
                    ),
                  ),
                ]),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.topLeft,
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFf5e9d8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF6a4a28)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
          if (!_mapFollowing)
            Positioned(
              right: 12, top: 80,
              child: SafeArea(
                child: FloatingActionButton.small(
                  heroTag: 'rec_follow',
                  onPressed: () {
                    setState(() => _mapFollowing = true);
                    if (pts.isNotEmpty) {
                      _mapController.move(LatLng(pts.last.lat, pts.last.lon),
                          _mapController.camera.zoom);
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(blurRadius: 12, color: Colors.black26),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _bigStat('${stats.distanceKm.toStringAsFixed(2)} km',
                            l.recordingDistance),
                        _bigStat(_fmtDuration(stats.movingDuration),
                            l.recordingDuration),
                        _bigStat(stats.avgSpeedKmh.toStringAsFixed(1),
                            '⌀ km/h'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _smallStat(
                            stats.currentSpeedKmh.toStringAsFixed(0),
                            'km/h'),
                        // Slope-adjusted pace, only meaningful while
                        // moving on foot. Runners/hikers care more
                        // about min/km than km/h, and the Naismith
                        // adjustment makes hilly and flat sections
                        // comparable.
                        if (_paceShown(stats))
                          _smallStat(_paceText(stats), 'min/km*'),
                        _smallStat('${stats.ascentM}', '↑ m'),
                        _smallStat('${stats.descentM}', '↓ m'),
                        if (stats.kcal != null)
                          _smallStat('${stats.kcal}', 'kcal'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _controls(l, rec),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(AppLocalizations l, RideRecorder rec) {
    if (rec.state == RecorderState.idle) {
      return FilledButton.icon(
        icon: const Icon(Icons.fiber_manual_record),
        label: Text(l.recordingStart),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: const Color(0xFFc62828),
          foregroundColor: Colors.white,
        ),
        onPressed: _start,
      );
    }
    final liveActive = LiveTrackingService.instance.isActive;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: rec.state == RecorderState.recording
                  ? OutlinedButton.icon(
                      icon: const Icon(Icons.pause),
                      label: Text(l.recordingPause),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: const Color(0xFF6a4a28),
                      ),
                      onPressed: rec.pause,
                    )
                  : OutlinedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l.recordingResume),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: const Color(0xFF6a4a28),
                      ),
                      onPressed: rec.resume,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.stop),
                label: Text(l.recordingStop),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: const Color(0xFFc62828),
                  foregroundColor: Colors.white,
                ),
                onPressed: _stop,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Icon(liveActive
                ? Icons.podcasts
                : Icons.podcasts_outlined),
            label: Text(liveActive
                ? l.liveTrackingActive
                : l.liveTrackingStart),
            style: OutlinedButton.styleFrom(
              foregroundColor: liveActive
                  ? const Color(0xFFc62828)
                  : const Color(0xFF6a4a28),
              side: BorderSide(
                color: liveActive
                    ? const Color(0xFFc62828)
                    : const Color(0xFF6a4a28),
              ),
            ),
            onPressed: _toggleLiveTracking,
          ),
        ),
      ],
    );
  }

  Widget _bigStat(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      );

  Widget _smallStat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      );

  Widget _statRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // Pace only makes sense on foot — at bike speeds (>15 km/h) we'd
  // show <4 min/km which is meaningless. The asterisk on the label
  // hints that this is slope-adjusted (Naismith).
  bool _paceShown(RideStats stats) =>
      stats.distanceKm > 0.05 &&
      stats.movingDuration.inSeconds > 30 &&
      stats.avgSpeedKmh > 0 &&
      stats.avgSpeedKmh < 15;

  /// Returns slope-adjusted pace in MM:SS per km. Naismith's rule: each
  /// 100 m of ascent equals ~10 min of additional flat walking time,
  /// so we strip that overhead and divide by distance to get a
  /// flat-equivalent pace ("you ran a 5:30/km effort even if your
  /// raw pace says 7:00/km because of all that climbing").
  String _paceText(RideStats stats) {
    final movMin = stats.movingDuration.inSeconds / 60.0;
    final flatEquivMin = (movMin - stats.ascentM / 10.0).clamp(0.1, 1e9);
    final paceMinPerKm = flatEquivMin / stats.distanceKm;
    if (!paceMinPerKm.isFinite || paceMinPerKm > 60) return '–';
    final wholeMin = paceMinPerKm.floor();
    final sec = ((paceMinPerKm - wholeMin) * 60).round();
    final secStr = sec.toString().padLeft(2, '0');
    // Guard against 5:60 from rounding
    if (sec == 60) return '${wholeMin + 1}:00';
    return '$wholeMin:$secStr';
  }
}
