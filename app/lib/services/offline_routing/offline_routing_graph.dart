import 'dart:math';

class OfflineRoutingGraph {
  final Map<int, OfflineRoutingNode> nodes;
  final Map<int, List<OfflineRoutingEdge>> outgoing;
  // Same shape as [outgoing] but oriented for the reversed graph, used by
  // backward A* search. For each original edge A→B, [incoming] holds a
  // reversed copy at B (whose fromNodeId is B, toNodeId is A). For
  // bidirectional edges the original direction is also added at A.
  final Map<int, List<OfflineRoutingEdge>> incoming;

  OfflineRoutingGraph({
    required Iterable<OfflineRoutingNode> nodes,
    required Iterable<OfflineRoutingEdge> edges,
  })  : nodes = {for (final node in nodes) node.id: node},
        outgoing = _buildOutgoing(edges),
        incoming = _buildIncoming(edges);

  bool get isEmpty => nodes.isEmpty;

  static Map<int, List<OfflineRoutingEdge>> _buildOutgoing(
    Iterable<OfflineRoutingEdge> edges,
  ) {
    final out = <int, List<OfflineRoutingEdge>>{};
    for (final edge in edges) {
      out.putIfAbsent(edge.fromNodeId, () => <OfflineRoutingEdge>[]).add(edge);
      if (edge.bidirectional) {
        out.putIfAbsent(edge.toNodeId, () => <OfflineRoutingEdge>[]).add(
              edge.reversed(),
            );
      }
    }
    return out;
  }

  static Map<int, List<OfflineRoutingEdge>> _buildIncoming(
    Iterable<OfflineRoutingEdge> edges,
  ) {
    final in_ = <int, List<OfflineRoutingEdge>>{};
    for (final edge in edges) {
      in_.putIfAbsent(edge.toNodeId, () => <OfflineRoutingEdge>[]).add(
            edge.reversed(),
          );
      if (edge.bidirectional) {
        in_.putIfAbsent(edge.fromNodeId, () => <OfflineRoutingEdge>[]).add(
              edge,
            );
      }
    }
    return in_;
  }

  OfflineRoutingNode? nearestNode(double lon, double lat) {
    OfflineRoutingNode? best;
    var bestMeters = double.infinity;
    for (final node in nodes.values) {
      final meters = haversineMeters(lon, lat, node.lon, node.lat);
      if (meters < bestMeters) {
        best = node;
        bestMeters = meters;
      }
    }
    return best;
  }

  double nearestNodeDistanceMeters(double lon, double lat) {
    final node = nearestNode(lon, lat);
    if (node == null) return double.infinity;
    return haversineMeters(lon, lat, node.lon, node.lat);
  }

  static double haversineMeters(
    double lon1,
    double lat1,
    double lon2,
    double lat2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final rLat1 = _degToRad(lat1);
    final rLat2 = _degToRad(lat2);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(rLat1) * cos(rLat2) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadiusMeters * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _degToRad(double deg) => deg * pi / 180.0;
}

class OfflineRoutingNode {
  final int id;
  final double lon;
  final double lat;
  final double elevation;

  const OfflineRoutingNode({
    required this.id,
    required this.lon,
    required this.lat,
    this.elevation = 0,
  });
}

class OfflineRoutingEdge {
  final int fromNodeId;
  final int toNodeId;
  final double distanceMeters;
  final Map<String, String> tags;
  final bool bidirectional;

  const OfflineRoutingEdge({
    required this.fromNodeId,
    required this.toNodeId,
    required this.distanceMeters,
    this.tags = const {},
    this.bidirectional = true,
  });

  OfflineRoutingEdge reversed() => OfflineRoutingEdge(
        fromNodeId: toNodeId,
        toNodeId: fromNodeId,
        distanceMeters: distanceMeters,
        tags: tags,
        bidirectional: false,
      );
}
