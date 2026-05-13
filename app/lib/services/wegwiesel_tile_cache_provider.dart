import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// flutter_map MapCachingProvider that stores tiles on disk so they remain
/// available offline. Uses a hash of the URL as filename so any tile server
/// works without baking style assumptions into the cache layout.
///
/// Total size is tracked in shared_prefs; when the configured limit is
/// exceeded, the oldest files (by mtime) are evicted in a 10% headroom
/// sweep.
class WegwieselTileCacheProvider implements MapCachingProvider {
  WegwieselTileCacheProvider._();
  static final WegwieselTileCacheProvider instance =
      WegwieselTileCacheProvider._();

  static const _sizeKey = 'tile_cache_size_bytes_v1';
  static const _limitKey = 'tile_cache_limit_mb_v1';
  static const int _defaultLimitMB = 500;

  Directory? _root;
  int? _cachedSizeBytes;
  bool _evictingNow = false;

  @override
  bool get isSupported => !kIsWeb;

  Future<Directory> _ensureRoot() async {
    if (_root != null) return _root!;
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory('${docs.path}/tile_cache');
    if (!root.existsSync()) {
      root.createSync(recursive: true);
    }
    _root = root;
    return root;
  }

  String _keyFor(String url) =>
      md5.convert(url.codeUnits).toString();

  Future<File> _fileFor(String url) async {
    final root = await _ensureRoot();
    final k = _keyFor(url);
    // Two-level directory split so we don't pile millions of files in
    // one folder.
    final sub = Directory('${root.path}/${k.substring(0, 2)}/${k.substring(2, 4)}');
    if (!sub.existsSync()) sub.createSync(recursive: true);
    return File('${sub.path}/$k.bin');
  }

  @override
  Future<CachedMapTile?> getTile(String url) async {
    if (!isSupported) return null;
    final file = await _fileFor(url);
    if (!file.existsSync()) return null;
    try {
      file.setLastModifiedSync(DateTime.now());
      final bytes = file.readAsBytesSync();
      // We never wrote real HTTP metadata; tell flutter_map the tile is
      // fresh for a week so it doesn't try to refetch on every render.
      return (
        bytes: bytes,
        metadata: CachedMapTileMetadata(
          staleAt: DateTime.now().add(const Duration(days: 7)),
          lastModified: file.lastModifiedSync(),
          etag: null,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata metadata,
    Uint8List? bytes,
  }) async {
    if (!isSupported || bytes == null || bytes.isEmpty) return;
    try {
      final file = await _fileFor(url);
      file.writeAsBytesSync(bytes);
      _cachedSizeBytes ??= await currentSizeBytes();
      _cachedSizeBytes = (_cachedSizeBytes ?? 0) + bytes.length;
      final p = await SharedPreferences.getInstance();
      await p.setInt(_sizeKey, _cachedSizeBytes!);
      _maybeEvict();
    } catch (_) {
      // best-effort
    }
  }

  Future<int> currentSizeBytes() async {
    if (!isSupported) return 0;
    final p = await SharedPreferences.getInstance();
    final stored = p.getInt(_sizeKey);
    if (stored != null) return stored;
    final root = await _ensureRoot();
    final total = _walkSize(root);
    await p.setInt(_sizeKey, total);
    _cachedSizeBytes = total;
    return total;
  }

  Future<int> limitMB() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_limitKey) ?? _defaultLimitMB;
  }

  Future<void> setLimitMB(int mb) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_limitKey, mb);
    _maybeEvict();
  }

  Future<void> clearAll() async {
    if (!isSupported) return;
    try {
      final root = await _ensureRoot();
      if (root.existsSync()) root.deleteSync(recursive: true);
      _cachedSizeBytes = 0;
      final p = await SharedPreferences.getInstance();
      await p.setInt(_sizeKey, 0);
    } catch (_) {
      // ignore
    }
  }

  void _maybeEvict() {
    if (_evictingNow) return;
    _evictingNow = true;
    Future.microtask(() async {
      try {
        final size = _cachedSizeBytes ?? await currentSizeBytes();
        final limit = (await limitMB()) * 1024 * 1024;
        if (size <= limit) return;
        await _evictOldestUntil(limit - (limit ~/ 10));
      } finally {
        _evictingNow = false;
      }
    });
  }

  Future<void> _evictOldestUntil(int targetBytes) async {
    if (!isSupported) return;
    final root = await _ensureRoot();
    final files = <File>[];
    _collectFiles(root, files);
    files.sort((a, b) {
      final amt = a.lastModifiedSync();
      final bmt = b.lastModifiedSync();
      return amt.compareTo(bmt);
    });
    int size = _cachedSizeBytes ?? await currentSizeBytes();
    for (final f in files) {
      if (size <= targetBytes) break;
      try {
        final len = f.lengthSync();
        f.deleteSync();
        size -= len;
      } catch (_) {}
    }
    _cachedSizeBytes = size < 0 ? 0 : size;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_sizeKey, _cachedSizeBytes!);
  }

  int _walkSize(Directory dir) {
    int total = 0;
    if (!dir.existsSync()) return 0;
    for (final f in dir.listSync(recursive: true)) {
      if (f is File) {
        try {
          total += f.lengthSync();
        } catch (_) {}
      }
    }
    return total;
  }

  void _collectFiles(Directory dir, List<File> out) {
    if (!dir.existsSync()) return;
    for (final f in dir.listSync(recursive: true)) {
      if (f is File) out.add(f);
    }
  }
}
