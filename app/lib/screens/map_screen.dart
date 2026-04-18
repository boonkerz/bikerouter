import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/gpx_export.dart';

import '../models/map_style.dart';
import '../models/osm_sight.dart';
import '../models/profile.dart';
import '../models/route_result.dart';
import '../models/route_segment.dart';
import '../models/route_poi.dart';
import '../models/saved_route.dart';
import '../services/brouter_service.dart';
import '../services/gpx_builder.dart';
import '../services/route_storage.dart';
import '../services/geocoding_service.dart';
import '../services/route_share.dart';
import '../services/share_url.dart';
import '../services/sights_service.dart';
import '../services/sight_prefs.dart';
import '../services/route_info_service.dart';
import '../widgets/elevation_chart.dart';
import '../services/stage_planner.dart';
import '../widgets/accommodation_sheet.dart';
import '../widgets/stages_sheet.dart';
import '../widgets/surface_chart.dart';
import '../widgets/stats_bar.dart';
import '../widgets/weather_sheet.dart';
import '../widgets/profile_selector.dart';
import '../widgets/roundtrip_panel.dart';
import '../widgets/address_search.dart';
import 'settings_screen.dart';
import 'saved_routes_screen.dart';

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
  // 'surface' colors the route by OSM surface tags, 'gradient' by elevation slope.
  String _routeVizMode = 'surface';
  int? _draggingWaypointIndex;
  int? _hoveredWaypointIndex; // Waypoint near cursor
  int? _selectedWaypointIndex; // Tapped waypoint showing delete option
  LatLng? _routeHoverPoint; // Preview point when hovering near route
  final Set<int> _anchorIndices = {}; // Anchor points for roundtrip shape
  final List<RoutePoi> _pois = [];
  List<OsmSight> _sights = [];
  bool _loadingSights = false;
  Set<String> _enabledSightTypes = allSightTypes;
  Set<String> _activeOverlays = {};
  bool _routeInspectMode = false;
  bool _loadingRouteInfo = false;
  RoundtripRequest? _lastRoundtripRequest;
  List<Stage> _stages = [];
  final Map<String, String> _waypointNames = {}; // key: "lat,lon" at 5 dp
  final Set<String> _waypointNamesInflight = {};

  String _wpKey(LatLng p) =>
      '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}';

  Future<void> _resolveWaypointName(LatLng p) async {
    final key = _wpKey(p);
    if (_waypointNames.containsKey(key) || _waypointNamesInflight.contains(key)) {
      return;
    }
    _waypointNamesInflight.add(key);
    final name = await GeocodingService.reverse(p.latitude, p.longitude);
    _waypointNamesInflight.remove(key);
    if (name != null && mounted) {
      setState(() => _waypointNames[key] = name);
    }
  }

  @override
  void initState() {
    super.initState();
    SightPrefs.load().then((v) {
      if (mounted) setState(() => _enabledSightTypes = v);
    });
    SharedPreferences.getInstance().then((prefs) {
      final list = prefs.getStringList('active_route_overlays_v1');
      if (list != null && mounted) setState(() => _activeOverlays = list.toSet());
      final mode = prefs.getString('route_viz_mode_v1');
      if (mode != null && mounted) setState(() => _routeVizMode = mode);
    });
    _tryLoadSharedRoute();
  }

  void _tryLoadSharedRoute() {
    final param = readShareParam();
    if (param == null || param.isEmpty) return;
    final shared = SharedRoute.decode(param);
    if (shared == null) return;
    final pts = shared.waypoints.map((p) => LatLng(p[0], p[1])).toList();
    setState(() {
      _waypoints
        ..clear()
        ..addAll(pts);
      _profile = shared.profile;
      _roundtripMode = shared.roundtrip;
      if (shared.roundtripDistanceKm != null) {
        _rtDistanceKm = shared.roundtripDistanceKm!;
      }
      if (shared.roundtripDirection != null) {
        _rtDirection = shared.roundtripDirection!;
      }
    });
    for (final wp in pts) {
      _resolveWaypointName(wp);
    }
    if (pts.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(pts);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.fitCamera(CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(60),
        ));
      });
    }
    if (_roundtripMode && pts.isNotEmpty) {
      _calculateRoundtrip(RoundtripRequest(
        distanceKm: _rtDistanceKm,
        useTime: false,
        timeMinutes: 0,
      ));
    } else if (pts.length >= 2) {
      _calculateRoute();
    }
  }

  Future<void> _saveOverlayPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('active_route_overlays_v1', _activeOverlays.toList());
  }

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
                      userAgentPackageName: 'app.wegwiesel',
                    ),
                    if (_mapStyle.labelsOverlay != null)
                      TileLayer(
                        urlTemplate: _mapStyle.labelsOverlay!,
                        maxZoom: _mapStyle.maxZoom.toDouble(),
                        userAgentPackageName: 'app.wegwiesel',
                      ),
                    for (final ov in routeOverlays.where((o) => _activeOverlays.contains(o.id)))
                      TileLayer(
                        urlTemplate: ov.urlTemplate,
                        maxZoom: 18,
                        userAgentPackageName: 'app.wegwiesel',
                      ),
                    if (_routePoints.isNotEmpty) ...[
                      if (_route != null && _routeVizMode == 'surface' && _route!.segments.isNotEmpty)
                        PolylineLayer(polylines: _buildSurfacePolylines())
                      else if (_route != null && _routeVizMode == 'gradient')
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
                    if (_sights.isNotEmpty)
                      MarkerLayer(markers: _buildSightMarkers()),
                    if (_stages.isNotEmpty)
                      MarkerLayer(markers: _buildStageMarkers()),
                    if (_waypoints.isNotEmpty)
                      MarkerLayer(markers: _buildMarkers()),
                    if (_pois.isNotEmpty)
                      MarkerLayer(markers: _buildPoiMarkers()),
                  ],
                ),
              ),),
              if (_route != null)
                StatsBar(route: _route!, actions: _buildStatsActions()),
              if (_route != null && _showElevation && _route!.segments.isNotEmpty)
                SurfaceChart(
                  segments: _route!.segments,
                  totalDistanceKm: _route!.distance,
                  onHover: (index) => setState(() => _highlightIndex = index),
                ),
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
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showProfileSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a1a2e).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _profileLabel(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF4fc3f7), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_more, color: Color(0xFF4fc3f7), size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
            bottom: (_route != null
                    ? (_showElevation
                        ? 254 + (_route!.segments.isNotEmpty ? 90 : 0)
                        : 94)
                    : 0) +
                bottomPadding +
                12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search button
                _fab(Icons.search, () => _searchAddress(context)),
                const SizedBox(height: 8),
                // GPS location button
                _fab(
                  _locatingUser ? Icons.hourglass_top : Icons.my_location,
                  _locateUser,
                ),
                const SizedBox(height: 8),
                if (_route != null) ...[
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

          // Menu button (bottom left, fixed offset from bottom)
          Positioned(
            left: 12,
            bottom: bottomPadding + 12,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Material(
                color: const Color(0xFF222244),
                shape: const CircleBorder(),
                elevation: 6,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF4fc3f7), size: 20),
                  iconSize: 20,
                  color: const Color(0xFF1a1a2e),
                  padding: EdgeInsets.zero,
                  tooltip: '',
                  onSelected: _onMenuSelected,
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'save',
                      enabled: _route != null,
                      child: const Row(children: [
                        Icon(Icons.bookmark_add_outlined, color: Color(0xFF4fc3f7), size: 20),
                        SizedBox(width: 12),
                        Text('Route speichern', style: TextStyle(color: Colors.white)),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'load',
                      child: Row(children: [
                        Icon(Icons.bookmarks_outlined, color: Color(0xFF4fc3f7), size: 20),
                        SizedBox(width: 12),
                        Text('Gespeicherte Routen', style: TextStyle(color: Colors.white)),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(children: [
                        Icon(Icons.settings_outlined, color: Color(0xFF4fc3f7), size: 20),
                        SizedBox(width: 12),
                        Text('Einstellungen', style: TextStyle(color: Colors.white)),
                      ]),
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

  List<Polyline> _buildSurfacePolylines() {
    final route = _route!;
    final coords = route.coordinates;
    if (coords.length < 2 || route.segments.isEmpty) return [];

    final polylines = <Polyline>[
      Polyline(
        points: _routePoints,
        color: Colors.black.withValues(alpha: 0.3),
        strokeWidth: 8,
      ),
    ];

    for (final seg in route.segments) {
      final end = seg.endCoordIdx.clamp(seg.startCoordIdx + 1, coords.length - 1);
      final pts = <LatLng>[
        for (int i = seg.startCoordIdx; i <= end; i++)
          LatLng(coords[i][1], coords[i][0]),
      ];
      if (pts.length < 2) continue;
      polylines.add(Polyline(
        points: pts,
        color: seg.category.color,
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
    _waypointNames[_wpKey(latLng)] = result.displayName.split(',').take(2).join(',').trim();
    if (!_roundtripMode && _waypoints.length >= 2) {
      _calculateRoute();
    }
  }

  // -- Helpers --

  String _profileLabel() {
    return BikeProfile.byId(_profile)?.name ?? _profile;
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => ListView(
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
            const Divider(color: Colors.white24, height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                'Overlay-Routen',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...routeOverlays.map((ov) => SwitchListTile(
              dense: true,
              secondary: Text(ov.icon, style: const TextStyle(fontSize: 18)),
              title: Text(ov.name, style: const TextStyle(color: Colors.white)),
              value: _activeOverlays.contains(ov.id),
              activeThumbColor: const Color(0xFF4fc3f7),
              onChanged: (v) {
                setSheetState(() {
                  if (v) {
                    _activeOverlays.add(ov.id);
                  } else {
                    _activeOverlays.remove(ov.id);
                  }
                });
                setState(() {});
                _saveOverlayPrefs();
              },
            )),
            const Divider(color: Colors.white24, height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                'Routen-Färbung',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            for (final entry in const [
              ['surface', 'Beschaffenheit', '🛣️'],
              ['gradient', 'Steigung', '📈'],
            ])
              ListTile(
                dense: true,
                leading: Text(entry[2], style: const TextStyle(fontSize: 18)),
                title: Text(entry[1], style: const TextStyle(color: Colors.white)),
                selected: _routeVizMode == entry[0],
                selectedTileColor: const Color(0xFF4fc3f7).withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  setSheetState(() => _routeVizMode = entry[0]);
                  setState(() {});
                  SharedPreferences.getInstance()
                      .then((p) => p.setString('route_viz_mode_v1', entry[0]));
                },
              ),
          ],
        ),
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

      // Hide anchor drag-handles unless actively interacted with — the route hover
      // point already acts as a drag handle, so permanent anchors clutter the map.
      if (isAnchor && !isDragging && !isHovered && !isSelected) continue;

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
      final wpName = _waypointNames[_wpKey(wp)];

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
            : Tooltip(
                message: wpName ?? '',
                triggerMode: TooltipTriggerMode.tap,
                preferBelow: false,
                child: Container(
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

  List<StatsAction> _buildStatsActions() {
    final actions = <StatsAction>[
      StatsAction(
        icon: _sights.isEmpty ? Icons.explore_outlined : Icons.explore_off_outlined,
        label: _sights.isEmpty ? 'Sights' : 'Sights aus',
        loading: _loadingSights,
        active: _sights.isNotEmpty,
        onTap: _toggleSights,
      ),
      StatsAction(
        icon: Icons.tune,
        label: 'Filter',
        onTap: () => _showSightFilterSheet(context),
      ),
      StatsAction(
        icon: Icons.cloud_outlined,
        label: 'Wetter',
        onTap: _showWeather,
      ),
      StatsAction(
        icon: Icons.bed_outlined,
        label: 'Unterkunft',
        onTap: _showAccommodation,
      ),
      StatsAction(
        icon: _stages.isEmpty ? Icons.date_range : Icons.event_available,
        label: 'Etappen',
        active: _stages.isNotEmpty,
        onTap: _showStagesPlanner,
      ),
      StatsAction(
        icon: Icons.share,
        label: 'Teilen',
        onTap: _shareRoute,
      ),
      StatsAction(
        icon: Icons.file_download,
        label: 'GPX',
        onTap: _exportGpx,
      ),
    ];
    if (_activeOverlays.isNotEmpty) {
      actions.add(StatsAction(
        icon: _routeInspectMode ? Icons.close : Icons.info_outline,
        label: 'Info',
        loading: _loadingRouteInfo,
        active: _routeInspectMode,
        onTap: () {
          setState(() => _routeInspectMode = !_routeInspectMode);
          if (_routeInspectMode) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Tippe auf eine Route, um Info zu sehen'),
              duration: Duration(seconds: 3),
            ));
          }
        },
      ));
    }
    return actions;
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

    if (_routeInspectMode) {
      _inspectRoutesAt(latLng);
      return;
    }

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
      _resolveWaypointName(latLng);
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
    _resolveWaypointName(latLng);
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
    _resolveWaypointName(point);
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
      return;
    }
    // Otherwise open POI add sheet
    _showAddPoiSheet(latLng);
  }

  void _showAddPoiSheet(LatLng latLng) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('POI hinzufügen',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: PoiCategory.values.map((cat) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _addPoi(latLng, cat);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: cat.color,
                            shape: BoxShape.circle,
                            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                          ),
                          child: Icon(cat.icon, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 72,
                          child: Text(cat.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addPoi(LatLng latLng, PoiCategory cat) async {
    final poi = RoutePoi(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      lat: latLng.latitude,
      lon: latLng.longitude,
      category: cat,
    );
    setState(() => _pois.add(poi));
    // Offer to name it right away
    await _editPoi(poi);
  }

  Future<void> _editPoi(RoutePoi poi) async {
    final nameCtrl = TextEditingController(text: poi.name ?? '');
    final noteCtrl = TextEditingController(text: poi.note ?? '');
    PoiCategory selectedCat = poi.category;

    final result = await showDialog<_PoiEditResult>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          title: Row(children: [
            Icon(selectedCat.icon, color: selectedCat.color),
            const SizedBox(width: 8),
            const Text('POI bearbeiten', style: TextStyle(color: Colors.white)),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kategorie',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: PoiCategory.values.map((cat) {
                    final selected = cat == selectedCat;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedCat = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? cat.color : Colors.transparent,
                          border: Border.all(color: cat.color, width: selected ? 0 : 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(cat.icon, color: selected ? Colors.white : cat.color, size: 14),
                          const SizedBox(width: 4),
                          Text(cat.label,
                              style: TextStyle(
                                  color: selected ? Colors.white : cat.color, fontSize: 11)),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF4fc3f7))),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF4fc3f7), width: 2)),
                  ),
                ),
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notiz (optional)',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF4fc3f7))),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF4fc3f7), width: 2)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, const _PoiEditResult.delete()),
              child: const Text('Löschen', style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                ctx,
                _PoiEditResult.save(
                  category: selectedCat,
                  name: nameCtrl.text.trim(),
                  note: noteCtrl.text.trim(),
                ),
              ),
              child: const Text('Speichern', style: TextStyle(color: Color(0xFF4fc3f7))),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    if (result.isDelete) {
      setState(() => _pois.removeWhere((p) => p.id == poi.id));
      return;
    }
    setState(() {
      final idx = _pois.indexWhere((p) => p.id == poi.id);
      if (idx >= 0) {
        _pois[idx] = poi.copyWith(
          category: result.category,
          name: result.name!.isEmpty ? null : result.name,
          note: result.note!.isEmpty ? null : result.note,
        );
      }
    });
  }

  List<Marker> _buildPoiMarkers() {
    return _pois.map((p) {
      return Marker(
        point: LatLng(p.lat, p.lon),
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => _editPoi(p),
          child: Container(
            decoration: BoxDecoration(
              color: p.category.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
            ),
            child: Icon(p.category.icon, color: Colors.white, size: 18),
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _buildSightMarkers() {
    return _sights.map((s) {
      return Marker(
        point: LatLng(s.lat, s.lon),
        width: 32,
        height: 32,
        child: Tooltip(
          message: s.name != null ? '${s.name}\n${s.subtypeLabel}' : s.subtypeLabel,
          waitDuration: const Duration(milliseconds: 200),
          preferBelow: false,
          child: GestureDetector(
            onTap: () => _showSightInfo(s),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                decoration: BoxDecoration(
                  color: _sightColor(s.category),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                ),
                child: Icon(_sightIcon(s), color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _sightColor(String category) {
    switch (category) {
      case 'tourism':
        return const Color(0xFFFF9800); // orange
      case 'historic':
        return const Color(0xFF8D6E63); // brown
      case 'natural':
        return const Color(0xFF43A047); // green
      case 'shop':
        return const Color(0xFFAB47BC); // purple
      case 'amenity':
        return const Color(0xFF26A69A); // teal
      case 'railway':
        return const Color(0xFF5C6BC0); // indigo
      default:
        return const Color(0xFF757575);
    }
  }

  IconData _sightIcon(OsmSight s) {
    switch (s.subtype) {
      case 'viewpoint':
        return Icons.visibility;
      case 'museum':
        return Icons.museum;
      case 'artwork':
        return Icons.palette;
      case 'picnic_site':
        return Icons.deck;
      case 'information':
        return Icons.info_outline;
      case 'hotel':
      case 'guest_house':
      case 'hostel':
        return Icons.hotel;
      case 'camp_site':
        return Icons.holiday_village;
      case 'castle':
        return Icons.castle;
      case 'monument':
      case 'memorial':
        return Icons.account_balance;
      case 'ruins':
      case 'archaeological_site':
        return Icons.history_edu;
      case 'peak':
        return Icons.terrain;
      case 'waterfall':
        return Icons.water_drop;
      case 'cave_entrance':
        return Icons.landscape;
      case 'supermarket':
        return Icons.shopping_cart;
      case 'bakery':
        return Icons.bakery_dining;
      case 'convenience':
        return Icons.local_convenience_store;
      case 'bicycle':
        return Icons.pedal_bike;
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'fast_food':
        return Icons.fastfood;
      case 'biergarten':
      case 'pub':
        return Icons.sports_bar;
      case 'drinking_water':
        return Icons.water_drop;
      case 'toilets':
        return Icons.wc;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'atm':
        return Icons.atm;
      case 'bicycle_repair_station':
        return Icons.build;
      case 'bicycle_rental':
        return Icons.pedal_bike;
      case 'charging_station':
        return Icons.ev_station;
      case 'station':
      case 'halt':
        return Icons.train;
      case 'tram_stop':
        return Icons.tram;
      default:
        return Icons.place;
    }
  }

  void _showSightFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          void toggle(String key, bool? v) {
            setSheetState(() {
              if (v == true) {
                _enabledSightTypes.add(key);
              } else {
                _enabledSightTypes.remove(key);
              }
            });
            setState(() {});
            SightPrefs.save(_enabledSightTypes);
          }

          void toggleCategory(String cat, bool enable) {
            setSheetState(() {
              for (final sub in sightTypes[cat]!.keys) {
                final key = '$cat:$sub';
                if (enable) {
                  _enabledSightTypes.add(key);
                } else {
                  _enabledSightTypes.remove(key);
                }
              }
            });
            setState(() {});
            SightPrefs.save(_enabledSightTypes);
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollCtrl) => ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text('POI-Typen',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                for (final cat in sightTypes.keys) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(color: _sightColor(cat), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sightCategoryLabels[cat] ?? cat,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final allOn = sightTypes[cat]!.keys.every((s) => _enabledSightTypes.contains('$cat:$s'));
                            toggleCategory(cat, !allOn);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF4fc3f7),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 28),
                          ),
                          child: Text(
                            sightTypes[cat]!.keys.every((s) => _enabledSightTypes.contains('$cat:$s'))
                                ? 'Keine' : 'Alle',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final entry in sightTypes[cat]!.entries)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _enabledSightTypes.contains('$cat:${entry.key}'),
                      onChanged: (v) => toggle('$cat:${entry.key}', v),
                      activeColor: const Color(0xFF4fc3f7),
                      checkColor: Colors.black,
                      title: Text(entry.value, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    ).then((_) {
      if (_sights.isNotEmpty && _route != null) _refetchSights();
    });
  }

  Future<void> _inspectRoutesAt(LatLng latLng) async {
    if (_loadingRouteInfo) return;
    setState(() => _loadingRouteInfo = true);
    try {
      final routes = await RouteInfoService.fetchAtPoint(
        latLng.latitude,
        latLng.longitude,
      );
      if (!mounted) return;
      setState(() {
        _routeInspectMode = false;
        _loadingRouteInfo = false;
      });
      if (routes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Keine Route an dieser Stelle gefunden'),
          duration: Duration(seconds: 2),
        ));
        return;
      }
      if (routes.length == 1) {
        _showRouteInfoSheet(routes.first);
      } else {
        _showRoutesListSheet(routes);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRouteInfo = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Overpass-Fehler: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    }
  }

  void _showRoutesListSheet(List<OsmRouteInfo> routes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: routes.length > 3 ? 0.5 : 0.35,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${routes.length} Route${routes.length == 1 ? '' : 'n'} hier',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final r in routes)
              ListTile(
                dense: true,
                leading: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: _routeColor(r), shape: BoxShape.circle),
                  child: Icon(_routeIcon(r), color: Colors.white, size: 18),
                ),
                title: Text(r.displayName, style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text(
                  [r.typeLabel, if (r.network != null) r.networkLabel].join(' · '),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRouteInfoSheet(r);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showRouteInfoSheet(OsmRouteInfo r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: _buildRouteSheetChildren(ctx, r),
        ),
      ),
    );
  }

  List<Widget> _buildRouteSheetChildren(BuildContext ctx, OsmRouteInfo r) {
    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF4fc3f7)),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
            ],
          ),
        );

    return [
      Center(
        child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _routeColor(r), shape: BoxShape.circle),
            child: Icon(_routeIcon(r), color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                Text(
                  [r.typeLabel, if (r.network != null) r.networkLabel].join(' · '),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      if (r.description != null) ...[
        const SizedBox(height: 12),
        Text(r.description!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
      const SizedBox(height: 12),
      if (r.from != null || r.to != null)
        row(Icons.swap_horiz, '${r.from ?? '?'} → ${r.to ?? '?'}'),
      if (r.distance != null) row(Icons.straighten, '${r.distance} km'),
      if (r.operator != null) row(Icons.business, r.operator!),
      if (r.ref != null && r.name != null) row(Icons.tag, r.ref!),
      if (r.symbol != null) row(Icons.label_outline, r.symbol!),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (r.wikipedia != null)
            TextButton.icon(
              icon: const Icon(Icons.public, size: 18),
              label: const Text('Wikipedia'),
              onPressed: () {
                Navigator.pop(ctx);
                _openWikipedia(r.wikipedia!);
              },
            ),
          if (r.website != null)
            TextButton.icon(
              icon: const Icon(Icons.language, size: 18),
              label: const Text('Website'),
              onPressed: () {
                Navigator.pop(ctx);
                _openUrl(r.website!);
              },
            ),
          TextButton.icon(
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('OSM-Relation'),
            onPressed: () {
              Navigator.pop(ctx);
              _openUrl('https://www.openstreetmap.org/relation/${r.id}');
            },
          ),
        ],
      ),
    ];
  }

  Color _routeColor(OsmRouteInfo r) {
    if (r.colour != null) {
      final c = r.colour!.trim();
      if (c.startsWith('#') && (c.length == 7 || c.length == 4)) {
        try {
          final hex = c.length == 4
              ? '${c[1]}${c[1]}${c[2]}${c[2]}${c[3]}${c[3]}'
              : c.substring(1);
          return Color(int.parse('FF$hex', radix: 16));
        } catch (_) {}
      }
    }
    switch (r.routeType) {
      case 'bicycle':
      case 'mtb':
        return const Color(0xFF1E88E5);
      case 'hiking':
      case 'foot':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF757575);
    }
  }

  IconData _routeIcon(OsmRouteInfo r) {
    switch (r.routeType) {
      case 'bicycle':
        return Icons.pedal_bike;
      case 'mtb':
        return Icons.terrain;
      case 'hiking':
      case 'foot':
        return Icons.hiking;
      default:
        return Icons.route;
    }
  }

  Future<void> _refetchSights() async {
    if (_route == null || _loadingSights) return;
    setState(() {
      _sights = [];
      _loadingSights = true;
    });
    try {
      final sights = await SightsService.fetchAlongRoute(
        _routePoints,
        enabledTypes: _enabledSightTypes,
      );
      setState(() => _sights = sights);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Overpass-Fehler: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } finally {
      if (mounted) setState(() => _loadingSights = false);
    }
  }

  Future<void> _toggleSights() async {
    if (_sights.isNotEmpty) {
      setState(() => _sights = []);
      return;
    }
    if (_route == null || _loadingSights) return;
    setState(() => _loadingSights = true);
    try {
      final sights = await SightsService.fetchAlongRoute(
        _routePoints,
        enabledTypes: _enabledSightTypes,
      );
      setState(() => _sights = sights);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${sights.length} Sehenswürdigkeiten gefunden'),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Overpass-Fehler: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } finally {
      if (mounted) setState(() => _loadingSights = false);
    }
  }

  void _showSightInfo(OsmSight s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: _buildSightSheetChildren(ctx, s),
        ),
      ),
    );
  }

  List<Widget> _buildSightSheetChildren(BuildContext ctx, OsmSight s) {
    final imageUrl = s.imageUrl;
    return [
      Center(
        child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (imageUrl != null) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            loadingBuilder: (c, child, p) => p == null
                ? child
                : Container(
                    height: 180,
                    color: Colors.white10,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(color: Color(0xFF4fc3f7)),
                  ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: _sightColor(s.category), shape: BoxShape.circle),
            child: Icon(_sightIcon(s), color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                Text(s.subtypeLabel,
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      if (s.description != null) ...[
        const SizedBox(height: 12),
        Text(s.description!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
      const SizedBox(height: 12),
      ..._sightInfoRows(s),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (s.wikipedia != null)
            TextButton.icon(
              icon: const Icon(Icons.public, size: 18),
              label: const Text('Wikipedia'),
              onPressed: () {
                Navigator.pop(ctx);
                _openWikipedia(s.wikipedia!);
              },
            ),
          if (s.website != null)
            TextButton.icon(
              icon: const Icon(Icons.language, size: 18),
              label: const Text('Website'),
              onPressed: () {
                Navigator.pop(ctx);
                _openUrl(s.website!);
              },
            ),
          TextButton.icon(
            icon: const Icon(Icons.add_location_alt_outlined, size: 18),
            label: const Text('Als Waypoint'),
            onPressed: () {
              Navigator.pop(ctx);
              _addWaypointFromSight(s);
            },
          ),
        ],
      ),
    ];
  }

  List<Widget> _sightInfoRows(OsmSight s) {
    final rows = <Widget>[];
    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF4fc3f7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
            ],
          ),
        );

    if (s.openingHours != null) rows.add(row(Icons.schedule, s.openingHours!));
    if (s.fee != null || s.charge != null) {
      final parts = <String>[];
      if (s.fee == 'yes') parts.add('Eintritt');
      if (s.fee == 'no') parts.add('Kostenlos');
      if (s.charge != null) parts.add(s.charge!);
      rows.add(row(Icons.euro, parts.join(' · ')));
    }
    if (s.wheelchair != null) {
      const wcLabels = {'yes': 'Barrierefrei', 'limited': 'Teilweise barrierefrei', 'no': 'Nicht barrierefrei'};
      rows.add(row(Icons.accessible, wcLabels[s.wheelchair!] ?? s.wheelchair!));
    }
    if (s.address != null) rows.add(row(Icons.place, s.address!));
    if (s.phone != null) rows.add(row(Icons.phone, s.phone!));
    if (s.ele != null) rows.add(row(Icons.terrain, '${s.ele} m Höhe'));
    if (s.startDate != null) rows.add(row(Icons.history, 'Erbaut ${s.startDate}'));
    if (s.heritage != null) rows.add(row(Icons.museum, 'Denkmalschutz'));
    if (s.artist != null) rows.add(row(Icons.brush, 'Künstler: ${s.artist}'));
    if (s.artworkType != null) rows.add(row(Icons.palette, s.artworkType!));
    if (s.castleType != null) rows.add(row(Icons.castle, s.castleType!));
    if (s.material != null) rows.add(row(Icons.texture, s.material!));
    if (s.operator != null) rows.add(row(Icons.business, s.operator!));
    return rows;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openWikipedia(String wikiTag) async {
    // wikiTag format: "de:Article Name" or "en:Article Name"
    final parts = wikiTag.split(':');
    if (parts.length < 2) return;
    final lang = parts[0];
    final article = parts.sublist(1).join(':');
    final url = Uri.parse('https://$lang.wikipedia.org/wiki/${Uri.encodeComponent(article)}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _addWaypointFromSight(OsmSight s) {
    final p = LatLng(s.lat, s.lon);
    setState(() => _waypoints.add(p));
    _waypointNames[_wpKey(p)] = s.name ?? s.subtypeLabel;
    _recalculate();
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
    if (_roundtripMode) {
      if (_lastRoundtripRequest != null && _waypoints.isNotEmpty) {
        _calculateRoundtrip(_lastRoundtripRequest!);
      }
    } else if (_waypoints.length >= 2) {
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
    _lastRoundtripRequest = req;
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
      _sights = [];
      _stages = [];
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

  Future<void> _onMenuSelected(String value) async {
    switch (value) {
      case 'save':
        await _saveRoute();
        break;
      case 'load':
        final loaded = await Navigator.of(context).push<SavedRoute>(
          MaterialPageRoute(builder: (_) => const SavedRoutesScreen()),
        );
        if (loaded != null) await _loadSavedRoute(loaded);
        break;
      case 'settings':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
    }
  }

  Future<void> _saveRoute() async {
    if (_route == null) return;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(
          text: 'Route ${DateTime.now().day}.${DateTime.now().month}.',
        );
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          title: const Text('Route speichern', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Name der Route',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF4fc3f7)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF4fc3f7), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Speichern', style: TextStyle(color: Color(0xFF4fc3f7))),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;

    final saved = SavedRoute(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      profile: _profile,
      waypoints: _waypoints.map((w) => [w.longitude, w.latitude]).toList(),
      distanceKm: _route!.distance,
      durationSeconds: _route!.time.toInt(),
      ascent: _route!.ascent.round(),
      createdAt: DateTime.now(),
      isRoundtrip: _roundtripMode,
      rtDistanceKm: _roundtripMode ? _rtDistanceKm : null,
      rtDirection: _roundtripMode ? _rtDirection : null,
      pois: List.of(_pois),
    );
    await RouteStorage.save(saved);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('„$name" gespeichert')),
    );
  }

  Future<void> _loadSavedRoute(SavedRoute r) async {
    setState(() {
      _waypoints.clear();
      _waypoints.addAll(r.waypoints.map((w) => LatLng(w[1], w[0])));
      _profile = r.profile;
      _roundtripMode = r.isRoundtrip;
      if (r.rtDistanceKm != null) _rtDistanceKm = r.rtDistanceKm!;
      if (r.rtDirection != null) _rtDirection = r.rtDirection!;
      _anchorIndices.clear();
      _selectedWaypointIndex = null;
      _hoveredWaypointIndex = null;
      _pois.clear();
      _pois.addAll(r.pois);
    });
    for (final wp in _waypoints) {
      _resolveWaypointName(wp);
    }
    if (_waypoints.length >= 2) {
      await _calculateRoute();
    }
  }

  void _showWeather() {
    if (_route == null) return;
    final speed = BikeProfile.byId(_profile)?.avgSpeedKmh ?? 20;
    showWeatherSheet(
      context,
      coordinates: _route!.coordinates,
      avgSpeedKmh: speed.toDouble(),
    );
  }

  Future<void> _showStagesPlanner() async {
    if (_route == null) return;
    final result = await showStagesSheet(
      context,
      coordinates: _route!.coordinates,
      totalDistanceKm: _route!.distance,
    );
    if (result == null || !mounted) return;
    setState(() => _stages = result.stages);
  }

  List<Marker> _buildStageMarkers() {
    final markers = <Marker>[];
    for (final s in _stages) {
      // Don't mark the final arrival (same as end waypoint)
      if (s.index == _stages.length && _stages.length > 1) continue;
      markers.add(Marker(
        point: LatLng(s.lat, s.lon),
        width: 30,
        height: 30,
        alignment: Alignment.center,
        child: Tooltip(
          message: s.townName ?? 'Etappe ${s.index}: ${s.lengthKm.toStringAsFixed(0)} km',
          triggerMode: TooltipTriggerMode.tap,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFffb74d),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
            ),
            child: Center(
              child: Text(
                '${s.index}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ));
    }
    return markers;
  }

  Future<void> _showAccommodation() async {
    if (_waypoints.isEmpty) return;
    final last = _roundtripMode ? _waypoints.first : _waypoints.last;
    final key = _wpKey(last);
    final label = _waypointNames[key] ?? 'Zielpunkt';
    final a = await showAccommodationSheet(
      context,
      lat: last.latitude,
      lon: last.longitude,
      anchorLabel: label,
    );
    if (a == null || !mounted) return;
    final p = LatLng(a.lat, a.lon);
    _mapController.move(p, 15);
    setState(() {
      _waypoints.add(p);
      _waypointNames[_wpKey(p)] = a.name ?? a.typeLabel;
    });
    if (_roundtripMode) _exitRoundtripMode();
    _recalculate();
  }

  Future<void> _shareRoute() async {
    if (_waypoints.isEmpty) return;
    final shared = SharedRoute(
      waypoints: _waypoints.map((w) => [w.latitude, w.longitude]).toList(),
      profile: _profile,
      roundtrip: _roundtripMode,
      roundtripDistanceKm: _roundtripMode ? _rtDistanceKm : null,
      roundtripDirection: _roundtripMode ? _rtDirection : null,
    );
    final url = shared.toUrl(base: currentBaseUrl());
    updateShareParam(shared.encode());
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link in die Zwischenablage kopiert')),
    );
  }

  Future<void> _exportGpx() async {
    if (_route == null) return;

    try {
      final trackName = _roundtripMode
          ? 'Rundtour ${_rtDistanceKm}km'
          : 'Wegwiesel-Tour';
      final gpx = GpxBuilder.build(
        route: _route!,
        trackName: trackName,
        pois: _pois,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'wegwiesel-$_profile-$timestamp.gpx';

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
    _pois.clear();
    _sights = [];
    setState(() {
      _route = null;
      _routePoints = [];
      _highlightIndex = null;
    });
  }
}

class _PoiEditResult {
  final bool isDelete;
  final PoiCategory? category;
  final String? name;
  final String? note;

  const _PoiEditResult.delete()
      : isDelete = true,
        category = null,
        name = null,
        note = null;

  const _PoiEditResult.save({
    required this.category,
    required this.name,
    required this.note,
  }) : isDelete = false;
}
