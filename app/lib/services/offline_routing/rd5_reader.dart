import 'dart:io';
import 'dart:typed_data';

import 'offline_router.dart';

/// First-pass reader for a BRouter `.rd5` segment file.
///
/// A segment covers one 5° × 5° tile. BRouter stores a 25-entry top index
/// for the one-degree squares first, then a per-degree micro-cache index.
class Rd5Reader {
  /// Westernmost longitude of the 5° tile (multiple of 5).
  final int tileMinLon;

  /// Southernmost latitude of the 5° tile (multiple of 5).
  final int tileMinLat;
  final File file;
  final Uint8List _bytes;

  static const int topIndexBytes = 200;

  /// New `segments4` files use 32 micro-caches per degree. Older files used
  /// 80; the app downloads current segments4 data, so 32 is the supported
  /// MVP path.
  final int divisor;
  final List<int> fileIndex;

  Rd5Reader._(
      {required this.tileMinLon,
      required this.tileMinLat,
      required this.file,
      required this.divisor,
      required this.fileIndex,
      required Uint8List bytes})
      : _bytes = bytes;

  /// Open a segment file given the standard naming convention:
  /// `E<lon>_N<lat>.rd5` for positive lon/lat, `W` / `S` for negative.
  static Rd5Reader open(File f) {
    final bytes = f.readAsBytesSync();
    final name = f.uri.pathSegments.last;
    final coords = _parseFilename(name);
    if (coords == null) {
      throw OfflineRoutingException(
          'bad_name', 'unrecognised segment filename: $name');
    }
    final view = ByteData.sublistView(bytes, 0, topIndexBytes);
    final fileIndex = <int>[];
    for (var i = 0; i < 25; i++) {
      final value = view.getUint64(i * 8, Endian.big);
      fileIndex.add(value & 0xffffffffffff);
    }
    return Rd5Reader._(
      tileMinLon: coords.minLon,
      tileMinLat: coords.minLat,
      file: f,
      divisor: 32,
      fileIndex: fileIndex,
      bytes: bytes,
    );
  }

  /// Total file size — used by the offline-storage UI for reporting.
  int get totalBytes => _bytes.length;

  /// Count of sub-tiles that actually contain data (non-zero length).
  int get populatedSubTileCount => fileIndex.where((e) => e > 0).length;

  Uint8List microCacheBytes(int lonIdx, int latIdx) {
    final lonDegree = lonIdx ~/ divisor;
    final latDegree = latIdx ~/ divisor;
    final lonMod5 = lonDegree % 5;
    final latMod5 = latDegree % 5;
    final tileIndex = lonMod5 * 5 + latMod5;
    if (tileIndex < 0 || tileIndex >= 25) return Uint8List(0);
    final fileOffset = tileIndex > 0 ? fileIndex[tileIndex - 1] : topIndexBytes;
    final nextOffset = fileIndex[tileIndex];
    if (fileOffset == nextOffset || nextOffset <= fileOffset) {
      return Uint8List(0);
    }

    final indexSize = divisor * divisor * 4;
    if (fileOffset + indexSize > _bytes.length) return Uint8List(0);
    final subIdx = (latIdx - divisor * latDegree) * divisor +
        (lonIdx - divisor * lonDegree);
    if (subIdx < 0 || subIdx >= divisor * divisor) return Uint8List(0);
    final indexView = ByteData.sublistView(
      _bytes,
      fileOffset,
      fileOffset + indexSize,
    );
    final start =
        subIdx == 0 ? indexSize : indexView.getUint32((subIdx - 1) * 4);
    final end = indexView.getUint32(subIdx * 4);
    if (end <= start) return Uint8List(0);
    final dataStart = fileOffset + start;
    final dataEnd = fileOffset + end;
    if (dataStart < 0 || dataEnd > _bytes.length || dataEnd <= dataStart) {
      return Uint8List(0);
    }
    return Uint8List.sublistView(_bytes, dataStart, dataEnd);
  }

  Iterable<Rd5MicroCacheIndex> microCacheIndicesForBounds({
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
  }) sync* {
    final west = minLon < maxLon ? minLon : maxLon;
    final east = minLon < maxLon ? maxLon : minLon;
    final south = minLat < maxLat ? minLat : maxLat;
    final north = minLat < maxLat ? maxLat : minLat;
    final lonStart = _microCacheIndex(west + 180.0, divisor);
    final lonEnd =
        _microCacheIndex(_inclusiveUpper(east, west, divisor) + 180.0, divisor);
    final latStart = _microCacheIndex(south + 90.0, divisor);
    final latEnd = _microCacheIndex(
        _inclusiveUpper(north, south, divisor) + 90.0, divisor);
    final minLonIdx = (tileMinLon + 180) * divisor;
    final maxLonIdx = (tileMinLon + 185) * divisor - 1;
    final minLatIdx = (tileMinLat + 90) * divisor;
    final maxLatIdx = (tileMinLat + 95) * divisor - 1;

    for (var lonIdx = lonStart; lonIdx <= lonEnd; lonIdx++) {
      if (lonIdx < minLonIdx || lonIdx > maxLonIdx) continue;
      for (var latIdx = latStart; latIdx <= latEnd; latIdx++) {
        if (latIdx < minLatIdx || latIdx > maxLatIdx) continue;
        yield Rd5MicroCacheIndex(lonIdx, latIdx);
      }
    }
  }

  static int _microCacheIndex(double shiftedDegrees, int divisor) =>
      (shiftedDegrees * divisor).floor();

  static double _inclusiveUpper(double upper, double lower, int divisor) {
    final scaled = upper * divisor;
    if (upper > lower && (scaled - scaled.round()).abs() < 0.0000001) {
      return upper - 0.0000001;
    }
    return upper;
  }

  static _SegCoords? _parseFilename(String name) {
    // Examples: E5_N50.rd5, W10_N45.rd5, E15_S05.rd5
    final m = RegExp(r'^([EW])(\d+)_([NS])(\d+)\.rd5$').firstMatch(name);
    if (m == null) return null;
    final lon = int.parse(m.group(2)!) * (m.group(1) == 'E' ? 1 : -1);
    final lat = int.parse(m.group(4)!) * (m.group(3) == 'N' ? 1 : -1);
    return _SegCoords(minLon: lon, minLat: lat);
  }
}

class Rd5MicroCacheIndex {
  final int lonIdx;
  final int latIdx;
  const Rd5MicroCacheIndex(this.lonIdx, this.latIdx);
}

class _SegCoords {
  final int minLon;
  final int minLat;
  const _SegCoords({required this.minLon, required this.minLat});
}
