import 'dart:io';

import 'offline_routing_graph.dart';
import 'rd5_microcache_decoder.dart';
import 'rd5_reader.dart';
import 'rd5_segment_downloader.dart';

class Rd5GraphLoader {
  final Rd5SegmentDownloader downloader;

  Rd5GraphLoader({Rd5SegmentDownloader? downloader})
      : downloader = downloader ?? Rd5SegmentDownloader.instance;

  Future<OfflineRoutingGraph> loadBounds({
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
  }) async {
    final dir = await downloader.segmentsDirectory();
    final filenames = Rd5SegmentDownloader.segmentFilenamesForBounds(
      minLat: minLat,
      minLon: minLon,
      maxLat: maxLat,
      maxLon: maxLon,
    );
    final nodes = <OfflineRoutingNode>[];
    final edges = <OfflineRoutingEdge>[];

    for (final name in filenames) {
      final file = File('${dir.path}/$name');
      if (!await file.exists()) continue;
      final reader = Rd5Reader.open(file);
      for (final cell in reader.microCacheIndicesForBounds(
        minLat: minLat,
        minLon: minLon,
        maxLat: maxLat,
        maxLon: maxLon,
      )) {
        final bytes = reader.microCacheBytes(cell.lonIdx, cell.latIdx);
        if (bytes.isEmpty) continue;
        try {
          final decoded = Rd5MicroCacheDecoder(
            bytes: bytes,
            lonIdx: cell.lonIdx,
            latIdx: cell.latIdx,
            divisor: reader.divisor,
          ).decode();
          nodes.addAll(decoded.nodes);
          edges.addAll(decoded.edges);
        } catch (_) {
          // Segment files may contain cells outside the currently supported
          // decoder subset. Keep loading neighbouring cells.
        }
      }
    }

    return OfflineRoutingGraph(nodes: nodes, edges: edges);
  }
}
