import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class Rd5SegmentDownloadProgress {
  final int done;
  final int total;
  final String? currentFile;
  final bool finished;
  final String? error;

  const Rd5SegmentDownloadProgress({
    required this.done,
    required this.total,
    this.currentFile,
    required this.finished,
    this.error,
  });
}

class Rd5SegmentDownloader {
  Rd5SegmentDownloader._();
  static final Rd5SegmentDownloader instance = Rd5SegmentDownloader._();

  static const defaultBaseUrl = 'https://wegwiesel.app/segments';

  bool _running = false;
  bool _cancelled = false;
  final _progress = StreamController<Rd5SegmentDownloadProgress>.broadcast();

  Stream<Rd5SegmentDownloadProgress> get progress => _progress.stream;
  bool get isRunning => _running;

  void cancel() {
    _cancelled = true;
  }

  Future<Directory> segmentsDirectory() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/offline_routing/segments');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<File>> localSegments() async {
    final dir = await segmentsDirectory();
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.rd5'))
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  Future<int> currentSizeBytes() async {
    var total = 0;
    for (final file in await localSegments()) {
      total += await file.length();
    }
    return total;
  }

  Future<void> clearAll() async {
    final dir = await segmentsDirectory();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> downloadBounds({
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
    String baseUrl = defaultBaseUrl,
    int parallel = 2,
  }) async {
    final filenames = segmentFilenamesForBounds(
      minLat: minLat,
      minLon: minLon,
      maxLat: maxLat,
      maxLon: maxLon,
    );
    await downloadFiles(
      filenames: filenames,
      baseUrl: baseUrl,
      parallel: parallel,
    );
  }

  Future<void> downloadFiles({
    required List<String> filenames,
    String baseUrl = defaultBaseUrl,
    int parallel = 2,
  }) async {
    if (_running) return;
    _running = true;
    _cancelled = false;

    final dir = await segmentsDirectory();
    var done = 0;
    final total = filenames.length;
    _progress.add(Rd5SegmentDownloadProgress(
      done: 0,
      total: total,
      finished: total == 0,
    ));

    Future<void> worker(int start) async {
      for (var i = start; i < filenames.length; i += parallel) {
        if (_cancelled) return;
        final name = filenames[i];
        _progress.add(Rd5SegmentDownloadProgress(
          done: done,
          total: total,
          currentFile: name,
          finished: false,
        ));
        try {
          await _downloadOne(
            name: name,
            target: File('${dir.path}/$name'),
            url: Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/$name'),
          );
        } catch (e) {
          _progress.add(Rd5SegmentDownloadProgress(
            done: done,
            total: total,
            currentFile: name,
            finished: false,
            error: e.toString(),
          ));
        }
        done++;
        _progress.add(Rd5SegmentDownloadProgress(
          done: done,
          total: total,
          currentFile: name,
          finished: done == total,
        ));
      }
    }

    try {
      await Future.wait([
        for (var p = 0; p < parallel; p++) worker(p),
      ]);
    } finally {
      _running = false;
      _progress.add(Rd5SegmentDownloadProgress(
        done: done,
        total: total,
        finished: true,
      ));
    }
  }

  Future<void> _downloadOne({
    required String name,
    required File target,
    required Uri url,
  }) async {
    if (await target.exists() && await target.length() > 0) return;

    final response = await http.get(
      url,
      headers: const {'User-Agent': 'Wegwiesel/2.0 (wegwiesel.app)'},
    ).timeout(const Duration(seconds: 60));
    if (response.statusCode == 404) {
      return;
    }
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw HttpException(
        'failed to download $name: HTTP ${response.statusCode}',
        uri: url,
      );
    }

    final part = File('${target.path}.part');
    await part.writeAsBytes(response.bodyBytes, flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await part.rename(target.path);
  }

  static List<String> segmentFilenamesForBounds({
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
  }) {
    final south = min(minLat, maxLat).clamp(-90.0, 90.0);
    final north = max(minLat, maxLat).clamp(-90.0, 90.0);
    final west = min(minLon, maxLon).clamp(-180.0, 180.0);
    final east = max(minLon, maxLon).clamp(-180.0, 180.0);

    final minTileLon = _tileMin(west);
    final maxTileLon = _tileMin(_inclusiveUpper(east, west));
    final minTileLat = _tileMin(south);
    final maxTileLat = _tileMin(_inclusiveUpper(north, south));

    final names = <String>[];
    for (var lon = minTileLon; lon <= maxTileLon; lon += 5) {
      for (var lat = minTileLat; lat <= maxTileLat; lat += 5) {
        names.add('${_lonName(lon)}_${_latName(lat)}.rd5');
      }
    }
    names.sort();
    return names;
  }

  static double _inclusiveUpper(double upper, double lower) {
    if (upper > lower && upper % 5 == 0) {
      return upper - 0.0000001;
    }
    return upper;
  }

  static int _tileMin(double value) => (value / 5).floor() * 5;

  static String _lonName(int lon) => lon >= 0 ? 'E$lon' : 'W${-lon}';

  static String _latName(int lat) => lat >= 0 ? 'N$lat' : 'S${-lat}';
}
