import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _roundtripMode = false;
  int _rtDistanceKm = 20;
  int _rtDirection = 0;
  bool _showElevation = true;
  bool _showControls = false;
  int? _highlightIndex;
  LatLng? _currentPosition;
  bool _locatingUser = false;

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
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'de.bikerouter.app',
                    ),
                    if (_routePoints.isNotEmpty) ...[
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
                  onDistanceChanged: (v) => setState(() => _rtDistanceKm = v),
                  onDirectionChanged: (v) => setState(() => _rtDirection = v),
                  onGenerate: () {
                    _calculateRoundtrip();
                    setState(() => _showControls = false);
                  },
                  onShuffle: () {
                    setState(() => _rtDirection = (_rtDirection + 60) % 360);
                    _calculateRoundtrip();
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
      final label = isStart ? 'A' : String.fromCharCode(65 + i);
      final color = isStart ? const Color(0xFF66bb6a) : const Color(0xFFef5350);

      return Marker(
        point: wp,
        width: 28,
        height: 28,
        alignment: Alignment.topCenter,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  Future<void> _calculateRoundtrip() async {
    if (_loading || _waypoints.isEmpty) return;
    setState(() => _loading = true);

    try {
      final start = _waypoints.first;
      final result = await BRouterService.calculateRoundtrip(
        start: [start.longitude, start.latitude],
        profile: _profile,
        distanceKm: _rtDistanceKm,
        direction: _rtDirection,
      );
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
      // For roundtrip, use stored route coordinates; for A→B use waypoints
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

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/bikerouter-$_profile-$timestamp.gpx');
      await file.writeAsString(gpx);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/gpx+xml')],
      ));
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
