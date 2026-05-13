import 'dart:collection';
import 'dart:math';

import '../../models/route_result.dart';
import 'offline_router.dart';
import 'offline_routing_graph.dart';
import 'trekking_profile.dart';

class GraphOfflineRouter implements OfflineRouter {
  final OfflineRoutingGraph graph;
  final TrekkingProfile profileModel;
  final double maxSnapDistanceMeters;

  GraphOfflineRouter({
    required this.graph,
    this.profileModel = const TrekkingProfile(),
    this.maxSnapDistanceMeters = 250,
  });

  @override
  Future<bool> canRoute({
    required double startLon,
    required double startLat,
    required double endLon,
    required double endLat,
  }) async {
    if (graph.isEmpty) return false;
    return graph.nearestNodeDistanceMeters(startLon, startLat) <=
            maxSnapDistanceMeters &&
        graph.nearestNodeDistanceMeters(endLon, endLat) <=
            maxSnapDistanceMeters;
  }

  @override
  Future<RouteResult> calculate({
    required List<List<double>> waypoints,
    required String profile,
  }) async {
    if (!profileModel.supports(profile)) {
      throw OfflineRoutingException(
        'unsupported_profile',
        'offline routing currently supports only $TrekkingProfile.supportedProfile',
      );
    }
    if (waypoints.length < 2) {
      throw const OfflineRoutingException(
        'bad_request',
        'at least two waypoints are required',
      );
    }

    final routeEdges = <_ResolvedEdge>[];
    for (var i = 1; i < waypoints.length; i++) {
      final from = _snap(waypoints[i - 1]);
      final to = _snap(waypoints[i]);
      final leg = _routeLeg(from, to);
      routeEdges.addAll(leg);
    }
    if (routeEdges.isEmpty) {
      throw const OfflineRoutingException('no_route', 'no route found');
    }
    return _toRouteResult(routeEdges);
  }

  OfflineRoutingNode _snap(List<double> waypoint) {
    final node = graph.nearestNode(waypoint[0], waypoint[1]);
    if (node == null) {
      throw const OfflineRoutingException('no_data', 'no local routing graph');
    }
    final distance = OfflineRoutingGraph.haversineMeters(
        waypoint[0], waypoint[1], node.lon, node.lat);
    if (distance > maxSnapDistanceMeters) {
      throw OfflineRoutingException(
        'snap_failed',
        'waypoint is ${distance.round()} m from the nearest routable node',
      );
    }
    return node;
  }

  List<_ResolvedEdge> _routeLeg(
    OfflineRoutingNode start,
    OfflineRoutingNode goal,
  ) {
    final open = _PriorityQueue<_QueueEntry>((a, b) {
      final byPriority = a.priority.compareTo(b.priority);
      if (byPriority != 0) return byPriority;
      return a.nodeId.compareTo(b.nodeId);
    });
    final bestCost = <int, double>{start.id: 0};
    final previous = <int, _PreviousHop>{};
    final closed = <int>{};

    open.add(_QueueEntry(start.id, 0));

    while (open.isNotEmpty) {
      final current = open.removeFirst();
      if (!closed.add(current.nodeId)) continue;
      if (current.nodeId == goal.id) break;

      final node = graph.nodes[current.nodeId]!;
      for (final edge in graph.outgoing[current.nodeId] ?? const []) {
        if (!profileModel.allows(edge)) continue;
        final next = graph.nodes[edge.toNodeId];
        if (next == null || closed.contains(next.id)) continue;

        final elevationGain = max(0.0, next.elevation - node.elevation);
        final newCost = bestCost[current.nodeId]! +
            profileModel.costSeconds(edge, elevationGain);
        if (newCost >= (bestCost[next.id] ?? double.infinity)) continue;

        bestCost[next.id] = newCost;
        previous[next.id] = _PreviousHop(current.nodeId, edge, newCost);
        final heuristic = OfflineRoutingGraph.haversineMeters(
              next.lon,
              next.lat,
              goal.lon,
              goal.lat,
            ) /
            (22 * 1000 / 3600);
        open.add(_QueueEntry(next.id, newCost + heuristic));
      }
    }

    if (!previous.containsKey(goal.id) && start.id != goal.id) {
      throw const OfflineRoutingException('no_route', 'no route found');
    }

    final edges = <_ResolvedEdge>[];
    var cursor = goal.id;
    while (cursor != start.id) {
      final hop = previous[cursor];
      if (hop == null) break;
      edges.add(_ResolvedEdge(
        from: graph.nodes[hop.fromNodeId]!,
        to: graph.nodes[hop.edge.toNodeId]!,
        edge: hop.edge,
        cumulativeSeconds: hop.costSeconds,
      ));
      cursor = hop.fromNodeId;
    }
    return edges.reversed.toList();
  }

  RouteResult _toRouteResult(List<_ResolvedEdge> edges) {
    final coords = <List<double>>[];
    double distanceMeters = 0;
    double ascent = 0;
    double seconds = 0;
    final messages = <List<dynamic>>[
      ['Longitude', 'Latitude', 'Elevation', 'Distance', 'Cost', 'Tags']
    ];

    for (var i = 0; i < edges.length; i++) {
      final resolved = edges[i];
      if (i == 0) {
        coords.add(
            [resolved.from.lon, resolved.from.lat, resolved.from.elevation]);
      }
      coords.add([resolved.to.lon, resolved.to.lat, resolved.to.elevation]);
      distanceMeters += resolved.edge.distanceMeters;
      final elevationDiff = resolved.to.elevation - resolved.from.elevation;
      if (elevationDiff > 0) ascent += elevationDiff;
      seconds = resolved.cumulativeSeconds;
      messages.add([
        resolved.to.lon,
        resolved.to.lat,
        resolved.to.elevation,
        resolved.edge.distanceMeters,
        seconds,
        '',
        '',
        '',
        '',
        _formatTags(resolved.edge.tags),
      ]);
    }

    final geojson = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'LineString',
            'coordinates': coords,
          },
          'properties': {
            'track-length': distanceMeters,
            'filtered ascend': ascent,
            'plain-ascend': ascent,
            'total-time': seconds,
            'messages': messages,
          },
        }
      ],
    };
    return RouteResult.fromGeojson(geojson);
  }

  String _formatTags(Map<String, String> tags) =>
      tags.entries.map((e) => '${e.key}=${e.value}').join(' ');
}

class _ResolvedEdge {
  final OfflineRoutingNode from;
  final OfflineRoutingNode to;
  final OfflineRoutingEdge edge;
  final double cumulativeSeconds;

  const _ResolvedEdge({
    required this.from,
    required this.to,
    required this.edge,
    required this.cumulativeSeconds,
  });
}

class _PreviousHop {
  final int fromNodeId;
  final OfflineRoutingEdge edge;
  final double costSeconds;

  const _PreviousHop(this.fromNodeId, this.edge, this.costSeconds);
}

class _QueueEntry {
  final int nodeId;
  final double priority;

  const _QueueEntry(this.nodeId, this.priority);
}

class _PriorityQueue<T> {
  final int Function(T a, T b) compare;
  final SplayTreeMap<T, int> _items;

  _PriorityQueue(this.compare) : _items = SplayTreeMap<T, int>(compare);

  bool get isNotEmpty => _items.isNotEmpty;

  void add(T item) => _items[item] = (_items[item] ?? 0) + 1;

  T removeFirst() {
    final item = _items.firstKey() as T;
    final count = _items[item]!;
    if (count == 1) {
      _items.remove(item);
    } else {
      _items[item] = count - 1;
    }
    return item;
  }
}
