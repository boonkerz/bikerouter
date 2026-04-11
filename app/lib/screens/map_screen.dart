import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/route_result.dart';
import '../services/brouter_service.dart';
import '../widgets/elevation_chart.dart';
import '../widgets/stats_bar.dart';
import '../widgets/profile_selector.dart';
import '../widgets/roundtrip_panel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController? _mapController;
  StyleController? _styleController;
  final List<Geographic> _waypoints = [];
  RouteResult? _route;
  bool _loading = false;
  String _profile = 'fastbike';
  bool _roundtripMode = false;
  int _rtDistanceKm = 20;
  int _rtDirection = 0;
  bool _showElevation = true;
  bool _routeSourceAdded = false;

  static const _styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map + Stats + Elevation
          Column(
            children: [
              Expanded(
                child: MapLibreMap(
                  options: const MapOptions(
                    initStyle: _styleUrl,
                    initCenter: Geographic(lon: 10.45, lat: 51.16),
                    initZoom: 6,
                  ),
                  onMapCreated: _onMapCreated,
                  onStyleLoaded: _onStyleLoaded,
                  onEvent: _onEvent,
                  children: [
                    // Waypoint markers as WidgetLayer
                    if (_waypoints.isNotEmpty)
                      WidgetLayer(
                        allowInteraction: true,
                        markers: _buildMarkers(),
                      ),
                  ],
                ),
              ),
              if (_route != null) StatsBar(route: _route!),
              if (_route != null && _showElevation)
                ElevationChart(coordinates: _route!.coordinates),
            ],
          ),

          // Top controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Mode toggle
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _modeButton('A → B', false),
                        _modeButton('Rundtour', true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Profile selector
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ProfileSelector(
                    selectedProfile: _profile,
                    onChanged: _setProfile,
                  ),
                ),
              ],
            ),
          ),

          // Roundtrip panel
          if (_roundtripMode)
            Positioned(
              bottom: (_route != null ? 160 + 50.0 : 0) +
                  MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(8),
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
                  onGenerate: _calculateRoundtrip,
                  onShuffle: () {
                    setState(() => _rtDirection = (_rtDirection + 60) % 360);
                    _calculateRoundtrip();
                  },
                ),
              ),
            ),

          // Loading indicator
          if (_loading)
            const Center(
                child: CircularProgressIndicator(color: Color(0xFF4fc3f7))),

          // Action buttons (bottom right)
          Positioned(
            right: 12,
            bottom: (_route != null ? 160 + 50.0 : 0) +
                MediaQuery.of(context).padding.bottom +
                12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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

  List<Marker> _buildMarkers() {
    return _waypoints.indexed.map((entry) {
      final (i, wp) = entry;
      final isStart = i == 0;
      final label = isStart ? 'A' : String.fromCharCode(65 + i);
      final color = isStart ? const Color(0xFF66bb6a) : const Color(0xFFef5350);

      return Marker(
        point: wp,
        size: const Size(32, 32),
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _modeButton(String label, bool isRoundtrip) {
    final active = _roundtripMode == isRoundtrip;
    return GestureDetector(
      onTap: () {
        if (_roundtripMode == isRoundtrip) return;
        _clearAll();
        setState(() => _roundtripMode = isRoundtrip);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4fc3f7) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
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

  void _onMapCreated(MapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded(StyleController style) {
    _styleController = style;
  }

  void _onEvent(MapEvent event) {
    if (event is MapEventClick) {
      _onMapClick(event.point);
    }
  }

  void _onMapClick(Geographic point) {
    if (_roundtripMode) {
      _clearAll();
      _addWaypoint(point);
    } else {
      _addWaypoint(point);
    }
  }

  void _addWaypoint(Geographic point) {
    setState(() {
      _waypoints.add(point);
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
      final pts = _waypoints.map((w) => [w.lon, w.lat]).toList();
      final result = await BRouterService.calculateRoute(
        waypoints: pts,
        profile: _profile,
      );
      _displayRoute(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Routing fehlgeschlagen: $e')),
        );
      }
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
        start: [start.lon, start.lat],
        profile: _profile,
        distanceKm: _rtDistanceKm,
        direction: _rtDirection,
      );
      _displayRoute(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rundtour fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _displayRoute(RouteResult result) async {
    final style = _styleController;
    if (style == null) return;

    final geojsonStr = jsonEncode(result.geojson);

    if (_routeSourceAdded) {
      // Update existing source data
      await style.updateGeoJsonSource(id: 'route', data: geojsonStr);
    } else {
      // Add source and layers for the first time
      await style.addSource(GeoJsonSource(id: 'route', data: geojsonStr));
      await style.addLayer(LineStyleLayer(
        id: 'route-outline',
        sourceId: 'route',
        paint: {
          'line-color': '#1565c0',
          'line-width': 8,
          'line-opacity': 0.4,
        },
        layout: {
          'line-cap': 'round',
          'line-join': 'round',
        },
      ));
      await style.addLayer(LineStyleLayer(
        id: 'route-line',
        sourceId: 'route',
        paint: {
          'line-color': '#4fc3f7',
          'line-width': 4,
          'line-opacity': 0.9,
        },
        layout: {
          'line-cap': 'round',
          'line-join': 'round',
        },
      ));
      _routeSourceAdded = true;
    }

    // Fit bounds to route
    if (result.coordinates.isNotEmpty) {
      final points = result.coordinates
          .map((c) => Geographic(lon: c[0], lat: c[1]))
          .toList();
      final bounds = LngLatBounds.fromPoints(points);
      await _mapController?.fitBounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(40, 160, 40, 220),
      );
    }

    setState(() {
      _route = result;
      _showElevation = true;
    });
  }

  Future<void> _exportGpx() async {
    if (_waypoints.length < 2 && !_roundtripMode) return;

    try {
      final pts = _waypoints.map((w) => [w.lon, w.lat]).toList();
      final gpx =
          await BRouterService.fetchGpx(waypoints: pts, profile: _profile);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bikerouter-$_profile.gpx');
      await file.writeAsString(gpx);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        title: 'BikeRouter GPX Export',
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export fehlgeschlagen: $e')),
        );
      }
    }
  }

  Future<void> _clearAll() async {
    if (_routeSourceAdded) {
      final style = _styleController;
      if (style != null) {
        try {
          await style.removeLayer('route-line');
          await style.removeLayer('route-outline');
          await style.removeSource('route');
        } catch (_) {}
      }
      _routeSourceAdded = false;
    }
    _waypoints.clear();
    setState(() => _route = null);
  }
}
