import '../../models/route_result.dart';
import 'graph_offline_router.dart';
import 'offline_router.dart';
import 'rd5_graph_loader.dart';
import 'rd5_segment_downloader.dart';

class Rd5OfflineRouter implements OfflineRouter {
  final Rd5SegmentDownloader downloader;
  final Rd5GraphLoader graphLoader;

  Rd5OfflineRouter({
    Rd5SegmentDownloader? downloader,
    Rd5GraphLoader? graphLoader,
  })  : downloader = downloader ?? Rd5SegmentDownloader.instance,
        graphLoader = graphLoader ?? Rd5GraphLoader();

  @override
  Future<bool> canRoute({
    required double startLon,
    required double startLat,
    required double endLon,
    required double endLat,
  }) async {
    final local = (await downloader.localSegments())
        .map((f) => f.uri.pathSegments.last)
        .toSet();
    final needed = Rd5SegmentDownloader.segmentFilenamesForBounds(
      minLat: startLat < endLat ? startLat : endLat,
      minLon: startLon < endLon ? startLon : endLon,
      maxLat: startLat > endLat ? startLat : endLat,
      maxLon: startLon > endLon ? startLon : endLon,
    );
    return needed.isNotEmpty && needed.every(local.contains);
  }

  @override
  Future<RouteResult> calculate({
    required List<List<double>> waypoints,
    required String profile,
  }) async {
    if (waypoints.length < 2) {
      throw const OfflineRoutingException(
        'bad_request',
        'at least two waypoints are required',
      );
    }
    var minLat = waypoints.first[1];
    var maxLat = waypoints.first[1];
    var minLon = waypoints.first[0];
    var maxLon = waypoints.first[0];
    for (final point in waypoints) {
      if (point[1] < minLat) minLat = point[1];
      if (point[1] > maxLat) maxLat = point[1];
      if (point[0] < minLon) minLon = point[0];
      if (point[0] > maxLon) maxLon = point[0];
    }

    const padding = 0.05;
    final graph = await graphLoader.loadBounds(
      minLat: minLat - padding,
      minLon: minLon - padding,
      maxLat: maxLat + padding,
      maxLon: maxLon + padding,
    );
    if (graph.isEmpty) {
      throw const OfflineRoutingException(
        'no_local_graph',
        'downloaded segments did not decode to a local graph',
      );
    }
    return GraphOfflineRouter(
      graph: graph,
      maxSnapDistanceMeters: 1000,
    ).calculate(
      waypoints: waypoints,
      profile: profile,
    );
  }
}
