import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../l10n/app_localizations.dart';
import '../models/map_style.dart';
import '../services/region_downloader.dart';
import '../services/wegwiesel_tile_cache_provider.dart';

class OfflineMapsScreen extends StatefulWidget {
  final MapStyle initialStyle;
  final LatLngBounds? initialViewport;

  const OfflineMapsScreen({
    super.key,
    required this.initialStyle,
    this.initialViewport,
  });

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  int _cacheBytes = 0;
  int _limitMB = 500;
  RegionDownloadProgress? _progress;
  StreamSubscription<RegionDownloadProgress>? _progressSub;

  @override
  void initState() {
    super.initState();
    _refresh();
    _progressSub = RegionDownloader.instance.progress.listen((p) {
      if (mounted) setState(() => _progress = p);
    });
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final bytes = await WegwieselTileCacheProvider.instance.currentSizeBytes();
    final limit = await WegwieselTileCacheProvider.instance.limitMB();
    if (!mounted) return;
    setState(() {
      _cacheBytes = bytes;
      _limitMB = limit;
    });
  }

  Future<void> _downloadCurrent() async {
    final l = AppLocalizations.of(context);
    final bounds = widget.initialViewport;
    if (bounds == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.offlineMapsNoViewport)),
      );
      return;
    }
    final estimateBytes = estimateRegionBytes(
      minLat: bounds.southWest.latitude,
      minLon: bounds.southWest.longitude,
      maxLat: bounds.northEast.latitude,
      maxLon: bounds.northEast.longitude,
    );
    final estMB = (estimateBytes / (1024 * 1024)).round();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.offlineMapsConfirmTitle),
        content: Text(l.offlineMapsConfirmBody(estMB)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.urlImportCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.offlineMapsStart),
          ),
        ],
      ),
    );
    if (ok != true) return;
    unawaited(RegionDownloader.instance.download(
      style: widget.initialStyle,
      minLat: bounds.southWest.latitude,
      minLon: bounds.southWest.longitude,
      maxLat: bounds.northEast.latitude,
      maxLon: bounds.northEast.longitude,
    ));
    setState(() {
      _progress = const RegionDownloadProgress(
          done: 0, total: 1, finished: false);
    });
  }

  Future<void> _clearAll() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.offlineMapsClearTitle),
        content: Text(l.offlineMapsClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.urlImportCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.recordedRideDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await WegwieselTileCacheProvider.instance.clearAll();
    await _refresh();
  }

  Future<void> _editLimit() async {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: _limitMB.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.offlineMapsLimit),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffix: Text('MB')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.urlImportCancel),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v >= 50 && v <= 10000) {
                Navigator.of(ctx).pop(v);
              }
            },
            child: Text(l.recordingSave),
          ),
        ],
      ),
    );
    if (result != null) {
      await WegwieselTileCacheProvider.instance.setLimitMB(result);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFebd9bd),
      appBar: AppBar(
        backgroundColor: const Color(0xFFf5e9d8),
        foregroundColor: Colors.black87,
        title: Text(l.offlineMapsTitle),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _section(l.offlineMapsCurrentSection),
          _tile(
            icon: Icons.storage_outlined,
            title: l.offlineMapsUsed,
            subtitle:
                '${(_cacheBytes / (1024 * 1024)).toStringAsFixed(1)} MB / $_limitMB MB',
            onTap: null,
          ),
          _tile(
            icon: Icons.tune,
            title: l.offlineMapsLimit,
            subtitle: '$_limitMB MB',
            onTap: _editLimit,
          ),
          _tile(
            icon: Icons.delete_sweep_outlined,
            title: l.offlineMapsClearTitle,
            subtitle: l.offlineMapsClearSubtitle,
            onTap: _clearAll,
          ),
          if (_progress != null) ...[
            _section(l.offlineMapsProgressSection),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _progress!.finished
                        ? l.offlineMapsProgressDone(_progress!.total)
                        : l.offlineMapsProgressLine(_progress!.done, _progress!.total),
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progress!.total > 0
                        ? _progress!.done / _progress!.total
                        : 0,
                    color: const Color(0xFF6a4a28),
                    backgroundColor: Colors.black12,
                  ),
                ],
              ),
            ),
          ],
          _section(l.offlineMapsDownloadSection),
          _tile(
            icon: Icons.cloud_download_outlined,
            title: l.offlineMapsDownloadCurrent,
            subtitle: l.offlineMapsDownloadCurrentSub,
            onTap: RegionDownloader.instance.isRunning ? null : _downloadCurrent,
          ),
        ],
      ),
    );
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF6a4a28),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) =>
      ListTile(
        leading: Icon(icon, color: const Color(0xFF6a4a28)),
        title: Text(title, style: const TextStyle(color: Colors.black87)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 12))
            : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: Colors.black38)
            : null,
        onTap: onTap,
      );
}
