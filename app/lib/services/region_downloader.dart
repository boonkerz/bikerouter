import 'dart:async';
import 'dart:math';

import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import '../models/map_style.dart';
import 'wegwiesel_tile_cache_provider.dart';

class RegionDownloadProgress {
  final int done;
  final int total;
  final bool finished;
  final String? error;

  const RegionDownloadProgress({
    required this.done,
    required this.total,
    required this.finished,
    this.error,
  });
}

/// Pre-downloads raster tiles for a rectangular region across a zoom range
/// and stuffs them into [WegwieselTileCacheProvider]. The TileLayer that
/// renders the same style during offline use will then read from disk.
class RegionDownloader {
  RegionDownloader._();
  static final RegionDownloader instance = RegionDownloader._();

  bool _running = false;
  bool _cancelled = false;
  final _progress = StreamController<RegionDownloadProgress>.broadcast();

  Stream<RegionDownloadProgress> get progress => _progress.stream;
  bool get isRunning => _running;

  void cancel() {
    _cancelled = true;
  }

  /// Iterate every tile (z,x,y) inside the bounding box across [minZoom,
  /// maxZoom], fetch via HTTP, and hand the bytes off to the cache. Runs in
  /// the foreground; the caller should keep the screen open. Future
  /// completes when all tiles done (or cancel was hit).
  Future<void> download({
    required MapStyle style,
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
    int minZoom = 8,
    int maxZoom = 15,
    int parallel = 6,
  }) async {
    if (_running) return;
    _running = true;
    _cancelled = false;

    // Round zooms into the style's allowed range.
    if (maxZoom > style.maxZoom) maxZoom = style.maxZoom;

    final coords = <_TileCoord>[];
    for (int z = minZoom; z <= maxZoom; z++) {
      final n = 1 << z;
      final xMin = _lonToTileX(minLon, z).clamp(0, n - 1);
      final xMax = _lonToTileX(maxLon, z).clamp(0, n - 1);
      final yMin = _latToTileY(maxLat, z).clamp(0, n - 1);
      final yMax = _latToTileY(minLat, z).clamp(0, n - 1);
      for (int x = xMin; x <= xMax; x++) {
        for (int y = yMin; y <= yMax; y++) {
          coords.add(_TileCoord(z, x, y));
        }
      }
    }

    final total = coords.length;
    int done = 0;
    final tpl = style.urlTemplate;
    final cache = WegwieselTileCacheProvider.instance;

    _progress.add(RegionDownloadProgress(done: 0, total: total, finished: false));

    Future<void> worker(int start) async {
      for (int i = start; i < coords.length; i += parallel) {
        if (_cancelled) return;
        final c = coords[i];
        final url = _expandTemplate(tpl, c);
        try {
          // Skip if we already have it.
          final hit = await cache.getTile(url);
          if (hit == null) {
            final res = await http.get(
              Uri.parse(url),
              headers: const {'User-Agent': 'Wegwiesel/2.0 (wegwiesel.app)'},
            ).timeout(const Duration(seconds: 15));
            if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
              await cache.putTile(
                url: url,
                metadata: CachedMapTileMetadata(
                  staleAt: DateTime.now().add(const Duration(days: 30)),
                  lastModified: DateTime.now(),
                  etag: null,
                ),
                bytes: res.bodyBytes,
              );
            }
          }
        } catch (_) {
          // Skip on error, continue with next tile.
        }
        done++;
        // Throttle progress events so the UI doesn't redraw 10k times.
        if (done % 25 == 0 || done == total) {
          _progress.add(RegionDownloadProgress(
              done: done, total: total, finished: done == total));
        }
      }
    }

    try {
      await Future.wait([for (int p = 0; p < parallel; p++) worker(p)]);
    } finally {
      _running = false;
      _progress.add(RegionDownloadProgress(
          done: done, total: total, finished: true));
    }
  }

  static String _expandTemplate(String tpl, _TileCoord c) {
    return tpl
        .replaceAll('{z}', '${c.z}')
        .replaceAll('{x}', '${c.x}')
        .replaceAll('{y}', '${c.y}')
        .replaceAll('{r}', '');
  }

  static int _lonToTileX(double lon, int z) {
    final n = 1 << z;
    return ((lon + 180) / 360 * n).floor();
  }

  static int _latToTileY(double lat, int z) {
    final n = 1 << z;
    final rad = lat * pi / 180;
    return ((1 - log(tan(rad) + 1 / cos(rad)) / pi) / 2 * n).floor();
  }
}

class _TileCoord {
  final int z;
  final int x;
  final int y;
  _TileCoord(this.z, this.x, this.y);
}

/// Rough byte-count estimate so the UI can warn before a multi-GB
/// download. Each tile ≈ 18 KB average for OSM raster.
int estimateRegionBytes({
  required double minLat,
  required double minLon,
  required double maxLat,
  required double maxLon,
  int minZoom = 8,
  int maxZoom = 15,
}) {
  int tiles = 0;
  for (int z = minZoom; z <= maxZoom; z++) {
    final n = 1 << z;
    final xMin = RegionDownloader._lonToTileX(minLon, z).clamp(0, n - 1);
    final xMax = RegionDownloader._lonToTileX(maxLon, z).clamp(0, n - 1);
    final yMin = RegionDownloader._latToTileY(maxLat, z).clamp(0, n - 1);
    final yMax = RegionDownloader._latToTileY(minLat, z).clamp(0, n - 1);
    tiles += (xMax - xMin + 1) * (yMax - yMin + 1);
  }
  return tiles * 18 * 1024;
}
