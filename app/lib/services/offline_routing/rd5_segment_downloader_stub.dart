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

  Stream<Rd5SegmentDownloadProgress> get progress => const Stream.empty();
  bool get isRunning => false;

  void cancel() {}

  Future<StubDirectory> segmentsDirectory() async => const StubDirectory('');

  Future<List<StubSegmentFile>> localSegments() async => const [];

  Future<int> currentSizeBytes() async => 0;

  Future<void> clearAll() async {}

  Future<void> downloadBounds({
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
    String baseUrl = defaultBaseUrl,
    int parallel = 2,
  }) async {}

  Future<void> downloadFiles({
    required List<String> filenames,
    String baseUrl = defaultBaseUrl,
    int parallel = 2,
  }) async {}

  static List<String> segmentFilenamesForBounds({
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
  }) =>
      const [];
}

class StubDirectory {
  final String path;
  const StubDirectory(this.path);
}

class StubSegmentFile {
  Uri get uri => Uri();
}
