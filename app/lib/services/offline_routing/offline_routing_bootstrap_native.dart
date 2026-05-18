import 'package:flutter/services.dart' show rootBundle;

import '../brouter_service.dart';
import 'lookups.dart';
import 'rd5_offline_router.dart';
import 'rd5_segment_downloader.dart';

class OfflineRoutingBootstrap {
  static const _lookupsAsset = 'assets/offline_routing/lookups.dat';

  static Future<void> initialize() async {
    final segments = await Rd5SegmentDownloader.instance.localSegments();
    if (segments.isEmpty) return;

    final lookups = await _loadLookups();
    BRouterService.offlineRouter = Rd5OfflineRouter(lookups: lookups);
  }

  static Future<Lookups?> _loadLookups() async {
    try {
      final data = await rootBundle.load(_lookupsAsset);
      return Lookups.parse(data.buffer.asUint8List());
    } catch (_) {
      // Missing or malformed asset → fall back to the placeholder tag map
      // (offline router still works, just without per-tag costing).
      return null;
    }
  }
}
