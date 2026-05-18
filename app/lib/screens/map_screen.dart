import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/gpx_export.dart';
import '../services/gpx_import.dart';
import '../services/route_url_import.dart';
import '../widgets/url_import_dialog.dart';
import '../widgets/gpx_import_mode_dialog.dart';
import 'recording_screen.dart';
import 'recorded_rides_screen.dart';
import 'library_screen.dart';
import 'offline_maps_screen.dart';
import '../services/library_service.dart';
import '../services/wegwiesel_tile_cache_provider.dart';
import '../widgets/publish_route_dialog.dart';

import '../models/map_style.dart';
import '../models/nogo_area.dart';
import '../models/osm_sight.dart';
import '../models/profile.dart';
import '../models/route_result.dart';
import '../models/route_segment.dart';
import '../models/route_poi.dart';
import '../models/saved_route.dart';
import '../models/turn_hint.dart';
import 'package:garmin_connect/garmin_connect.dart';
import 'navigation_screen.dart';
import '../services/brouter_service.dart';
import '../services/garmin_share_service.dart';
import '../services/gpx_builder.dart';
import '../services/nogo_storage.dart';
import '../services/profile_speed_prefs.dart';
import '../services/hiking_prefs.dart';
import '../services/bikepacking_prefs.dart';
import '../services/ride_recorder.dart';
import '../services/ride_session_store.dart';
import '../services/ride_storage.dart';
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
import '../widgets/route_poi_search_sheet.dart';
import '../services/route_poi_search_service.dart';
import '../services/poi_image_resolver.dart';
import '../widgets/stages_sheet.dart';
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
  // Up-to-two alternative routes alongside the active one. Empty in
  // roundtrip mode (BRouter's roundtrip engine doesn't accept alternatives).
  List<_RouteAlternative> _alternativeRoutes = const [];
  _RouteAlternativeKind _activeRouteKind = _RouteAlternativeKind.primary;
  int _activeRouteVariantIdx = 0;
  bool _loading = false;
  int? _loadingAlternativeIdx;
  bool _loadingShortestCarRoute = false;
  bool _loadingAvoidMotorwaysCarRoute = false;
  int _routeRequestId = 0;
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
  bool _loadingPauseRecs = false;
  Set<String> _enabledSightTypes = allSightTypes;
  Set<String> _activeOverlays = {};
  double _overlayOpacity = 0.5;
  bool _routeInspectMode = false;
  bool _loadingRouteInfo = false;
  RoundtripRequest? _lastRoundtripRequest;
  List<Stage> _stages = [];
  List<NogoArea> _nogos = const [];
  bool _placingNogo = false;
  final Map<String, String> _waypointNames = {}; // key: "lat,lon" at 5 dp
  final Set<String> _waypointNamesInflight = {};
  bool _garminAvailable = false;

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
      final op = prefs.getDouble('overlay_opacity_v1');
      if (op != null && mounted) setState(() => _overlayOpacity = op.clamp(0.0, 1.0));
    });
    NogoStorage.load().then((v) {
      if (mounted) setState(() => _nogos = v);
    });
    ProfileSpeedPrefs.load();
    HikingPrefs.load();
    BikepackingPrefs.load();
    _recoverOrphanRide();
    GarminConnect.isAvailable().then((v) {
      if (mounted) setState(() => _garminAvailable = v);
    });
    _tryLoadSharedRoute();
  }

  /// If the last app session crashed mid-recording, an orphan session file
  /// is on disk. Convert it to a saved ride and tell the user. We skip the
  /// recovery if the recorder is somehow already running (hot-restart edge
  /// case during dev) so we don't snapshot a live session.
  Future<void> _recoverOrphanRide() async {
    if (RideRecorder.instance.isActive) return;
    if (!await RideSessionStore.hasOrphanSession()) return;
    final now = DateTime.now();
    final name =
        'Wiederhergestellte Fahrt ${_pad(now.day)}.${_pad(now.month)}. ${_pad(now.hour)}:${_pad(now.minute)}';
    final ride = await RideSessionStore.recoverAsRide(name);
    await RideSessionStore.clearSession();
    if (ride == null) return;
    await RideStorage.save(ride);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).rideRecoveredSnack(
            ride.distanceKm.toStringAsFixed(1),
          ),
        ),
        backgroundColor: const Color(0xFF6a4a28),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');

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
                      tileProvider: NetworkTileProvider(
                        cachingProvider: WegwieselTileCacheProvider.instance,
                      ),
                    ),
                    if (_mapStyle.labelsOverlay != null)
                      TileLayer(
                        urlTemplate: _mapStyle.labelsOverlay!,
                        maxZoom: _mapStyle.maxZoom.toDouble(),
                        userAgentPackageName: 'app.wegwiesel',
                      ),
                    for (final ov in routeOverlays.where((o) => _activeOverlays.contains(o.id)))
                      Opacity(
                        opacity: _overlayOpacity,
                        child: TileLayer(
                          urlTemplate: ov.urlTemplate,
                          maxZoom: 18,
                          userAgentPackageName: 'app.wegwiesel',
                        ),
                      ),
                    if (_nogos.isNotEmpty)
                      CircleLayer(
                        circles: [
                          for (final n in _nogos)
                            CircleMarker(
                              point: LatLng(n.lat, n.lon),
                              radius: n.radiusMeters.toDouble(),
                              useRadiusInMeter: true,
                              color: const Color(0xFFef5350).withValues(alpha: 0.18),
                              borderColor: const Color(0xFFef5350).withValues(alpha: 0.85),
                              borderStrokeWidth: 2,
                            ),
                        ],
                      ),
                    if (_roundtripMode &&
                        _anchorIndices.isNotEmpty &&
                        _waypoints.length >= 3 &&
                        _draggingWaypointIndex != null)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: [..._waypoints],
                            borderColor: const Color(0xFFffc107).withValues(alpha: 0.85),
                            borderStrokeWidth: 2.5,
                          ),
                        ],
                      ),
                    if (_alternativeRoutes.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          for (final alt in _alternativeRoutes)
                            Polyline(
                              points: alt.route.coordinates
                                  .map((c) => LatLng(c[1], c[0]))
                                  .toList(growable: false),
                              color: Colors.grey.withValues(alpha: 0.65),
                              strokeWidth: 6,
                            ),
                        ],
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
                              color: const Color(0xFF6a4a28),
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
                                color: Colors.black87,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF6a4a28), width: 2),
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
                                border: Border.all(color: Colors.black87, width: 3),
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
                                color: const Color(0xFF6a4a28).withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black87, width: 2),
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
              if (_showAlternativesBar)
                _buildAlternativesBar(),
              if (_route != null)
                StatsBar(
                  route: _route!,
                  actions: _buildStatsActions(context),
                  userSpeedKmh: ProfileSpeedPrefs.speedFor(_profile),
                  highlightAscent: _profile == 'hiking-beta' ||
                      _profile == 'wegwiesel-running',
                  showSacBadge: _profile == 'hiking-beta',
                ),
              if (_route != null && _showElevation)
                ElevationChart(
                  coordinates: _route!.coordinates,
                  segments: _route!.segments,
                  waypoints: [
                    for (final wp in _waypoints) [wp.latitude, wp.longitude],
                  ],
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
                    color: const Color(0xFFf5e9d8).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _modeChip(AppLocalizations.of(context).modeAtoB, false),
                      _modeChip(AppLocalizations.of(context).modeRoundtrip, true),
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
                        color: const Color(0xFFf5e9d8).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _profileLabel(context),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF6a4a28), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_more, color: Color(0xFF6a4a28), size: 18),
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
                      color: const Color(0xFFf5e9d8).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.layers, color: Color(0xFF6a4a28), size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                if (_roundtripMode)
                  GestureDetector(
                    onTap: () => setState(() => _showControls = !_showControls),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf5e9d8).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _showControls ? Icons.close : Icons.tune,
                        color: const Color(0xFF6a4a28),
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
                  color: const Color(0xFFf5e9d8).withValues(alpha: 0.95),
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
                child: CircularProgressIndicator(color: Color(0xFF6a4a28))),

          // Action buttons
          Positioned(
            right: 12,
            bottom: (_route != null
                    ? (_showElevation
                        ? 254 + (_route!.segments.isNotEmpty ? 90 : 0)
                        : 94)
                    : 0) +
                (_showAlternativesBar ? 56 : 0) +
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

          // Left action column — mirrors the right column's bottom offset so
          // the menu sits at the same height as the trash button (above the
          // stats bar) and route actions sit visibly stacked above it.
          Positioned(
            left: 12,
            bottom: (_route != null
                    ? (_showElevation
                        ? 254 + (_route!.segments.isNotEmpty ? 90 : 0)
                        : 94)
                    : 0) +
                (_showAlternativesBar ? 56 : 0) +
                bottomPadding +
                12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_route != null) ...[
                  _fab(Icons.share, _shareRoute),
                  const SizedBox(height: 8),
                  _fab(Icons.file_download, _exportGpx),
                  const SizedBox(height: 8),
                  if (_activeOverlays.isNotEmpty) ...[
                    _fab(
                      _loadingRouteInfo
                          ? Icons.hourglass_top
                          : (_routeInspectMode ? Icons.close : Icons.info_outline),
                      () {
                        setState(() => _routeInspectMode = !_routeInspectMode);
                        if (_routeInspectMode) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(AppLocalizations.of(context).tapRouteForInfo),
                            duration: const Duration(seconds: 3),
                          ));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Material(
                    color: const Color(0xFFe8d5b8),
                    shape: const CircleBorder(),
                    elevation: 6,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Color(0xFF6a4a28), size: 20),
                      iconSize: 20,
                      color: const Color(0xFFf5e9d8),
                      padding: EdgeInsets.zero,
                      tooltip: '',
                      onSelected: _onMenuSelected,
                      itemBuilder: (ctx) {
                        final l = AppLocalizations.of(ctx);
                        return [
                          PopupMenuItem(
                            value: 'navigate',
                            enabled: _route != null,
                            child: Row(children: [
                              const Icon(Icons.navigation, color: Color(0xFF6a4a28), size: 20),
                              const SizedBox(width: 12),
                              Text(l.menuStartNavigation, style: const TextStyle(color: Colors.black87)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'save',
                            enabled: _route != null,
                            child: Row(children: [
                              const Icon(Icons.bookmark_add_outlined, color: Color(0xFF6a4a28), size: 20),
                              const SizedBox(width: 12),
                              Text(l.menuSaveRoute, style: const TextStyle(color: Colors.black87)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'load',
                            child: Row(children: [
                              const Icon(Icons.bookmarks_outlined, color: Color(0xFF6a4a28), size: 20),
                              const SizedBox(width: 12),
                              Text(l.menuSavedRoutes, style: const TextStyle(color: Colors.black87)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'import_gpx',
                            child: Row(children: [
                              const Icon(Icons.upload_file_outlined, color: Color(0xFF6a4a28), size: 20),
                              const SizedBox(width: 12),
                              Text(l.menuImportGpx, style: const TextStyle(color: Colors.black87)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'import_url',
                            child: Row(children: [
                              const Icon(Icons.cloud_download_outlined, color: Color(0xFF6a4a28), size: 20),
                              const SizedBox(width: 12),
                              Text(l.menuImportUrl, style: const TextStyle(color: Colors.black87)),
                            ]),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'recording',
                            child: Row(children: [
                              const Icon(Icons.fiber_manual_record, color: Color(0xFFc62828), size: 20),
                              const SizedBox(width: 12),
                              Text(l.menuRecording, style: const TextStyle(color: Colors.black87)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'recorded',
                            child: Row(children: [
                              const Icon(Icons.history, color: Color(0xFF6a4a28), size: 20),
                              const SizedBox(width: 12),
                              Text(l.menuRecordedRides, style: const TextStyle(color: Colors.black87)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'library',
                            child: Row(children: [
                              const Icon(Icons.travel_explore, color: Color(0xFF6a4a28), size: 20),
                              const SizedBox(width: 12),
                              Text(l.menuLibrary, style: const TextStyle(color: Colors.black87)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'publish',
                            enabled: _route != null,
                            child: Row(children: [
                              const Icon(Icons.public, color: Color(0xFF6a4a28), size: 20),
                              const SizedBox(width: 12),
                              Text(l.menuPublishRoute, style: const TextStyle(color: Colors.black87)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'offline_maps',
                            child: Row(children: [
                              const Icon(Icons.cloud_off_outlined, color: Color(0xFF6a4a28), size: 20),
                              const SizedBox(width: 12),
                              Text(l.menuOfflineMaps, style: const TextStyle(color: Colors.black87)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'nogos',
                            child: Row(children: [
                              const Icon(Icons.block, color: Color(0xFF6a4a28), size: 20),
                              const SizedBox(width: 12),
                              Text(l.menuNogos, style: const TextStyle(color: Colors.black87)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'poi_search',
                            enabled: _route != null,
                            child: Row(children: [
                              const Icon(Icons.search, color: Color(0xFF6a4a28), size: 20),
                              const SizedBox(width: 12),
                              Text(l.menuSearchAlongRoute, style: const TextStyle(color: Colors.black87)),
                            ]),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'settings',
                            child: Row(children: [
                              const Icon(Icons.settings_outlined, color: Color(0xFF6a4a28), size: 20),
                              const SizedBox(width: 12),
                              Text(l.menuSettings, style: const TextStyle(color: Colors.black87)),
                            ]),
                          ),
                        ];
                      },
                    ),
                  ),
                ),
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
      final l = AppLocalizations.of(context);
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError(l.gpsPermissionDenied);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showError(l.gpsPermanentlyDenied);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final latLng = LatLng(position.latitude, position.longitude);

      setState(() => _currentPosition = latLng);
      _mapController.move(latLng, 14);
    } catch (e) {
      if (mounted) _showError(AppLocalizations.of(context).gpsFetchFailed(e.toString()));
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

  String _profileLabel(BuildContext context) {
    final p = BikeProfile.byId(_profile);
    if (p == null) return _profile;
    return p.localizedName(AppLocalizations.of(context));
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
      backgroundColor: const Color(0xFFf5e9d8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final l = AppLocalizations.of(ctx);
          final vizEntries = [
            ['surface', l.surfaceTitle, '🛣️'],
            ['gradient', l.mapVizGradient, '📈'],
          ];
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Text(
                  l.mapStyleTitle,
                  style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              ...mapStyles.map((style) => ListTile(
                dense: true,
                leading: Text(style.icon, style: const TextStyle(fontSize: 18)),
                title: Text(style.localizedName(l), style: const TextStyle(color: Colors.black87)),
                selected: style.id == _mapStyle.id,
                selectedTileColor: const Color(0xFF6a4a28).withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  setState(() => _mapStyle = style);
                  Navigator.pop(ctx);
                },
              )),
              const Divider(color: Colors.black26, height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text(
                  l.mapOverlayRoutes,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...routeOverlays.map((ov) => SwitchListTile(
                dense: true,
                secondary: Text(ov.icon, style: const TextStyle(fontSize: 18)),
                title: Text(ov.localizedName(l), style: const TextStyle(color: Colors.black87)),
                value: _activeOverlays.contains(ov.id),
                activeThumbColor: const Color(0xFF6a4a28),
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
              if (_activeOverlays.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.opacity, color: Colors.black54, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${(_overlayOpacity * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _overlayOpacity,
                          min: 0.1,
                          max: 1.0,
                          divisions: 18,
                          activeColor: const Color(0xFF6a4a28),
                          inactiveColor: Colors.black26,
                          onChanged: (v) {
                            setSheetState(() => _overlayOpacity = v);
                            setState(() {});
                          },
                          onChangeEnd: (v) async {
                            final p = await SharedPreferences.getInstance();
                            await p.setDouble('overlay_opacity_v1', v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(color: Colors.black26, height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text(
                  l.mapRouteVizTitle,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              for (final entry in vizEntries)
                ListTile(
                  dense: true,
                  leading: Text(entry[2], style: const TextStyle(fontSize: 18)),
                  title: Text(entry[1], style: const TextStyle(color: Colors.black87)),
                  selected: _routeVizMode == entry[0],
                  selectedTileColor: const Color(0xFF6a4a28).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    setSheetState(() => _routeVizMode = entry[0]);
                    setState(() {});
                    SharedPreferences.getInstance()
                        .then((p) => p.setString('route_viz_mode_v1', entry[0]));
                  },
                ),
            ],
          );
        },
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
        color = const Color(0xFF6a4a28);
      }

      double size;
      if (isAnchor) {
        size = isDragging ? 32.0 : (isHovered ? 28.0 : 24.0);
      } else if (isStart || (isEnd && !_roundtripMode)) {
        size = isDragging ? 36.0 : (isHovered ? 32.0 : 28.0);
      } else {
        size = isDragging ? 28.0 : (isHovered ? 24.0 : 20.0);
      }

      String label;
      if (_roundtripMode && _anchorIndices.isNotEmpty) {
        // A/B/C/D style labels for the four corners of the roundtrip shape.
        label = i < 26 ? String.fromCharCode('A'.codeUnitAt(0) + i) : '';
      } else {
        label = isStart ? 'A' : (isEnd && !_roundtripMode ? 'B' : '');
      }
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
                        border: Border.all(color: Colors.black87, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.delete, color: Colors.black87, size: 16),
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
                        border: Border.all(color: Colors.black87, width: 1.5),
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
                    border: Border.all(color: Colors.black87, width: isDragging ? 3 : (isHovered ? 2.5 : isAnchor ? 1.5 : 2)),
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
                              color: Colors.black87,
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
          color: active ? const Color(0xFF6a4a28) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFf5e9d8) : Colors.black54,
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
      backgroundColor: const Color(0xFFe8d5b8),
      foregroundColor: const Color(0xFF6a4a28),
      onPressed: onTap,
      child: Icon(icon),
    );
  }

  List<StatsAction> _buildStatsActions(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isOnFoot = _profile == 'hiking-beta' || _profile == 'wegwiesel-running';
    final actions = <StatsAction>[
      StatsAction(
        icon: _sights.isEmpty ? Icons.explore_outlined : Icons.explore_off_outlined,
        label: l.actionSights,
        loading: _loadingSights,
        active: _sights.isNotEmpty,
        onTap: _toggleSights,
      ),
      StatsAction(
        icon: Icons.tune,
        label: l.actionFilter,
        onTap: () => _showSightFilterSheet(context),
      ),
      StatsAction(
        icon: Icons.cloud_outlined,
        label: l.actionWeather,
        onTap: _showWeather,
      ),
      StatsAction(
        icon: Icons.bed_outlined,
        label: l.actionAccommodation,
        onTap: _showAccommodation,
      ),
      StatsAction(
        icon: _stages.isEmpty ? Icons.date_range : Icons.event_available,
        label: l.actionStages,
        active: _stages.isNotEmpty,
        onTap: _showStagesPlanner,
      ),
      if (isOnFoot)
        StatsAction(
          icon: Icons.deck_outlined,
          label: l.actionPauseRecommendations,
          loading: _loadingPauseRecs,
          onTap: _addPauseRecommendations,
        ),
    ];
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

    if (_placingNogo) {
      _addNogoAt(latLng);
      return;
    }

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
      backgroundColor: const Color(0xFFf5e9d8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.poiAddTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
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
                            child: Icon(cat.icon, color: Colors.black87, size: 28),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 72,
                            child: Text(cat.localizedLabel(l),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black54, fontSize: 11)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
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

  /// Opens the POI photo in a full-screen black-backdrop viewer with
  /// pinch-to-zoom. Tap anywhere closes the view.
  Future<void> _showPoiPhotoFullscreen(String url, String? name) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      url,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
              if (name != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 32,
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                    ),
                  ),
                ),
              Positioned(
                top: 36,
                right: 12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editPoi(RoutePoi poi) async {
    final nameCtrl = TextEditingController(text: poi.name ?? '');
    final noteCtrl = TextEditingController(text: poi.note ?? '');
    PoiCategory selectedCat = poi.category;

    final result = await showDialog<_PoiEditResult>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFFf5e9d8),
            title: Row(children: [
              Icon(selectedCat.icon, color: selectedCat.color),
              const SizedBox(width: 8),
              Text(l.poiEditTitle, style: const TextStyle(color: Colors.black87)),
            ]),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (poi.imageUrl != null) ...[
                    GestureDetector(
                      onTap: () => _showPoiPhotoFullscreen(poi.imageUrl!, poi.name),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: double.infinity,
                          height: 160,
                          child: Image.network(
                            poi.imageUrl!,
                            fit: BoxFit.cover,
                            // Wikimedia kann mit 404/Redirect-Loop antworten
                            // — den Fehler verschlucken statt einen
                            // hässlichen ImageException-Block zeigen.
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            loadingBuilder: (ctx, child, progress) =>
                                progress == null
                                    ? child
                                    : Container(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF6a4a28),
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(l.poiCategoryLabel,
                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
                            Icon(cat.icon, color: selected ? Colors.black87 : cat.color, size: 14),
                            const SizedBox(width: 4),
                            Text(cat.localizedLabel(l),
                                style: TextStyle(
                                    color: selected ? Colors.black87 : cat.color, fontSize: 11)),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: l.poiNameLabel,
                      labelStyle: const TextStyle(color: Colors.black54),
                      enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6a4a28))),
                      focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6a4a28), width: 2)),
                    ),
                  ),
                  TextField(
                    controller: noteCtrl,
                    style: const TextStyle(color: Colors.black87),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l.poiNoteLabel,
                      labelStyle: const TextStyle(color: Colors.black54),
                      enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6a4a28))),
                      focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6a4a28), width: 2)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, const _PoiEditResult.delete()),
                child: Text(l.commonDelete, style: const TextStyle(color: Colors.redAccent)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.commonCancel),
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
                child: Text(l.commonSave, style: const TextStyle(color: Color(0xFF6a4a28))),
              ),
            ],
          ),
        );
      },
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
              border: Border.all(color: Colors.black87, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
            ),
            child: Icon(p.category.icon, color: Colors.black87, size: 18),
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _buildSightMarkers() {
    final l = AppLocalizations.of(context);
    return _sights.map((s) {
      final subLabel = s.localizedSubtype(l);
      return Marker(
        point: LatLng(s.lat, s.lon),
        width: 32,
        height: 32,
        child: Tooltip(
          message: s.name != null ? '${s.name}\n$subLabel' : subLabel,
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
                  border: Border.all(color: Colors.black87, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                ),
                child: Icon(_sightIcon(s), color: Colors.black87, size: 16),
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
      backgroundColor: const Color(0xFFf5e9d8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final l = AppLocalizations.of(ctx);
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
              for (final sub in sightTypes[cat]!) {
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
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(l.poiTypesTitle,
                    style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
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
                            sightCategoryLabel(l, cat),
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final allOn = sightTypes[cat]!.every((s) => _enabledSightTypes.contains('$cat:$s'));
                            toggleCategory(cat, !allOn);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6a4a28),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 28),
                          ),
                          child: Text(
                            sightTypes[cat]!.every((s) => _enabledSightTypes.contains('$cat:$s'))
                                ? l.filterSelectNone : l.filterSelectAll,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final sub in sightTypes[cat]!)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _enabledSightTypes.contains('$cat:$sub'),
                      onChanged: (v) => toggle('$cat:$sub', v),
                      activeColor: const Color(0xFF6a4a28),
                      checkColor: Colors.black,
                      title: Text(sightSubtypeLabel(l, sub), style: const TextStyle(color: Colors.black87, fontSize: 13)),
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
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      if (routes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.noRouteHere),
          duration: const Duration(seconds: 2),
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
          content: Text(AppLocalizations.of(context).overpassError(e.toString())),
          backgroundColor: Colors.red.shade700,
        ));
      }
    }
  }

  void _showRoutesListSheet(List<OsmRouteInfo> routes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFf5e9d8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return DraggableScrollableSheet(
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
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${routes.length} × ${l.actionInfo}',
                style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              for (final r in routes)
                ListTile(
                  dense: true,
                  leading: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: _routeColor(r), shape: BoxShape.circle),
                    child: Icon(_routeIcon(r), color: Colors.black87, size: 18),
                  ),
                  title: Text(r.localizedDisplayName(l), style: const TextStyle(color: Colors.black87, fontSize: 14)),
                  subtitle: Text(
                    [r.localizedType(l), if (r.network != null) r.localizedNetwork(l)].join(' · '),
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRouteInfoSheet(r);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showRouteInfoSheet(OsmRouteInfo r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFf5e9d8),
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
    final l = AppLocalizations.of(ctx);
    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF6a4a28)),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 13))),
            ],
          ),
        );

    return [
      Center(
        child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _routeColor(r), shape: BoxShape.circle),
            child: Icon(_routeIcon(r), color: Colors.black87, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.localizedDisplayName(l),
                  style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w600)),
                Text(
                  [r.localizedType(l), if (r.network != null) r.localizedNetwork(l)].join(' · '),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      if (r.description != null) ...[
        const SizedBox(height: 12),
        Text(r.description!, style: const TextStyle(color: Colors.black54, fontSize: 13)),
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
              label: Text(l.sightWikipedia),
              onPressed: () {
                Navigator.pop(ctx);
                _openWikipedia(r.wikipedia!);
              },
            ),
          if (r.website != null)
            TextButton.icon(
              icon: const Icon(Icons.language, size: 18),
              label: Text(l.sightWebsite),
              onPressed: () {
                Navigator.pop(ctx);
                _openUrl(r.website!);
              },
            ),
          TextButton.icon(
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(l.sightOsmRelation),
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
          content: Text(AppLocalizations.of(context).overpassError(e.toString())),
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
          content: Text(AppLocalizations.of(context).infoPoiCount(sights.length)),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).overpassError(e.toString())),
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
      backgroundColor: const Color(0xFFf5e9d8),
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
    final l = AppLocalizations.of(ctx);
    final imageUrl = s.imageUrl;
    return [
      Center(
        child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: Colors.black26,
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
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(color: Color(0xFF6a4a28)),
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
            child: Icon(_sightIcon(s), color: Colors.black87, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.displayName(l),
                  style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w600)),
                Text(s.localizedSubtype(l),
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      if (s.description != null) ...[
        const SizedBox(height: 12),
        Text(s.description!, style: const TextStyle(color: Colors.black54, fontSize: 13)),
      ],
      const SizedBox(height: 12),
      ..._sightInfoRows(l, s),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (s.wikipedia != null)
            TextButton.icon(
              icon: const Icon(Icons.public, size: 18),
              label: Text(l.sightWikipedia),
              onPressed: () {
                Navigator.pop(ctx);
                _openWikipedia(s.wikipedia!);
              },
            ),
          if (s.website != null)
            TextButton.icon(
              icon: const Icon(Icons.language, size: 18),
              label: Text(l.sightWebsite),
              onPressed: () {
                Navigator.pop(ctx);
                _openUrl(s.website!);
              },
            ),
          TextButton.icon(
            icon: const Icon(Icons.add_location_alt_outlined, size: 18),
            label: Text(l.sightAsWaypoint),
            onPressed: () {
              Navigator.pop(ctx);
              _addWaypointFromSight(s);
            },
          ),
        ],
      ),
    ];
  }

  List<Widget> _sightInfoRows(AppLocalizations l, OsmSight s) {
    final rows = <Widget>[];
    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF6a4a28)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ),
            ],
          ),
        );

    if (s.openingHours != null) rows.add(row(Icons.schedule, s.openingHours!));
    if (s.fee != null || s.charge != null) {
      final parts = <String>[];
      if (s.fee == 'yes') parts.add(l.sightFeeYes);
      if (s.fee == 'no') parts.add(l.sightFeeNo);
      if (s.charge != null) parts.add(s.charge!);
      rows.add(row(Icons.euro, parts.join(' · ')));
    }
    if (s.wheelchair != null) {
      String wcLabel(String v) {
        switch (v) {
          case 'yes':
            return l.sightAccessibleYes;
          case 'limited':
            return l.sightAccessibleLimited;
          case 'no':
            return l.sightAccessibleNo;
          default:
            return v;
        }
      }
      rows.add(row(Icons.accessible, wcLabel(s.wheelchair!)));
    }
    if (s.address != null) rows.add(row(Icons.place, s.address!));
    if (s.phone != null) rows.add(row(Icons.phone, s.phone!));
    if (s.ele != null) rows.add(row(Icons.terrain, '${s.ele} ${l.commonM}'));
    if (s.startDate != null) rows.add(row(Icons.history, l.sightBuilt(s.startDate!)));
    if (s.heritage != null) rows.add(row(Icons.museum, l.sightHeritage));
    if (s.artist != null) rows.add(row(Icons.brush, l.sightArtist(s.artist!)));
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
    _waypointNames[_wpKey(p)] = s.name ?? s.localizedSubtype(AppLocalizations.of(context));
    _recalculate();
  }

  void _finishDrag() {
    final idx = _draggingWaypointIndex;
    setState(() => _draggingWaypointIndex = null);
    if (idx != null) {
      // Dragging an A/B/C/D anchor keeps roundtrip mode alive so the user can
      // keep tweaking the quadrilateral. Dragging any other waypoint
      // (start-only scenarios) falls back to the previous behaviour.
      final wasAnchor = _anchorIndices.contains(idx) || idx == 0;
      if (_roundtripMode && !wasAnchor) _exitRoundtripMode();
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
    setState(() {
      _profile = profile;
      // Hiking has a much smaller realistic distance range than cycling.
      // Without this clamp, switching from "fastbike 100 km roundtrip" to
      // hiking would send a 100 km value into BRouter even though the slider
      // visually maxes out at 50 km.
      // Hiking/running operate on a much smaller scale than cycling.
      // A 100 km value carried over from "fastbike" would silently be sent
      // to BRouter even though the slider's max is 50 km — clamp + reset
      // to a typical day-tour length so the user starts in a sensible
      // place when they switch profile.
      if ((profile == 'hiking-beta' || profile == 'wegwiesel-running') &&
          _rtDistanceKm > 50) {
        _rtDistanceKm = profile == 'hiking-beta' ? 8 : 5;
      }
    });
    if (_roundtripMode) {
      if (_lastRoundtripRequest != null && _waypoints.isNotEmpty) {
        _calculateRoundtrip(_lastRoundtripRequest!);
      }
    } else if (_waypoints.length >= 2) {
      _calculateRoute();
    }
  }

  bool get _showAlternativesBar => _route != null && !_roundtripMode;

  Future<void> _calculateRoute() async {
    if (_loading || _waypoints.length < 2) return;
    final requestId = ++_routeRequestId;
    setState(() {
      _loading = true;
      _loadingAlternativeIdx = null;
      _loadingShortestCarRoute = false;
      _loadingAvoidMotorwaysCarRoute = false;
    });

    try {
      final pts = _waypoints.map((w) => [w.longitude, w.latitude]).toList();
      final profile = _profile;
      final nogos = List<NogoArea>.from(_nogos);
      // In roundtrip mode with via-points, close the loop back to start
      if (_roundtripMode && pts.length >= 2) {
        pts.add(pts.first);
      }
      if (_roundtripMode) {
        final result = await BRouterService.calculateRoute(
          waypoints: pts,
          profile: profile,
          nogos: nogos,
        );
        if (!mounted || requestId != _routeRequestId) return;
        _displayRoute(result, alternatives: const []);
      } else {
        final result = await BRouterService.calculateRoute(
          waypoints: pts,
          profile: profile,
          nogos: nogos,
        );
        if (!mounted || requestId != _routeRequestId) return;
        _displayRoute(result, alternatives: const []);
        unawaited(_loadRouteAlternatives(
          requestId: requestId,
          waypoints: pts,
          profile: profile,
          nogos: nogos,
        ));
      }
    } catch (e) {
      if (mounted && requestId == _routeRequestId) {
        _showError(AppLocalizations.of(context).routingFailed(e.toString()));
      }
    } finally {
      if (mounted && requestId == _routeRequestId) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadRouteAlternatives({
    required int requestId,
    required List<List<double>> waypoints,
    required String profile,
    required List<NogoArea> nogos,
  }) async {
    for (final idx in const [1, 2]) {
      if (!mounted || requestId != _routeRequestId) return;
      setState(() {
        _loadingAlternativeIdx = idx;
        _loadingShortestCarRoute = false;
        _loadingAvoidMotorwaysCarRoute = false;
      });
      try {
        final alt = await BRouterService.calculateRoute(
          waypoints: waypoints,
          profile: profile,
          alternativeIdx: idx,
          nogos: nogos,
        );
        if (!mounted || requestId != _routeRequestId) return;
        _appendAlternativeRoute(_RouteAlternative.variant(alt, idx));
      } catch (_) {
        // Alternatives are optional; keep the already displayed primary route.
      }
    }
    if (profile == 'car' || profile == 'car-trailer') {
      if (!mounted || requestId != _routeRequestId) return;
      setState(() {
        _loadingAlternativeIdx = null;
        _loadingShortestCarRoute = true;
        _loadingAvoidMotorwaysCarRoute = false;
      });
      try {
        final shortest = await BRouterService.calculateRoute(
          waypoints: waypoints,
          profile: profile,
          shortestCarRoute: true,
          nogos: nogos,
        );
        if (!mounted || requestId != _routeRequestId) return;
        _appendAlternativeRoute(_RouteAlternative.shortest(shortest));
      } catch (_) {
        // The shortest car route is optional; keep the available routes.
      }
      if (!mounted || requestId != _routeRequestId) return;
      setState(() {
        _loadingShortestCarRoute = false;
        _loadingAvoidMotorwaysCarRoute = true;
      });
      try {
        final avoidMotorways = await BRouterService.calculateRoute(
          waypoints: waypoints,
          profile: profile,
          avoidMotorwaysCarRoute: true,
          nogos: nogos,
        );
        if (!mounted || requestId != _routeRequestId) return;
        _appendAlternativeRoute(_RouteAlternative.avoidMotorways(avoidMotorways));
      } catch (_) {
        // Avoid-motorway car routing is optional; keep the available routes.
      }
    }
    if (mounted && requestId == _routeRequestId) {
      setState(() {
        _loadingAlternativeIdx = null;
        _loadingShortestCarRoute = false;
        _loadingAvoidMotorwaysCarRoute = false;
      });
    }
  }

  void _appendAlternativeRoute(_RouteAlternative alternative) {
    final existing = [
      _route,
      ..._alternativeRoutes.map((alt) => alt.route),
    ].whereType<RouteResult>();
    final duplicate = existing.any((r) =>
        r.distance > 0 &&
        ((alternative.route.distance - r.distance).abs() / r.distance) < 0.01);
    if (duplicate) return;
    setState(() {
      _alternativeRoutes = [..._alternativeRoutes, alternative];
    });
  }

  Future<void> _calculateRoundtrip(RoundtripRequest req) async {
    if (_loading || _waypoints.isEmpty) return;
    ++_routeRequestId;
    _lastRoundtripRequest = req;
    setState(() {
      _loading = true;
      _loadingAlternativeIdx = null;
      _loadingShortestCarRoute = false;
      _loadingAvoidMotorwaysCarRoute = false;
    });

    try {
      final start = _waypoints.first;
      final RouteResult result;
      if (req.useTime) {
        final speed = ProfileSpeedPrefs.speedFor(_profile);
        result = await BRouterService.calculateRoundtripByTime(
          start: [start.longitude, start.latitude],
          profile: _profile,
          timeMinutes: req.timeMinutes,
          avgSpeedKmh: speed,
          direction: _rtDirection,
          nogos: _nogos,
        );
      } else {
        result = await BRouterService.calculateRoundtrip(
          start: [start.longitude, start.latitude],
          profile: _profile,
          distanceKm: req.distanceKm,
          direction: _rtDirection,
          nogos: _nogos,
        );
      }
      _displayRoute(result);
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      final msg = e.toString();
      final offTargetMatch = RegExp(r'roundtrip_off_target:([\d.]+)').firstMatch(msg);
      if (offTargetMatch != null) {
        _showError(l.roundtripOffTarget(offTargetMatch.group(1)!));
      } else {
        _showError(l.roundtripFailed(msg));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildAlternativesBar() {
    final l = AppLocalizations.of(context);
    final speed = ProfileSpeedPrefs.speedFor(_profile);
    return Container(
      color: const Color(0xFFf5e9d8),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _altChip(0, _route!, _activeRouteLabel(l), true, speed),
            for (int i = 0; i < _alternativeRoutes.length; i++) ...[
              const SizedBox(width: 8),
              _altChip(
                i + 1,
                _alternativeRoutes[i].route,
                _alternativeRoutes[i].label(l),
                false,
                speed,
              ),
            ],
            if (_loadingAlternativeIdx != null) ...[
              const SizedBox(width: 8),
              _altLoadingChip(l.altRouteVariant(_loadingAlternativeIdx!), l),
            ],
            if (_loadingShortestCarRoute) ...[
              const SizedBox(width: 8),
              _altLoadingChip(l.altRouteShortest, l),
            ],
            if (_loadingAvoidMotorwaysCarRoute) ...[
              const SizedBox(width: 8),
              _altLoadingChip(l.altRouteAvoidMotorways, l),
            ],
          ],
        ),
      ),
    );
  }

  String _activeRouteLabel(AppLocalizations l) {
    return _RouteAlternative._(
      _route!,
      _activeRouteKind,
      _activeRouteVariantIdx,
    ).label(l);
  }

  Widget _altChip(
    int idx,
    RouteResult r,
    String label,
    bool active,
    int userSpeedKmh,
  ) {
    final km = r.distance.toStringAsFixed(r.distance < 100 ? 1 : 0);
    final mins = ((r.distance / userSpeedKmh) * 60).round();
    final timeStr = mins < 60
        ? '$mins min'
        : '${(mins / 60).floor()}h ${(mins % 60).toString().padLeft(2, '0')}';
    final bg = active ? const Color(0xFF6a4a28) : const Color(0xFFd8c2a4);
    final fg = active ? Colors.white : Colors.black87;
    final subFg = active ? Colors.white.withValues(alpha: 0.86) : Colors.black87;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: active ? null : () => _activateAlternative(idx),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  )),
              Text('$km km · $timeStr',
                  style: TextStyle(color: subFg, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _altLoadingChip(String label, AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFeadcc8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFc9aa80)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFF6a4a28).withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                l.altRouteCalculating,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _activateAlternative(int idx) {
    if (idx <= 0 || idx > _alternativeRoutes.length) return;
    final selected = _alternativeRoutes[idx - 1];
    final newPrimary = selected.route;
    final newAlts = <_RouteAlternative>[
      _RouteAlternative._(_route!, _activeRouteKind, _activeRouteVariantIdx),
      ..._alternativeRoutes.sublist(0, idx - 1),
      ..._alternativeRoutes.sublist(idx),
    ];
    setState(() {
      _route = newPrimary;
      _routePoints =
          newPrimary.coordinates.map((c) => LatLng(c[1], c[0])).toList();
      _activeRouteKind = selected.kind;
      _activeRouteVariantIdx = selected.variantIdx;
      _alternativeRoutes = newAlts;
      _loadingAlternativeIdx = null;
      _loadingShortestCarRoute = false;
      _loadingAvoidMotorwaysCarRoute = false;
      _highlightIndex = null;
    });
  }

  void _displayRoute(RouteResult result,
      {List<_RouteAlternative> alternatives = const []}) {
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
      _activeRouteKind = _RouteAlternativeKind.primary;
      _activeRouteVariantIdx = 0;
      _alternativeRoutes = alternatives;
      _loadingAlternativeIdx = null;
      _loadingShortestCarRoute = false;
      _loadingAvoidMotorwaysCarRoute = false;
      _showElevation = true;
      _highlightIndex = null;
      _sights = [];
      _stages = [];
    });

    // Regenerate anchors on every roundtrip display, not only on the first
    // run. Otherwise "Andere Variante" / direction-change would update the
    // route geometry but leave the A/B/C/D markers pinned to the previous
    // route's curve. _generateAnchors() preserves _waypoints.first (the
    // start) and replaces everything else, so this is safe to call after a
    // prior roundtrip has already populated anchors.
    if (_roundtripMode && _waypoints.isNotEmpty && points.length > 2) {
      _generateAnchors();
    }
  }

  void _generateAnchors() {
    final start = _waypoints.first;
    _anchorIndices.clear();

    if (_routePoints.length < 4) {
      setState(() {});
      return;
    }
    final cum = List<double>.filled(_routePoints.length, 0);
    for (int i = 1; i < _routePoints.length; i++) {
      cum[i] = cum[i - 1] + _latLngDist(_routePoints[i - 1], _routePoints[i]);
    }
    final total = cum.last;
    if (total <= 0) {
      setState(() {});
      return;
    }

    // Distance comes from _latLngDist in "degrees × 111" units. Approximate
    // ~111 km per degree latitude is fine at this granularity.
    final distanceKm = total * 111;
    // Minimum three anchors, plus one additional for every whole 10 km.
    final nVias = max(3, 3 + (distanceKm / 10).floor());

    LatLng atFraction(double f) {
      final target = total * f;
      int lo = 0, hi = cum.length - 1;
      while (lo < hi) {
        final mid = (lo + hi) ~/ 2;
        if (cum[mid] < target) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      return _routePoints[lo];
    }

    final anchors = <LatLng>[];
    for (int k = 1; k <= nVias; k++) {
      anchors.add(atFraction(k / (nVias + 1)));
    }

    _waypoints.clear();
    _waypoints.add(start);
    for (final a in anchors) {
      _waypoints.add(a);
      _anchorIndices.add(_waypoints.length - 1);
    }
    setState(() {});
  }

  Future<void> _startNavigation() async {
    if (_route == null || _waypoints.length < 2) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NavigationScreen(
          route: _route!,
          waypoints: List<LatLng>.from(_waypoints),
          profile: _profile,
          nogos: _nogos,
          mapStyle: _mapStyle,
        ),
      ),
    );
  }

  Future<void> _onMenuSelected(String value) async {
    switch (value) {
      case 'navigate':
        await _startNavigation();
        break;
      case 'save':
        await _saveRoute();
        break;
      case 'load':
        final loaded = await Navigator.of(context).push<SavedRoute>(
          MaterialPageRoute(builder: (_) => const SavedRoutesScreen()),
        );
        if (loaded != null) await _loadSavedRoute(loaded);
        break;
      case 'import_gpx':
        await _importGpx();
        break;
      case 'import_url':
        await _importUrl();
        break;
      case 'recording':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecordingScreen(mapStyle: _mapStyle),
          ),
        );
        break;
      case 'recorded':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecordedRidesScreen()),
        );
        break;
      case 'library':
        await _openLibrary();
        break;
      case 'publish':
        await _publishCurrentRoute();
        break;
      case 'offline_maps':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OfflineMapsScreen(
              initialStyle: _mapStyle,
              initialViewport: _mapController.camera.visibleBounds,
            ),
          ),
        );
        break;
      case 'nogos':
        await _showNogosSheet();
        break;
      case 'poi_search':
        await _showPoiSearchSheet();
        break;
      case 'settings':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
    }
  }

  Future<void> _showPoiSearchSheet() async {
    final route = _route;
    if (route == null) return;
    final picks = await showRoutePoiSearchSheet(
      context,
      coordinates: route.coordinates,
    );
    if (picks == null || picks.isEmpty) return;
    setState(() {
      for (final hit in picks) {
        _pois.add(RoutePoi(
          id: '${hit.osmType}-${hit.osmId}',
          lat: hit.lat,
          lon: hit.lon,
          category: hit.category,
          name: hit.name,
          imageUrl: PoiImageResolver.resolve(hit.tags),
        ));
      }
    });
  }

  /// Picks one rest-spot POI (picnic site, alpine/wilderness hut, or shelter)
  /// every ~1.5 hours of estimated walking time and pins them on the map.
  /// Skips POIs we've already added so re-running is idempotent.
  Future<void> _addPauseRecommendations() async {
    final route = _route;
    if (route == null || _loadingPauseRecs) return;
    final speedKmh = ProfileSpeedPrefs.speedFor(_profile);
    final totalHours = route.distance / speedKmh;
    if (totalHours < 1.5) {
      _showError(AppLocalizations.of(context).pauseRecsTooShort);
      return;
    }
    setState(() => _loadingPauseRecs = true);
    try {
      final hits = await RoutePoiSearchService.searchAlongRoute(
        coordinates: route.coordinates,
        categories: {PoiCategory.picnic, PoiCategory.shelter},
        corridorMeters: 800,
      );
      // Target time markers every 1.5h, excluding 0 and the final pause-at-end.
      const interval = 1.5;
      final markers = <double>[];
      for (var t = interval; t < totalHours; t += interval) {
        markers.add(t * speedKmh); // target km along route
      }
      if (markers.isEmpty || hits.isEmpty) {
        if (mounted) _showError(AppLocalizations.of(context).pauseRecsNone);
        return;
      }
      final existing = _pois.map((p) => p.id).toSet();
      final picked = <RoutePoiHit>[];
      for (final targetKm in markers) {
        RoutePoiHit? best;
        double bestDelta = double.infinity;
        for (final h in hits) {
          if (picked.contains(h)) continue;
          final delta = (h.routeKm - targetKm).abs();
          if (delta < bestDelta && delta < 5.0) {
            bestDelta = delta;
            best = h;
          }
        }
        if (best != null) picked.add(best);
      }
      if (picked.isEmpty) {
        if (mounted) _showError(AppLocalizations.of(context).pauseRecsNone);
        return;
      }
      setState(() {
        for (final hit in picked) {
          final id = '${hit.osmType}-${hit.osmId}';
          if (existing.contains(id)) continue;
          _pois.add(RoutePoi(
            id: id,
            lat: hit.lat,
            lon: hit.lon,
            category: hit.category,
            name: hit.name,
            imageUrl: PoiImageResolver.resolve(hit.tags),
          ));
        }
      });
    } catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context).pauseRecsFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _loadingPauseRecs = false);
    }
  }

  Future<void> _showNogosSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFf5e9d8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.block, color: Color(0xFFef5350)),
                      const SizedBox(width: 8),
                      Text(l.nogoTitle,
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_nogos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l.nogoEmpty,
                          style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _nogos.length,
                        itemBuilder: (_, i) {
                          final n = _nogos[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.adjust, color: Color(0xFFef5350)),
                            title: Text(
                              '${n.lat.toStringAsFixed(4)}, ${n.lon.toStringAsFixed(4)}',
                              style: const TextStyle(color: Colors.black87, fontSize: 13),
                            ),
                            subtitle: Text(l.nogoRadius(n.radiusMeters),
                                style: const TextStyle(color: Colors.black54, fontSize: 11)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.black54),
                              onPressed: () async {
                                final updated = [..._nogos]..removeAt(i);
                                await NogoStorage.save(updated);
                                if (!mounted) return;
                                setState(() => _nogos = updated);
                                setSheetState(() {});
                                _maybeRecalculate();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: Text(l.nogoAdd),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFef5350),
                      foregroundColor: const Color(0xFFf5e9d8),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() => _placingNogo = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.nogoAddHint)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addNogoAt(LatLng latLng) async {
    int radius = 200;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFFf5e9d8),
            title: Text(l.nogoAdd, style: const TextStyle(color: Colors.black87)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.nogoRadius(radius),
                    style: const TextStyle(color: Colors.black54)),
                Slider(
                  value: radius.toDouble(),
                  min: 50,
                  max: 5000,
                  divisions: 99,
                  activeColor: const Color(0xFFef5350),
                  onChanged: (v) => setDialogState(() => radius = v.round()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text(l.nogoConfirmCancel,
                    style: const TextStyle(color: Colors.black54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFef5350),
                  foregroundColor: const Color(0xFFf5e9d8),
                ),
                onPressed: () => Navigator.of(ctx).pop(radius),
                child: Text(l.nogoConfirmAdd),
              ),
            ],
          ),
        );
      },
    );
    setState(() => _placingNogo = false);
    if (result == null) return;
    final nogo = NogoArea(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      lat: latLng.latitude,
      lon: latLng.longitude,
      radiusMeters: result,
    );
    final updated = [..._nogos, nogo];
    await NogoStorage.save(updated);
    if (!mounted) return;
    setState(() => _nogos = updated);
    _maybeRecalculate();
  }

  void _maybeRecalculate() {
    if (_route == null) return;
    if (_roundtripMode) {
      if (_lastRoundtripRequest != null && _waypoints.isNotEmpty) {
        _calculateRoundtrip(_lastRoundtripRequest!);
      }
    } else if (_waypoints.length >= 2) {
      _calculateRoute();
    }
  }

  Future<void> _importGpx() async {
    try {
      final picked = await GpxImport.pick();
      if (picked == null) return;
      final result = GpxImport.parse(picked.bytes);
      if (!mounted) return;
      await _handleImportedGpx(result);
    } on GpxImportException catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      _showError(e.code == 'empty' ? l.gpxImportEmpty : l.gpxImportFailed(e.toString()));
    } catch (e) {
      if (mounted) _showError(AppLocalizations.of(context).gpxImportFailed(e.toString()));
    }
  }

  Future<void> _handleImportedGpx(RouteResult parsed) async {
    final mode = await askGpxImportMode(
      context,
      pointCount: parsed.coordinates.length,
      distanceKm: parsed.distance,
    );
    if (mode == null || !mounted) return;
    final l = AppLocalizations.of(context);

    if (mode == GpxImportMode.track) {
      _displayRoute(parsed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.gpxImportSuccess(
          parsed.coordinates.length,
          parsed.distance.toStringAsFixed(1),
        ))),
      );
      return;
    }

    // Re-route via BRouter using the user's current profile.
    final samples = GpxImport.sampleWaypoints(parsed.coordinates);
    setState(() {
      _waypoints
        ..clear()
        ..addAll(samples.map((c) => LatLng(c[1], c[0])));
      _roundtripMode = false;
    });
    await _calculateRoute();
  }

  Future<void> _openLibrary() async {
    final picked = await Navigator.of(context).push<RouteResult>(
      MaterialPageRoute(builder: (_) => const LibraryScreen()),
    );
    if (picked != null && mounted) {
      // Library items arrive as parsed GPX → run them through the same
      // import-mode dialog so the user can choose re-route vs. as-is.
      await _handleImportedGpx(picked);
    }
  }

  Future<void> _publishCurrentRoute() async {
    if (_route == null) return;
    final l = AppLocalizations.of(context);

    final draft = await showPublishRouteDialog(
      context,
      suggestedTitle: _roundtripMode
          ? l.roundtripTourName(_rtDistanceKm)
          : l.defaultTourName,
    );
    if (draft == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6a4a28)),
      ),
    );

    try {
      final gpx = GpxBuilder.build(
        route: _route!,
        trackName: draft.title,
        pois: _pois,
      );
      final upload = await GarminShareService.upload(
        name: draft.title,
        gpx: gpx,
        distanceMeters: (_route!.distance * 1000).round(),
      );
      final editToken = upload.editToken;
      if (editToken == null) {
        throw Exception('server returned no edit token');
      }
      await EditTokenStore.save(upload.code, editToken);

      // Centroid of the route polyline for region filtering.
      final coords = _route!.coordinates;
      double sumLat = 0;
      double sumLon = 0;
      for (final c in coords) {
        sumLon += c[0];
        sumLat += c[1];
      }
      final centerLat = sumLat / coords.length;
      final centerLon = sumLon / coords.length;

      final ok = await LibraryService.publish(
        code: upload.code,
        editToken: editToken,
        title: draft.title,
        description: draft.description,
        profile: _profile,
        distanceM: (_route!.distance * 1000).round(),
        ascent: _route!.ascent.round(),
        centerLat: centerLat,
        centerLon: centerLon,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close spinner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? l.publishSuccess : l.publishFailed)),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.publishFailed)),
      );
    }
  }

  Future<void> _importUrl() async {
    final l = AppLocalizations.of(context);
    final url = await showUrlImportDialog(context);
    if (url == null || url.isEmpty) return;
    if (!mounted) return;

    // Spinner while we fetch — the GPX endpoint can take a few seconds.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(l.urlImportLoading)),
          ],
        ),
      ),
    );

    try {
      final fetched = await RouteUrlImport.fetch(url);
      final result = GpxImport.parse(fetched.bytes);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close spinner
      await _handleImportedGpx(result);
    } on RouteUrlImportException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showError(_urlImportMessage(l, e));
    } on GpxImportException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showError(e.code == 'empty' ? l.gpxImportEmpty : l.gpxImportFailed(e.toString()));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showError(l.gpxImportFailed(e.toString()));
    }
  }

  String _urlImportMessage(AppLocalizations l, RouteUrlImportException e) {
    switch (e.code) {
      case 'empty_url':
        return l.urlImportErrEmpty;
      case 'invalid_url':
        return l.urlImportErrInvalid;
      case 'network':
        return l.urlImportErrNetwork;
      case 'forbidden':
        return l.urlImportErrForbidden;
      case 'not_found':
        return l.urlImportErrNotFound;
      case 'not_gpx':
      case 'empty_body':
        return l.urlImportErrNotGpx;
      case 'strava_login_required':
        return l.urlImportErrStravaLogin;
      default:
        return l.gpxImportFailed(e.code);
    }
  }

  Future<void> _saveRoute() async {
    if (_route == null) return;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        final now = DateTime.now();
        final controller = TextEditingController(
          text: l.savedRouteDefaultName(now.day, now.month),
        );
        return AlertDialog(
          backgroundColor: const Color(0xFFf5e9d8),
          title: Text(l.savedRouteSaveDialogTitle, style: const TextStyle(color: Colors.black87)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: l.savedRouteSavePrompt,
              hintStyle: const TextStyle(color: Colors.black38),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6a4a28)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6a4a28), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l.commonSave, style: const TextStyle(color: Color(0xFF6a4a28))),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;

    // Flatten coordinates and turn hints so the route can be replayed
    // offline without another BRouter round trip.
    final flat = <double>[];
    for (final c in _route!.coordinates) {
      flat.add(c[0]);
      flat.add(c[1]);
      flat.add(c.length >= 3 ? c[2] : 0);
    }
    final hintRows = _route!.turnHints
        .map((h) => <double>[
              h.coordIndex.toDouble(),
              h.cmd.index.toDouble(),
              h.exitNumber.toDouble(),
              h.distanceToNextM,
              h.angle,
            ])
        .toList();
    final cached = CachedRoute(
      flatCoords: flat,
      ascent: _route!.ascent,
      descent: _route!.descent,
      turnHints: hintRows,
    );

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
      cached: cached,
    );
    await RouteStorage.save(saved);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).savedRouteSaved)),
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

    // Prefer the cached snapshot if present so the saved route is
    // immediately viewable / navigable offline. Re-routing through BRouter
    // is still available via the explicit "recalc" UI when online.
    if (r.cached != null) {
      final c = r.cached!;
      _displayRoute(RouteResult(
        geojson: const {},
        distance: r.distanceKm,
        ascent: c.ascent,
        descent: c.descent,
        time: r.durationSeconds.toDouble(),
        coordinates: c.coordinates,
        segments: const <RouteSegment>[],
        turnHints: c.turnHints.map((row) => TurnHint(
              coordIndex: row[0].toInt(),
              cmd: TurnCmd.fromCode(row[1].toInt()),
              exitNumber: row[2].toInt(),
              distanceToNextM: row[3],
              angle: row[4],
            )).toList(),
      ));
      return;
    }
    if (_waypoints.length >= 2) {
      await _calculateRoute();
    }
  }

  void _showWeather() {
    if (_route == null) return;
    final speed = ProfileSpeedPrefs.speedFor(_profile);
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
      final l = AppLocalizations.of(context);
      markers.add(Marker(
        point: LatLng(s.lat, s.lon),
        width: 30,
        height: 30,
        alignment: Alignment.center,
        child: Tooltip(
          message: s.townName ?? l.stageTooltip(s.index, s.lengthKm.toStringAsFixed(0)),
          triggerMode: TooltipTriggerMode.tap,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFffb74d),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black87, width: 2),
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
    final label = _waypointNames[key] ?? AppLocalizations.of(context).defaultWaypoint;
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
      _waypointNames[_wpKey(p)] = a.name ?? a.localizedType(AppLocalizations.of(context));
    });
    if (_roundtripMode) _exitRoundtripMode();
    _recalculate();
  }

  Future<void> _shareRoute() async {
    if (_waypoints.isEmpty) return;
    final l = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    l.shareSheetTitle,
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(l.shareCopyLink),
              subtitle: Text(l.shareCopyLinkSubtitle),
              onTap: () => Navigator.pop(ctx, 'link'),
            ),
            if (_route != null && _garminAvailable)
              ListTile(
                leading: const Icon(Icons.bluetooth_searching),
                title: Text(l.shareDirectToEdge),
                subtitle: Text(l.shareDirectToEdgeSubtitle),
                onTap: () => Navigator.pop(ctx, 'edge'),
              ),
            if (_route != null)
              ListTile(
                leading: const Icon(Icons.directions_bike),
                title: Text(l.shareToGarmin),
                subtitle: Text(l.shareToGarminSubtitle),
                onTap: () => Navigator.pop(ctx, 'garmin'),
              ),
            if (_route != null)
              ListTile(
                leading: const Icon(Icons.pedal_bike),
                title: Text(l.shareToWahoo),
                subtitle: Text(l.shareToWahooSubtitle),
                onTap: () => Navigator.pop(ctx, 'wahoo'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'link') {
      await _copyShareLink();
    } else if (action == 'garmin') {
      await _sendToGarmin();
    } else if (action == 'edge') {
      await _sendDirectToEdge();
    } else if (action == 'wahoo') {
      await _sendToWahoo();
    }
  }

  Future<void> _copyShareLink() async {
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
      SnackBar(content: Text(AppLocalizations.of(context).routeLinkCopied)),
    );
  }

  Future<void> _sendToGarmin() async {
    if (_route == null) return;
    final l = AppLocalizations.of(context);
    final trackName = _roundtripMode
        ? l.roundtripTourName(_rtDistanceKm)
        : l.defaultTourName;
    final gpx = GpxBuilder.build(
      route: _route!,
      trackName: trackName,
      pois: _pois,
      poiFallbackName: (poi) => poi.category.localizedLabel(l),
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await GarminShareService.upload(
        name: trackName,
        gpx: gpx,
        distanceMeters: (_route!.distance * 1000).round(),
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss spinner
      await _showGarminCodeDialog(result);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.garminUploadFailed(e.toString()))),
      );
    }
  }

  /// Wahoo Companion App listens for `wahoofitness://route?url=...` deep
  /// links and fetches the GPX from the URL we hand it. The link only
  /// works on a phone where the Wahoo app is installed; on Web/Desktop
  /// it'll silently fail. We upload to the existing share-service first
  /// because the Wahoo app needs an HTTPS URL it can GET — no Companion
  /// app accepts raw file payloads.
  Future<void> _sendToWahoo() async {
    if (_route == null) return;
    final l = AppLocalizations.of(context);
    final trackName = _roundtripMode
        ? l.roundtripTourName(_rtDistanceKm)
        : l.defaultTourName;
    final gpx = GpxBuilder.build(
      route: _route!,
      trackName: trackName,
      pois: _pois,
      poiFallbackName: (poi) => poi.category.localizedLabel(l),
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await GarminShareService.upload(
        name: trackName,
        gpx: gpx,
        distanceMeters: (_route!.distance * 1000).round(),
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final deepLink = Uri.parse(
        'wahoofitness://route?url=${Uri.encodeQueryComponent(result.gpxUrl)}',
      );
      final launched = await launchUrl(
        deepLink,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        // App nicht installiert → Hilfe-Dialog mit Store-Link.
        await _showWahooNotInstalledDialog();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.wahooSendFailed(e.toString()))),
      );
    }
  }

  Future<void> _showWahooNotInstalledDialog() async {
    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFf5e9d8),
        title: Text(l.wahooNotInstalledTitle),
        content: Text(l.wahooNotInstalledBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonOk),
          ),
        ],
      ),
    );
  }

  Future<void> _showGarminCodeDialog(GarminShareResult result) async {
    final l = AppLocalizations.of(context);
    final expiresLocal = result.expiresAt.toLocal();
    final dateStr =
        '${expiresLocal.day.toString().padLeft(2, '0')}.${expiresLocal.month.toString().padLeft(2, '0')}.${expiresLocal.year} '
        '${expiresLocal.hour.toString().padLeft(2, '0')}:${expiresLocal.minute.toString().padLeft(2, '0')}';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.garminCodeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            SelectableText(
              result.code,
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(l.garminCodeHint, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              l.garminCodeExpiresAt(dateStr),
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: result.code));
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(l.garminCodeCopied)),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(MaterialLocalizations.of(ctx).copyButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _sendDirectToEdge() async {
    if (_route == null) return;
    final l = AppLocalizations.of(context);

    var devices = await GarminConnect.listDevices();
    if (!mounted) return;
    GarminDevice? target;
    while (target == null) {
      if (devices.isEmpty) {
        final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.garminPickDevicesTitle),
            content: Text(l.garminPickDevicesPrompt),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.garminPickDevicesAction),
              ),
            ],
          ),
        );
        if (go != true || !mounted) return;
        devices = await GarminConnect.pickDevices();
        if (!mounted) return;
        if (devices.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.garminNoDevicesAfterPick)),
          );
          return;
        }
        continue;
      }

      // Always show the picker sheet — even with one device — so the user
      // can re-trigger the GCM authorisation flow if "device offline"
      // shows up wrongly (a fresh pickDevices() refreshes status).
      final choice = await showModalBottomSheet<_DevicePickerResult>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(children: [
                  Text(l.garminPickDevicesTitle,
                      style: Theme.of(ctx).textTheme.titleMedium),
                ]),
              ),
              for (final d in devices)
                ListTile(
                  leading: Icon(d.isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled),
                  title: Text(d.name.isEmpty ? d.modelName : d.name),
                  subtitle: d.isConnected ? null : Text(l.garminDeviceOffline(d.name)),
                  onTap: () => Navigator.pop(ctx, _DevicePickerResult.pick(d)),
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(l.garminRepickDevices),
                subtitle: Text(l.garminRepickDevicesSubtitle),
                onTap: () => Navigator.pop(ctx, _DevicePickerResult.repick()),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (choice == null || !mounted) return;
      if (choice.device != null) {
        target = choice.device;
      } else {
        devices = await GarminConnect.pickDevices();
        if (!mounted) return;
      }
    }

    final trackName = _roundtripMode
        ? l.roundtripTourName(_rtDistanceKm)
        : l.defaultTourName;
    final gpx = GpxBuilder.build(
      route: _route!,
      trackName: trackName,
      pois: _pois,
      poiFallbackName: (poi) => poi.category.localizedLabel(l),
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(l.garminSendingTo(target!.name))),
          ],
        ),
      ),
    );

    try {
      final upload = await GarminShareService.upload(
        name: trackName,
        gpx: gpx,
        distanceMeters: (_route!.distance * 1000).round(),
      );
      await GarminConnect.sendCode(deviceId: target.id, code: upload.code);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.garminSendSuccess(target.name))),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.garminSendFailed(e.toString()))),
      );
    }
  }

  Future<void> _exportGpx() async {
    if (_route == null) return;

    try {
      final l = AppLocalizations.of(context);
      final trackName = _roundtripMode
          ? l.roundtripTourName(_rtDistanceKm)
          : l.defaultTourName;
      final gpx = GpxBuilder.build(
        route: _route!,
        trackName: trackName,
        pois: _pois,
        poiFallbackName: (poi) => poi.category.localizedLabel(l),
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'wegwiesel-$_profile-$timestamp.gpx';

      await exportGpxFile(filename, gpx);
    } catch (e) {
      if (mounted) _showError(AppLocalizations.of(context).exportFailed(e.toString()));
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
      ++_routeRequestId;
      setState(() {
        _route = null;
        _routePoints = [];
        _activeRouteKind = _RouteAlternativeKind.primary;
        _activeRouteVariantIdx = 0;
        _alternativeRoutes = const [];
        _loadingAlternativeIdx = null;
        _loadingShortestCarRoute = false;
        _loadingAvoidMotorwaysCarRoute = false;
        _highlightIndex = null;
      });
    }
  }

  void _clearAll() {
    ++_routeRequestId;
    _waypoints.clear();
    _anchorIndices.clear();
    _pois.clear();
    _sights = [];
    setState(() {
      _route = null;
      _routePoints = [];
      _activeRouteKind = _RouteAlternativeKind.primary;
      _activeRouteVariantIdx = 0;
      _alternativeRoutes = const [];
      _loadingAlternativeIdx = null;
      _loadingShortestCarRoute = false;
      _loadingAvoidMotorwaysCarRoute = false;
      _highlightIndex = null;
    });
  }
}

enum _RouteAlternativeKind { primary, variant, shortest, avoidMotorways }

class _RouteAlternative {
  final RouteResult route;
  final _RouteAlternativeKind kind;
  final int variantIdx;

  const _RouteAlternative._(this.route, this.kind, this.variantIdx);

  const _RouteAlternative.variant(RouteResult route, int variantIdx)
      : this._(route, _RouteAlternativeKind.variant, variantIdx);

  const _RouteAlternative.shortest(RouteResult route)
      : this._(route, _RouteAlternativeKind.shortest, 0);

  const _RouteAlternative.avoidMotorways(RouteResult route)
      : this._(route, _RouteAlternativeKind.avoidMotorways, 0);

  String label(AppLocalizations l) {
    switch (kind) {
      case _RouteAlternativeKind.primary:
        return l.altRoutePrimary;
      case _RouteAlternativeKind.variant:
        return l.altRouteVariant(variantIdx);
      case _RouteAlternativeKind.shortest:
        return l.altRouteShortest;
      case _RouteAlternativeKind.avoidMotorways:
        return l.altRouteAvoidMotorways;
    }
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

class _DevicePickerResult {
  final GarminDevice? device;
  const _DevicePickerResult._(this.device);
  factory _DevicePickerResult.pick(GarminDevice d) => _DevicePickerResult._(d);
  factory _DevicePickerResult.repick() => const _DevicePickerResult._(null);
}
