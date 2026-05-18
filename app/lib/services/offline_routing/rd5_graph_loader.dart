import 'dart:collection';
import 'dart:io';

import 'offline_routing_graph.dart';
import 'rd5_microcache_decoder.dart';
import 'rd5_reader.dart';
import 'rd5_segment_downloader.dart';

class Rd5GraphLoader {
  final Rd5SegmentDownloader downloader;
  // Decoded microcaches cached LRU-style. Re-planning a route a few km away
  // (the common case for tweaking start/end points) hits the same cells
  // again and decoding is by far the most expensive step here. 200 cells
  // covers ~200 × 12.5km × 12.5km ≈ Bayern in practice.
  static const _maxCacheEntries = 200;
  final LinkedHashMap<String, Rd5DecodedMicroCache> _cache =
      LinkedHashMap<String, Rd5DecodedMicroCache>();

  Rd5GraphLoader({Rd5SegmentDownloader? downloader})
      : downloader = downloader ?? Rd5SegmentDownloader.instance;

  /// Drops all cached decoded microcaches. Useful when the user clears the
  /// on-disk segments — stale entries would otherwise outlive the data.
  void clearCache() => _cache.clear();

  /// Number of decoded microcaches currently held in the LRU cache.
  /// Exposed for diagnostics / settings screens.
  int get cachedMicrocacheCount => _cache.length;

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
        final cacheKey = '$name:${cell.lonIdx}:${cell.latIdx}';
        final cached = _cache.remove(cacheKey);
        if (cached != null) {
          // Re-insert to move to MRU end.
          _cache[cacheKey] = cached;
          nodes.addAll(cached.nodes);
          edges.addAll(cached.edges);
          continue;
        }
        final bytes = reader.microCacheBytes(cell.lonIdx, cell.latIdx);
        if (bytes.isEmpty) continue;
        try {
          final decoded = Rd5MicroCacheDecoder(
            bytes: bytes,
            lonIdx: cell.lonIdx,
            latIdx: cell.latIdx,
            divisor: reader.divisor,
          ).decode();
          _cache[cacheKey] = decoded;
          if (_cache.length > _maxCacheEntries) {
            _cache.remove(_cache.keys.first);
          }
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
