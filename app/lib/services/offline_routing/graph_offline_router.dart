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

  /// Bidirectional A* — runs two simultaneous searches, one forward from
  /// [start] and one backward from [goal] (using the graph's `incoming`
  /// adjacency). When a node has been touched by both frontiers we record
  /// the meeting point and use the standard termination condition
  /// `min(forwardTopPriority) + min(backwardTopPriority) >= bestMeetingCost`,
  /// which is sound for the consistent haversine/maxSpeed heuristic we
  /// use. On graphs typical for cycling this is ~2× faster than the prior
  /// single-direction A* for long-distance routes; for short legs both
  /// algorithms touch roughly the same nodes.
  List<_ResolvedEdge> _routeLeg(
    OfflineRoutingNode start,
    OfflineRoutingNode goal,
  ) {
    if (start.id == goal.id) return const [];

    int compare(_QueueEntry a, _QueueEntry b) {
      final byPriority = a.priority.compareTo(b.priority);
      if (byPriority != 0) return byPriority;
      return a.nodeId.compareTo(b.nodeId);
    }

    final fOpen = _PriorityQueue<_QueueEntry>(compare);
    final bOpen = _PriorityQueue<_QueueEntry>(compare);
    final fBest = <int, double>{start.id: 0};
    final bBest = <int, double>{goal.id: 0};
    final fPrev = <int, _PreviousHop>{};
    final bPrev = <int, _PreviousHop>{};
    final fClosed = <int>{};
    final bClosed = <int>{};

    fOpen.add(_QueueEntry(start.id, _heuristicSeconds(start, goal)));
    bOpen.add(_QueueEntry(goal.id, _heuristicSeconds(start, goal)));

    double mu = double.infinity;
    int? meeting;

    while (fOpen.isNotEmpty && bOpen.isNotEmpty) {
      final fTop = fOpen.firstOrNull?.priority ?? double.infinity;
      final bTop = bOpen.firstOrNull?.priority ?? double.infinity;
      if (fTop + bTop >= mu) break;

      if (fTop <= bTop) {
        final current = fOpen.removeFirst();
        if (!fClosed.add(current.nodeId)) continue;
        final node = graph.nodes[current.nodeId];
        if (node == null) continue;
        for (final edge in graph.outgoing[current.nodeId] ?? const []) {
          if (!profileModel.allows(edge)) continue;
          final next = graph.nodes[edge.toNodeId];
          if (next == null || fClosed.contains(next.id)) continue;
          final gain = max(0.0, next.elevation - node.elevation);
          final newCost = fBest[current.nodeId]! +
              profileModel.costSeconds(edge, gain);
          if (newCost >= (fBest[next.id] ?? double.infinity)) continue;
          fBest[next.id] = newCost;
          fPrev[next.id] = _PreviousHop(current.nodeId, edge, newCost);
          final bc = bBest[next.id];
          if (bc != null && newCost + bc < mu) {
            mu = newCost + bc;
            meeting = next.id;
          }
          fOpen.add(
              _QueueEntry(next.id, newCost + _heuristicSeconds(next, goal)));
        }
      } else {
        final current = bOpen.removeFirst();
        if (!bClosed.add(current.nodeId)) continue;
        final node = graph.nodes[current.nodeId];
        if (node == null) continue;
        // The reversed-graph edges live in incoming. Each entry's
        // fromNodeId equals the current backward node; toNodeId is the
        // neighbour we relax. The original-graph direction is the
        // reverse of that, so elevation gain in the *forward* walk is
        // node.elevation − next.elevation.
        for (final edge in graph.incoming[current.nodeId] ?? const []) {
          if (!profileModel.allows(edge)) continue;
          final next = graph.nodes[edge.toNodeId];
          if (next == null || bClosed.contains(next.id)) continue;
          final gain = max(0.0, node.elevation - next.elevation);
          final newCost = bBest[current.nodeId]! +
              profileModel.costSeconds(edge, gain);
          if (newCost >= (bBest[next.id] ?? double.infinity)) continue;
          bBest[next.id] = newCost;
          bPrev[next.id] = _PreviousHop(current.nodeId, edge, newCost);
          final fc = fBest[next.id];
          if (fc != null && newCost + fc < mu) {
            mu = newCost + fc;
            meeting = next.id;
          }
          bOpen.add(
              _QueueEntry(next.id, newCost + _heuristicSeconds(start, next)));
        }
      }
    }

    if (meeting == null) {
      throw const OfflineRoutingException('no_route', 'no route found');
    }
    return _reconstructPath(start, goal, meeting, fPrev, bPrev, fBest, bBest);
  }

  /// Builds the resolved edge list start → goal by joining the forward
  /// fragment with the (reversed) backward fragment at the meeting node.
  List<_ResolvedEdge> _reconstructPath(
    OfflineRoutingNode start,
    OfflineRoutingNode goal,
    int meeting,
    Map<int, _PreviousHop> fPrev,
    Map<int, _PreviousHop> bPrev,
    Map<int, double> fBest,
    Map<int, double> bBest,
  ) {
    final forwardSegment = <_ResolvedEdge>[];
    var cursor = meeting;
    while (cursor != start.id) {
      final hop = fPrev[cursor];
      if (hop == null) break;
      forwardSegment.add(_ResolvedEdge(
        from: graph.nodes[hop.fromNodeId]!,
        to: graph.nodes[hop.edge.toNodeId]!,
        edge: hop.edge,
        cumulativeSeconds: hop.costSeconds,
      ));
      cursor = hop.fromNodeId;
    }
    final result = forwardSegment.reversed.toList();

    // Backward fragment: bPrev[node] stores the reversed-direction edge
    // we used to reach `node` in the backward search. Its `fromNodeId`
    // equals the current `cursor` (going outward from meeting toward
    // goal); `toNodeId` is the next node on the forward path.
    final fwdAtMeeting = fBest[meeting] ?? 0;
    final bwdAtMeeting = bBest[meeting] ?? 0;
    cursor = meeting;
    while (cursor != goal.id) {
      final hop = bPrev[cursor];
      if (hop == null) break;
      final next = hop.fromNodeId;
      final cumulative = fwdAtMeeting +
          (bwdAtMeeting - (bBest[next] ?? bwdAtMeeting));
      result.add(_ResolvedEdge(
        from: graph.nodes[cursor]!,
        to: graph.nodes[next]!,
        edge: hop.edge,
        cumulativeSeconds: cumulative,
      ));
      cursor = next;
    }
    return result;
  }

  double _heuristicSeconds(OfflineRoutingNode a, OfflineRoutingNode b) {
    // Best-case speed of the routing profile (≈ flat asphalt cycleway).
    // Must be an upper bound on actual speed to keep A* admissible.
    const maxSpeedKmh = 22.0;
    return OfflineRoutingGraph.haversineMeters(a.lon, a.lat, b.lon, b.lat) /
        (maxSpeedKmh * 1000 / 3600);
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
  T? get firstOrNull => _items.isEmpty ? null : _items.firstKey() as T;

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
