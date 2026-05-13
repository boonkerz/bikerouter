import 'dart:io';
import 'dart:typed_data';

import 'offline_router.dart';

/// First-pass reader for a BRouter `.rd5` segment file.
///
/// A segment covers one 5° × 5° tile, internally divided into a 32×32 grid
/// of sub-tiles. Each sub-tile is variable-length compressed Huffman bit-
/// stream of node and outgoing-way records.
///
/// This reader currently only parses the directory header (offset + length
/// per sub-tile). Sub-tile decoding (Huffman, node payload, way payload)
/// lands in a follow-up commit alongside the routing search.
///
/// File layout:
///   - 1024 × 8 byte directory entries (length, offset)
///   - Variable-length sub-tile blobs at the listed offsets
class Rd5Reader {
  /// Westernmost longitude of the 5° tile (multiple of 5).
  final int tileMinLon;

  /// Southernmost latitude of the 5° tile (multiple of 5).
  final int tileMinLat;
  final File file;
  final Uint8List _bytes;

  static const int subTilesPerSide = 32;
  static const int subTileCount = subTilesPerSide * subTilesPerSide;

  /// Per sub-tile (length in bytes, file offset).
  final List<SubTileEntry> directory;

  Rd5Reader._(
      {required this.tileMinLon,
      required this.tileMinLat,
      required this.file,
      required this.directory,
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
    final view = ByteData.sublistView(bytes, 0, subTileCount * 8);
    final directory = <SubTileEntry>[];
    for (int i = 0; i < subTileCount; i++) {
      final base = i * 8;
      final size = view.getUint32(base, Endian.big);
      final offset = view.getUint32(base + 4, Endian.big);
      directory.add(SubTileEntry(size: size, offset: offset));
    }
    return Rd5Reader._(
      tileMinLon: coords.minLon,
      tileMinLat: coords.minLat,
      file: f,
      directory: directory,
      bytes: bytes,
    );
  }

  /// Total file size — used by the offline-storage UI for reporting.
  int get totalBytes => _bytes.length;

  /// Count of sub-tiles that actually contain data (non-zero length).
  int get populatedSubTileCount =>
      directory.where((e) => e.size > 0).length;

  /// Returns the raw bytes for a sub-tile so the decoder commit can hook
  /// straight in. Caller is responsible for decompression.
  Uint8List rawSubTileBytes(int index) {
    final entry = directory[index];
    if (entry.size == 0) return Uint8List(0);
    return Uint8List.sublistView(_bytes, entry.offset, entry.offset + entry.size);
  }

  /// Translate a lon/lat into the matching sub-tile index, or null if it
  /// falls outside this segment.
  int? subTileIndexFor(double lon, double lat) {
    final dx = lon - tileMinLon;
    final dy = lat - tileMinLat;
    if (dx < 0 || dx >= 5 || dy < 0 || dy >= 5) return null;
    // Sub-tiles span 5/32 degrees ≈ 0.156°.
    final ix = (dx / (5.0 / subTilesPerSide)).floor();
    final iy = (dy / (5.0 / subTilesPerSide)).floor();
    // BRouter stores rows north-to-south so the on-disk index matches the
    // northwest corner being (0, 0).
    final row = subTilesPerSide - 1 - iy;
    return row * subTilesPerSide + ix;
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

class SubTileEntry {
  final int size;
  final int offset;
  const SubTileEntry({required this.size, required this.offset});
}

class _SegCoords {
  final int minLon;
  final int minLat;
  const _SegCoords({required this.minLon, required this.minLat});
}
