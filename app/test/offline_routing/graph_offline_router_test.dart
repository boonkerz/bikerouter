import 'package:bikerouter/services/offline_routing/graph_offline_router.dart';
import 'package:bikerouter/services/offline_routing/offline_router.dart';
import 'package:bikerouter/services/offline_routing/offline_routing_graph.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes over the lowest trekking cost path', () async {
    final graph = OfflineRoutingGraph(
      nodes: const [
        OfflineRoutingNode(id: 1, lon: 11.0, lat: 48.0),
        OfflineRoutingNode(id: 2, lon: 11.001, lat: 48.0),
        OfflineRoutingNode(id: 3, lon: 11.002, lat: 48.0),
        OfflineRoutingNode(id: 4, lon: 11.001, lat: 48.001),
      ],
      edges: const [
        OfflineRoutingEdge(
          fromNodeId: 1,
          toNodeId: 2,
          distanceMeters: 80,
          tags: {'highway': 'cycleway', 'surface': 'asphalt'},
        ),
        OfflineRoutingEdge(
          fromNodeId: 2,
          toNodeId: 3,
          distanceMeters: 80,
          tags: {'highway': 'cycleway', 'surface': 'asphalt'},
        ),
        OfflineRoutingEdge(
          fromNodeId: 1,
          toNodeId: 4,
          distanceMeters: 80,
          tags: {'highway': 'path', 'surface': 'sand'},
        ),
        OfflineRoutingEdge(
          fromNodeId: 4,
          toNodeId: 3,
          distanceMeters: 80,
          tags: {'highway': 'path', 'surface': 'sand'},
        ),
      ],
    );
    final router = GraphOfflineRouter(graph: graph);

    final result = await router.calculate(
      waypoints: const [
        [11.0, 48.0],
        [11.002, 48.0],
      ],
      profile: 'trekking',
    );

    expect(result.coordinates, hasLength(3));
    expect(result.coordinates[1][0], 11.001);
    expect(result.distance, closeTo(0.160, 0.001));
    expect(result.time, greaterThan(0));
  });

  test('rejects unsupported profiles', () async {
    final router = GraphOfflineRouter(
      graph: OfflineRoutingGraph(
        nodes: const [
          OfflineRoutingNode(id: 1, lon: 11.0, lat: 48.0),
          OfflineRoutingNode(id: 2, lon: 11.001, lat: 48.0),
        ],
        edges: const [
          OfflineRoutingEdge(
            fromNodeId: 1,
            toNodeId: 2,
            distanceMeters: 80,
            tags: {'highway': 'cycleway'},
          ),
        ],
      ),
    );

    expect(
      () => router.calculate(
        waypoints: const [
          [11.0, 48.0],
          [11.001, 48.0],
        ],
        profile: 'fastbike',
      ),
      throwsA(isA<OfflineRoutingException>()),
    );
  });

  test('keeps all edges across via waypoints', () async {
    final router = GraphOfflineRouter(
      graph: OfflineRoutingGraph(
        nodes: const [
          OfflineRoutingNode(id: 1, lon: 11.0, lat: 48.0),
          OfflineRoutingNode(id: 2, lon: 11.001, lat: 48.0),
          OfflineRoutingNode(id: 3, lon: 11.002, lat: 48.0),
        ],
        edges: const [
          OfflineRoutingEdge(
            fromNodeId: 1,
            toNodeId: 2,
            distanceMeters: 80,
            tags: {'highway': 'cycleway'},
          ),
          OfflineRoutingEdge(
            fromNodeId: 2,
            toNodeId: 3,
            distanceMeters: 80,
            tags: {'highway': 'cycleway'},
          ),
        ],
      ),
    );

    final result = await router.calculate(
      waypoints: const [
        [11.0, 48.0],
        [11.001, 48.0],
        [11.002, 48.0],
      ],
      profile: 'trekking',
    );

    expect(result.coordinates, hasLength(3));
    expect(result.distance, closeTo(0.160, 0.001));
  });

  test('canRoute checks local snap distance', () async {
    final router = GraphOfflineRouter(
      maxSnapDistanceMeters: 30,
      graph: OfflineRoutingGraph(
        nodes: const [
          OfflineRoutingNode(id: 1, lon: 11.0, lat: 48.0),
          OfflineRoutingNode(id: 2, lon: 11.001, lat: 48.0),
        ],
        edges: const [],
      ),
    );

    expect(
      await router.canRoute(
        startLon: 11.0,
        startLat: 48.0,
        endLon: 11.001,
        endLat: 48.0,
      ),
      isTrue,
    );
    expect(
      await router.canRoute(
        startLon: 11.0,
        startLat: 48.0,
        endLon: 12.0,
        endLat: 48.0,
      ),
      isFalse,
    );
  });
}
