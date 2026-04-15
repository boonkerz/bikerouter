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
import 'settings_screen.dart';

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
  int? _hoveredWaypointIndex; // Waypoint near cursor
  int? _selectedWaypointIndex; // Tapped waypoint showing delete option
  LatLng? _routeHoverPoint; // Preview point when hovering near route
  final Set<int> _anchorIndices = {}; // Anchor points for roundtrip shape

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
                child: Listener(
                  onPointerMove: (event) {
                    if (_draggingWaypointIndex != null) {
                      final latLng = _mapController.camera.screenOffsetToLatLng(
                        event.localPosition,
                      );
                      setState(() => _waypoints[_draggingWaypointIndex!] = latLng);
                    }
                  },
                  onPointerUp: (_) {
                    if (_draggingWaypointIndex != null) {
                      _finishDrag();
                    }
                  },
                  child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(51.16, 10.45),
                    initialZoom: 6,
                    onTap: (tapPos, latLng) => _onMapTap(latLng),
                    onLongPress: (tapPos, latLng) => _onMapLongPress(latLng),
                    onPointerHover: (event, latLng) => _onMapHover(latLng),
                    interactionOptions: InteractionOptions(
                      flags: _draggingWaypointIndex != null
                          ? InteractiveFlag.none
                          : InteractiveFlag.all,
                    ),
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
                    // Hover preview point on route
                    if (_routeHoverPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _routeHoverPoint!,
                            width: 18,
                            height: 18,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF4fc3f7).withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_waypoints.isNotEmpty)
                      MarkerLayer(markers: _buildMarkers()),
                  ],
                ),
              ),),
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
                // Settings button
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.more_vert, color: Color(0xFF4fc3f7), size: 20),
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

  int _findWaypointInsertIndex(LatLng point) {
    if (_waypoints.length < 2) return _waypoints.length;

    // Find the nearest point on the actual route
    int bestRouteIdx = 0;
    double bestRouteDist = double.infinity;
    for (int i = 0; i < _routePoints.length; i++) {
      final d = _latLngDist(point, _routePoints[i]);
      if (d < bestRouteDist) {
        bestRouteDist = d;
        bestRouteIdx = i;
      }
    }

    // Now find which waypoint pair this route point falls between
    // by finding the nearest route point to each waypoint
    final wpRouteIndices = <int>[];
    for (final wp in _waypoints) {
      int bestIdx = 0;
      double bestDist = double.infinity;
      for (int i = 0; i < _routePoints.length; i++) {
        final d = _latLngDist(wp, _routePoints[i]);
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
      wpRouteIndices.add(bestIdx);
    }

    // Find between which waypoints the route index falls
    for (int i = 0; i < wpRouteIndices.length - 1; i++) {
      final startIdx = wpRouteIndices[i];
      final endIdx = wpRouteIndices[i + 1];
      if (startIdx <= endIdx) {
        if (bestRouteIdx >= startIdx && bestRouteIdx <= endIdx) return i + 1;
      } else {
        if (bestRouteIdx >= startIdx || bestRouteIdx <= endIdx) return i + 1;
      }
    }

    // For roundtrip: check last waypoint → start segment
    if (_roundtripMode) {
      return _waypoints.length;
    }

    return _waypoints.length;
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
    final markers = <Marker>[];
    for (final entry in _waypoints.indexed) {
      final (i, wp) = entry;
      final isAnchor = _anchorIndices.contains(i);
      final isStart = i == 0;
      final isEnd = i == _waypoints.length - 1 && _waypoints.length > 1;
      final isDragging = _draggingWaypointIndex == i;
      final isHovered = _hoveredWaypointIndex == i;
      final isSelected = _selectedWaypointIndex == i;
      final canDelete = !isStart && _waypoints.length > 2;

      final Color color;
      if (isStart) {
        color = const Color(0xFF66bb6a);
      } else if (isEnd && !_roundtripMode) {
        color = const Color(0xFFef5350);
      } else {
        color = const Color(0xFF4fc3f7);
      }

      double size;
      if (isAnchor) {
        size = isDragging ? 22.0 : (isHovered ? 20.0 : 14.0);
      } else if (isStart || (isEnd && !_roundtripMode)) {
        size = isDragging ? 36.0 : (isHovered ? 32.0 : 28.0);
      } else {
        size = isDragging ? 28.0 : (isHovered ? 24.0 : 20.0);
      }

      final label = isStart ? 'A' : (isEnd && !_roundtripMode ? 'B' : '');

      markers.add(Marker(
        point: wp,
        width: isSelected ? 36 : size,
        height: isSelected ? 56 : size,
        alignment: Alignment.topCenter,
        child: isSelected && canDelete
            ? GestureDetector(
                onTap: () => _deleteWaypoint(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFef5350),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.delete, color: Colors.white, size: 16),
                    ),
                    Container(
                      width: 2,
                      height: 8,
                      color: const Color(0xFFef5350),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: (isDragging || isHovered) ? color : color.withValues(alpha: isAnchor ? 0.7 : 1.0),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: isDragging ? 3 : (isHovered ? 2.5 : isAnchor ? 1.5 : 2)),
                  boxShadow: [
                    BoxShadow(
                      color: (isDragging || isHovered) ? color.withValues(alpha: 0.5) : Colors.black26,
                      blurRadius: isDragging ? 12 : (isHovered ? 8 : isAnchor ? 2 : 4),
                    ),
                  ],
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
      ));
    }
    return markers;
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

  double get _hoverThreshold =>
      360.0 / (pow(2, _mapController.camera.zoom) * 256) * 25;

  void _onMapHover(LatLng latLng) {
    if (_draggingWaypointIndex != null) return;

    // Check if near an existing waypoint
    final nearWp = _findNearestWaypoint(latLng);
    if (nearWp != null) {
      setState(() {
        _hoveredWaypointIndex = nearWp;
        _routeHoverPoint = null;
      });
      return;
    }

    if (_hoveredWaypointIndex != null) {
      setState(() => _hoveredWaypointIndex = null);
    }

    if (_routePoints.isEmpty || _route == null) {
      if (_routeHoverPoint != null) setState(() => _routeHoverPoint = null);
      return;
    }

    final nearestPoint = _nearestPointOnRoute(latLng);
    final dist = _latLngDist(latLng, nearestPoint);

    if (dist < _hoverThreshold) {
      setState(() => _routeHoverPoint = nearestPoint);
    } else if (_routeHoverPoint != null) {
      setState(() => _routeHoverPoint = null);
    }
  }

  int? _findNearestWaypoint(LatLng point) {
    final threshold = _hoverThreshold * 1.5;
    double bestDist = double.infinity;
    int? bestIdx;
    for (int i = 0; i < _waypoints.length; i++) {
      final d = _latLngDist(point, _waypoints[i]);
      if (d < bestDist && d < threshold) {
        bestDist = d;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  void _onMapTap(LatLng latLng) {
    if (_draggingWaypointIndex != null) return; // Drag handled by Listener

    // Check if tapping near a waypoint → select/deselect
    final nearWp = _findNearestWaypoint(latLng);
    if (nearWp != null) {
      setState(() {
        _selectedWaypointIndex = _selectedWaypointIndex == nearWp ? null : nearWp;
      });
      return;
    }

    // Tap elsewhere → deselect any selected waypoint
    if (_selectedWaypointIndex != null) {
      setState(() => _selectedWaypointIndex = null);
      return;
    }

    if (_roundtripMode && _waypoints.isEmpty) {
      setState(() => _waypoints.add(latLng));
      return;
    }

    // If hovering on route → insert via-point
    if (_routeHoverPoint != null) {
      _insertViaPoint(_routeHoverPoint!);
      return;
    }

    // Touch: check if near route → insert via-point
    if (_routePoints.isNotEmpty && _route != null) {
      final nearest = _nearestPointOnRoute(latLng);
      final dist = _latLngDist(latLng, nearest);
      if (dist < _hoverThreshold) {
        _insertViaPoint(nearest);
        return;
      }
    }

    // Roundtrip mode with existing route: don't add new points
    if (_roundtripMode && _route != null) return;

    setState(() => _waypoints.add(latLng));
    if (!_roundtripMode && _waypoints.length >= 2) {
      _calculateRoute();
    }
  }

  void _insertViaPoint(LatLng point) {
    // Exit roundtrip mode on manual edit
    if (_roundtripMode) _exitRoundtripMode();

    final insertIdx = _findWaypointInsertIndex(point);

    setState(() {
      _waypoints.insert(insertIdx, point);
      _routeHoverPoint = null;
      _draggingWaypointIndex = insertIdx;
    });
  }

  void _onMapLongPress(LatLng latLng) {
    // Find nearest waypoint for drag
    double bestDist = double.infinity;
    int bestIdx = -1;
    for (int i = 0; i < _waypoints.length; i++) {
      final d = _latLngDist(latLng, _waypoints[i]);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    // Start drag if close enough to a waypoint
    if (bestIdx >= 0 && bestDist < _hoverThreshold * 2) {
      setState(() => _draggingWaypointIndex = bestIdx);
    }
  }

  void _finishDrag() {
    final idx = _draggingWaypointIndex;
    setState(() => _draggingWaypointIndex = null);
    if (idx != null) {
      if (_roundtripMode) _exitRoundtripMode();
      _recalculate();
    }
  }

  /// Exit roundtrip mode: close the loop with explicit waypoints
  void _exitRoundtripMode() {
    // Add start point as end to close the loop explicitly
    _waypoints.add(LatLng(_waypoints.first.latitude, _waypoints.first.longitude));
    _anchorIndices.clear();
    setState(() => _roundtripMode = false);
  }

  /// Recalculate route: works for both A→B and roundtrip (with via-points)
  void _recalculate() {
    if (_waypoints.length >= 2) {
      _calculateRoute();
    }
  }

  LatLng _nearestPointOnRoute(LatLng point) {
    double bestDist = double.infinity;
    LatLng bestPoint = _routePoints.first;

    for (int i = 0; i < _routePoints.length - 1; i++) {
      final projected = _projectOnSegment(point, _routePoints[i], _routePoints[i + 1]);
      final d = _latLngDist(point, projected);
      if (d < bestDist) {
        bestDist = d;
        bestPoint = projected;
      }
    }
    return bestPoint;
  }

  LatLng _projectOnSegment(LatLng p, LatLng a, LatLng b) {
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;
    if (dx == 0 && dy == 0) return a;
    var t = ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) /
        (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);
    return LatLng(a.latitude + t * dy, a.longitude + t * dx);
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
      // In roundtrip mode with via-points, close the loop back to start
      if (_roundtripMode && pts.length >= 2) {
        pts.add(pts.first);
      }
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

    // In roundtrip mode with only start point, auto-generate anchor points
    if (_roundtripMode && _waypoints.length == 1 && points.length > 2) {
      _generateAnchors();
    }
  }

  void _generateAnchors() {
    final start = _waypoints.first;
    _anchorIndices.clear();

    final anchors = <LatLng>[];
    double dist = 0;
    for (int i = 1; i < _routePoints.length - 1; i++) {
      dist += _latLngDist(_routePoints[i - 1], _routePoints[i]) * 111;
      if (dist >= 2.0) {
        anchors.add(_routePoints[i]);
        dist = 0;
      }
    }

    _waypoints.clear();
    _waypoints.add(start);
    for (final a in anchors) {
      _waypoints.add(a);
      _anchorIndices.add(_waypoints.length - 1);
    }
    setState(() {});
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

  void _deleteWaypoint(int index) {
    if (index < 0 || index >= _waypoints.length) return;

    // Remove waypoint and adjust anchor indices
    _waypoints.removeAt(index);
    final shifted = <int>{};
    for (final i in _anchorIndices) {
      if (i < index) {
        shifted.add(i);
      } else if (i > index) {
        shifted.add(i - 1);
      }
      // i == index → removed, don't add
    }
    _anchorIndices.clear();
    _anchorIndices.addAll(shifted);

    setState(() {
      _selectedWaypointIndex = null;
      _hoveredWaypointIndex = null;
    });

    // Exit roundtrip mode on manual edit
    if (_roundtripMode) {
      _exitRoundtripMode();
    }

    // Recalculate or clear route
    if (_waypoints.length >= 2) {
      _recalculate();
    } else {
      setState(() {
        _route = null;
        _routePoints = [];
        _highlightIndex = null;
      });
    }
  }

  void _clearAll() {
    _waypoints.clear();
    _anchorIndices.clear();
    setState(() {
      _route = null;
      _routePoints = [];
      _highlightIndex = null;
    });
  }
}
