import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/gpx_export.dart';

import '../models/map_style.dart';
import '../models/profile.dart';
import '../models/route_result.dart';
import '../services/brouter_service.dart';
import '../widgets/elevation_chart.dart';
import '../widgets/stats_bar.dart';
import '../widgets/profile_selector.dart';
import '../widgets/roundtrip_panel.dart';
import '../widgets/address_search.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final List<LatLng> _waypoints = [];
  RouteResult? _route;
  List<LatLng> _routePoints = [];
  bool _loading = false;
  String _profile = 'fastbike';
  MapStyle _mapStyle = mapStyles[0];
  bool _roundtripMode = false;
  int _rtDistanceKm = 20;
  int _rtDirection = 0;
  bool _showElevation = true;
  bool _showControls = false;
  int? _highlightIndex;
  LatLng? _currentPosition;
  bool _locatingUser = false;
  final bool _gradientRoute = true;
  int? _draggingWaypointIndex;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // Map + bottom panels
          Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(51.16, 10.45),
                    initialZoom: 6,
                    onTap: (tapPos, latLng) => _onMapTap(latLng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _mapStyle.urlTemplate,
                      maxZoom: _mapStyle.maxZoom.toDouble(),
                      userAgentPackageName: 'de.bikerouter.app',
                    ),
                    if (_mapStyle.labelsOverlay != null)
                      TileLayer(
                        urlTemplate: _mapStyle.labelsOverlay!,
                        maxZoom: _mapStyle.maxZoom.toDouble(),
                        userAgentPackageName: 'de.bikerouter.app',
                      ),
                    if (_routePoints.isNotEmpty) ...[
                      if (_gradientRoute && _route != null)
                        PolylineLayer(polylines: _buildGradientPolylines())
                      else
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              color: const Color(0xFF1565c0).withValues(alpha: 0.4),
                              strokeWidth: 8,
                            ),
                            Polyline(
                              points: _routePoints,
                              color: const Color(0xFF4fc3f7),
                              strokeWidth: 4,
                            ),
                          ],
                        ),
                      // Invisible fat polyline for tap detection (via-points)
                      if (!_roundtripMode && _waypoints.length >= 2)
                        GestureDetector(
                          onTapUp: (details) => _onRouteTap(details),
                          child: PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                color: Colors.transparent,
                                strokeWidth: 30,
                                useStrokeWidthInMeter: false,
                              ),
                            ],
                          ),
                        ),
                    ],
                    // Highlight marker from elevation chart
                    if (_highlightIndex != null &&
                        _route != null &&
                        _highlightIndex! < _route!.coordinates.length)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              _route!.coordinates[_highlightIndex!][1],
                              _route!.coordinates[_highlightIndex!][0],
                            ),
                            width: 16,
                            height: 16,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF4fc3f7), width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    // Current position marker
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition!,
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_waypoints.isNotEmpty)
                      MarkerLayer(markers: _buildMarkers()),
                  ],
                ),
              ),
              if (_route != null) StatsBar(route: _route!),
              if (_route != null && _showElevation)
                ElevationChart(
                  coordinates: _route!.coordinates,
                  onHover: (index) => setState(() => _highlightIndex = index),
                ),
            ],
          ),

          // Top bar
          Positioned(
            top: topPadding + 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _modeChip('A\u2009\u2192\u2009B', false),
                      _modeChip('Runde', true),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showProfileSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _profileLabel(),
                          style: const TextStyle(color: Color(0xFF4fc3f7), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more, color: Color(0xFF4fc3f7), size: 18),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Map style button
                GestureDetector(
                  onTap: () => _showMapStyleSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.layers, color: Color(0xFF4fc3f7), size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                // Search button
                GestureDetector(
                  onTap: () => _searchAddress(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search, color: Color(0xFF4fc3f7), size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                if (_roundtripMode)
                  GestureDetector(
                    onTap: () => setState(() => _showControls = !_showControls),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _showControls ? Icons.close : Icons.tune,
                        color: const Color(0xFF4fc3f7),
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Roundtrip controls
          if (_roundtripMode && _showControls)
            Positioned(
              top: topPadding + 56,
              left: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RoundtripPanel(
                  distanceKm: _rtDistanceKm,
                  direction: _rtDirection,
                  hasStart: _waypoints.isNotEmpty,
                  profile: _profile,
                  onDistanceChanged: (v) => setState(() => _rtDistanceKm = v),
                  onDirectionChanged: (v) => setState(() => _rtDirection = v),
                  onGenerate: (req) {
                    _calculateRoundtrip(req);
                    setState(() => _showControls = false);
                  },
                  onShuffle: (req) {
                    setState(() => _rtDirection = (_rtDirection + 60) % 360);
                    _calculateRoundtrip(req);
                  },
                ),
              ),
            ),

          // Loading
          if (_loading)
            const Center(
                child: CircularProgressIndicator(color: Color(0xFF4fc3f7))),

          // Action buttons
          Positioned(
            right: 12,
            bottom: (_route != null ? (_showElevation ? 210 : 50) : 0) +
                bottomPadding +
                12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // GPS location button
                _fab(
                  _locatingUser ? Icons.hourglass_top : Icons.my_location,
                  _locateUser,
                ),
                const SizedBox(height: 8),
                if (_route != null) ...[
                  _fab(Icons.file_download, _exportGpx),
                  const SizedBox(height: 8),
                  _fab(
                    _showElevation ? Icons.expand_more : Icons.expand_less,
                    () => setState(() => _showElevation = !_showElevation),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_waypoints.isNotEmpty)
                  _fab(Icons.delete_outline, _clearAll),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Gradient Route Polylines --

  List<Polyline> _buildGradientPolylines() {
    final coords = _route!.coordinates;
    if (coords.length < 2) return [];

    final polylines = <Polyline>[];
    // Background shadow
    polylines.add(Polyline(
      points: _routePoints,
      color: Colors.black.withValues(alpha: 0.3),
      strokeWidth: 8,
    ));

    // Colored segments by gradient
    for (int i = 0; i < coords.length - 1; i++) {
      final elevDiff = coords[i + 1][2] - coords[i][2];
      final dist = _haversine(coords[i], coords[i + 1]) * 1000; // meters
      final gradient = dist > 0 ? (elevDiff / dist * 100) : 0.0; // percent

      polylines.add(Polyline(
        points: [
          LatLng(coords[i][1], coords[i][0]),
          LatLng(coords[i + 1][1], coords[i + 1][0]),
        ],
        color: _gradientColor(gradient),
        strokeWidth: 5,
      ));
    }
    return polylines;
  }

  Color _gradientColor(double gradientPercent) {
    // Downhill: blue, flat: green, mild: yellow, steep: orange, very steep: red
    if (gradientPercent < -8) return const Color(0xFF1565C0); // steep downhill
    if (gradientPercent < -3) return const Color(0xFF42A5F5); // downhill
    if (gradientPercent < -1) return const Color(0xFF81D4FA); // mild downhill
    if (gradientPercent < 1) return const Color(0xFF66BB6A);  // flat
    if (gradientPercent < 3) return const Color(0xFFFFEB3B);  // mild uphill
    if (gradientPercent < 6) return const Color(0xFFFFA726);  // uphill
    if (gradientPercent < 10) return const Color(0xFFEF5350); // steep
    return const Color(0xFFB71C1C);                           // very steep
  }

  double _haversine(List<double> a, List<double> b) {
    const r = 6371.0;
    final dLat = (b[1] - a[1]) * pi / 180;
    final dLon = (b[0] - a[0]) * pi / 180;
    final lat1 = a[1] * pi / 180;
    final lat2 = b[1] * pi / 180;
    final x = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(x), sqrt(1 - x));
  }

  // -- Via-Point on Route --

  void _onRouteTap(TapUpDetails details) {
    if (_routePoints.isEmpty || _roundtripMode) return;

    // Convert screen tap to map coordinate
    final renderBox = context.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(details.globalPosition);
    final tapLatLng = _mapController.camera.screenOffsetToLatLng(
      Offset(localPos.dx, localPos.dy),
    );

    final insertIdx = _findWaypointInsertIndex(tapLatLng);

    setState(() {
      _waypoints.insert(insertIdx, tapLatLng);
    });
    _calculateRoute();
  }

  int _findWaypointInsertIndex(LatLng point) {
    if (_waypoints.length < 2) return _waypoints.length;

    // Find which pair of waypoints the point is closest to being between
    double bestDist = double.infinity;
    int bestIdx = _waypoints.length;

    for (int i = 0; i < _waypoints.length - 1; i++) {
      final d = _distToSegment(point, _waypoints[i], _waypoints[i + 1]);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i + 1;
      }
    }
    return bestIdx;
  }

  double _distToSegment(LatLng p, LatLng a, LatLng b) {
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;
    if (dx == 0 && dy == 0) {
      return _latLngDist(p, a);
    }
    var t = ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) /
        (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);
    final proj = LatLng(a.latitude + t * dy, a.longitude + t * dx);
    return _latLngDist(p, proj);
  }

  double _latLngDist(LatLng a, LatLng b) {
    final dx = a.longitude - b.longitude;
    final dy = a.latitude - b.latitude;
    return sqrt(dx * dx + dy * dy);
  }

  // -- GPS Location --

  Future<void> _locateUser() async {
    if (_locatingUser) return;
    setState(() => _locatingUser = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Standort-Berechtigung verweigert');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showError('Standort-Berechtigung dauerhaft verweigert. Bitte in den Einstellungen aktivieren.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final latLng = LatLng(position.latitude, position.longitude);

      setState(() => _currentPosition = latLng);
      _mapController.move(latLng, 14);
    } catch (e) {
      _showError('Standort konnte nicht ermittelt werden: $e');
    } finally {
      if (mounted) setState(() => _locatingUser = false);
    }
  }

  // -- Address Search --

  Future<void> _searchAddress(BuildContext context) async {
    final result = await showAddressSearch(context);
    if (result == null || !mounted) return;

    final latLng = LatLng(result.lat, result.lon);
    _mapController.move(latLng, 14);

    // Add as waypoint
    if (_roundtripMode) {
      _clearAll();
    }
    setState(() {
      _waypoints.add(latLng);
    });
    if (!_roundtripMode && _waypoints.length >= 2) {
      _calculateRoute();
    }
  }

  // -- Helpers --

  String _profileLabel() {
    const labels = {
      'fastbike': 'Rennrad',
      'fastbike-lowtraffic': 'Gravel',
      'trekking': 'Trekking',
      'mtb-zossebart': 'MTB',
    };
    return labels[_profile] ?? _profile;
  }

  void _showProfileSheet(BuildContext context) {
    ProfileSelector(
      selectedProfile: _profile,
      onChanged: _setProfile,
    ).showSheet(context);
  }

  void _showMapStyleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
            child: Text(
              'Kartenstil',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          ...mapStyles.map((style) => ListTile(
            dense: true,
            leading: Text(style.icon, style: const TextStyle(fontSize: 18)),
            title: Text(style.name, style: const TextStyle(color: Colors.white)),
            selected: style.id == _mapStyle.id,
            selectedTileColor: const Color(0xFF4fc3f7).withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: () {
              setState(() => _mapStyle = style);
              Navigator.pop(ctx);
            },
          )),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  List<Marker> _buildMarkers() {
    return _waypoints.indexed.map((entry) {
      final (i, wp) = entry;
      final isStart = i == 0;
      final isEnd = i == _waypoints.length - 1 && _waypoints.length > 1;
      final label = isStart ? 'A' : (isEnd && !_roundtripMode ? 'B' : '');
      final color = isStart
          ? const Color(0xFF66bb6a)
          : (isEnd && !_roundtripMode
              ? const Color(0xFFef5350)
              : const Color(0xFF4fc3f7));
      final isVia = !isStart && !(isEnd && !_roundtripMode);

      return Marker(
        point: wp,
        width: isVia ? 20 : 28,
        height: isVia ? 20 : 28,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onPanStart: (_) {
            setState(() => _draggingWaypointIndex = i);
          },
          onPanUpdate: (details) {
            if (_draggingWaypointIndex == null) return;
            final renderBox = context.findRenderObject() as RenderBox;
            final localPos = renderBox.globalToLocal(details.globalPosition);
            final newLatLng = _mapController.camera.screenOffsetToLatLng(
              Offset(localPos.dx, localPos.dy),
            );
            setState(() {
              _waypoints[_draggingWaypointIndex!] = newLatLng;
            });
          },
          onPanEnd: (_) {
            _draggingWaypointIndex = null;
            if (!_roundtripMode && _waypoints.length >= 2) {
              _calculateRoute();
            }
          },
          onLongPress: () {
            // Long press to remove via-point
            if (_waypoints.length > 2 && !isStart && !(isEnd && !_roundtripMode)) {
              setState(() => _waypoints.removeAt(i));
              _calculateRoute();
            }
          },
          child: Container(
            width: isVia ? 20 : 28,
            height: isVia ? 20 : 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: label.isNotEmpty
                ? Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      );
    }).toList();
  }

  Widget _modeChip(String label, bool isRoundtrip) {
    final active = _roundtripMode == isRoundtrip;
    return GestureDetector(
      onTap: () {
        if (_roundtripMode == isRoundtrip) return;
        _clearAll();
        setState(() {
          _roundtripMode = isRoundtrip;
          _showControls = isRoundtrip;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4fc3f7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white60,
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _fab(IconData icon, VoidCallback onTap) {
    return FloatingActionButton.small(
      heroTag: icon.hashCode,
      backgroundColor: const Color(0xFF222244),
      foregroundColor: const Color(0xFF4fc3f7),
      onPressed: onTap,
      child: Icon(icon),
    );
  }

  void _onMapTap(LatLng latLng) {
    if (_roundtripMode) {
      _clearAll();
    }
    setState(() {
      _waypoints.add(latLng);
    });
    if (!_roundtripMode && _waypoints.length >= 2) {
      _calculateRoute();
    }
  }

  void _setProfile(String profile) {
    setState(() => _profile = profile);
    if (!_roundtripMode && _waypoints.length >= 2) {
      _calculateRoute();
    }
  }

  Future<void> _calculateRoute() async {
    if (_loading || _waypoints.length < 2) return;
    setState(() => _loading = true);

    try {
      final pts = _waypoints.map((w) => [w.longitude, w.latitude]).toList();
      final result = await BRouterService.calculateRoute(
        waypoints: pts,
        profile: _profile,
      );
      _displayRoute(result);
    } catch (e) {
      _showError('Routing fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _calculateRoundtrip(RoundtripRequest req) async {
    if (_loading || _waypoints.isEmpty) return;
    setState(() => _loading = true);

    try {
      final start = _waypoints.first;
      final RouteResult result;
      if (req.useTime) {
        final speed = BikeProfile.byId(_profile)?.avgSpeedKmh ?? 20;
        result = await BRouterService.calculateRoundtripByTime(
          start: [start.longitude, start.latitude],
          profile: _profile,
          timeMinutes: req.timeMinutes,
          avgSpeedKmh: speed,
          direction: _rtDirection,
        );
      } else {
        result = await BRouterService.calculateRoundtrip(
          start: [start.longitude, start.latitude],
          profile: _profile,
          distanceKm: req.distanceKm,
          direction: _rtDirection,
        );
      }
      _displayRoute(result);
    } catch (e) {
      _showError('Rundtour fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _displayRoute(RouteResult result) {
    final points = result.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    if (points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(40, 80, 40, 220),
        ),
      );
    }

    setState(() {
      _route = result;
      _routePoints = points;
      _showElevation = true;
      _highlightIndex = null;
    });
  }

  Future<void> _exportGpx() async {
    if (_route == null) return;

    try {
      final String gpx;
      if (_roundtripMode) {
        gpx = await BRouterService.fetchRoundtripGpx(
          start: [_waypoints.first.longitude, _waypoints.first.latitude],
          profile: _profile,
          distanceKm: _rtDistanceKm,
          direction: _rtDirection,
        );
      } else {
        final pts = _waypoints.map((w) => [w.longitude, w.latitude]).toList();
        gpx = await BRouterService.fetchGpx(waypoints: pts, profile: _profile);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'bikerouter-$_profile-$timestamp.gpx';

      await exportGpxFile(filename, gpx);
    } catch (e) {
      _showError('Export fehlgeschlagen: $e');
    }
  }

  void _clearAll() {
    _waypoints.clear();
    setState(() {
      _route = null;
      _routePoints = [];
      _highlightIndex = null;
    });
  }
}
