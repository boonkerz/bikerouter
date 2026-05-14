import '../brouter_service.dart';
import 'rd5_offline_router.dart';
import 'rd5_segment_downloader.dart';

class OfflineRoutingBootstrap {
  static Future<void> initialize() async {
    final segments = await Rd5SegmentDownloader.instance.localSegments();
    if (segments.isNotEmpty) {
      BRouterService.offlineRouter = Rd5OfflineRouter();
    }
  }
}
