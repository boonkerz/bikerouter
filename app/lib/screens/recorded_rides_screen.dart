import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/recorded_ride.dart';
import '../services/gpx_export.dart';
import '../services/ride_storage.dart';

class RecordedRidesScreen extends StatefulWidget {
  const RecordedRidesScreen({super.key});

  @override
  State<RecordedRidesScreen> createState() => _RecordedRidesScreenState();
}

class _RecordedRidesScreenState extends State<RecordedRidesScreen> {
  List<RecordedRide> _rides = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rides = await RideStorage.loadAll();
    if (!mounted) return;
    setState(() {
      _rides = rides;
      _loading = false;
    });
  }

  Future<void> _delete(RecordedRide ride) async {
    await RideStorage.delete(ride.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFebd9bd),
      appBar: AppBar(
        backgroundColor: const Color(0xFFf5e9d8),
        foregroundColor: Colors.black87,
        title: Text(l.recordedRidesTitle),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rides.isEmpty
              ? Center(
                  child: Text(l.recordedRidesEmpty,
                      style: const TextStyle(color: Colors.black54)),
                )
              : ListView.separated(
                  itemCount: _rides.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Colors.black12),
                  itemBuilder: (ctx, i) {
                    final r = _rides[i];
                    final n = r.startedAt;
                    final date =
                        '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFc62828),
                        child: Icon(Icons.directions_bike, color: Colors.white),
                      ),
                      title: Text(r.name),
                      subtitle: Text(
                          '$date  ·  ${r.distanceKm.toStringAsFixed(1)} km  ·  ${_fmtDuration(Duration(seconds: r.movingSeconds))}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'share') {
                            await exportGpxFile('${r.id}.gpx', r.toGpx());
                          } else if (v == 'delete') {
                            await _delete(r);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'share',
                            child: Row(children: [
                              const Icon(Icons.share, size: 18),
                              const SizedBox(width: 12),
                              Text(l.recordingExportGpx),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              const SizedBox(width: 12),
                              Text(l.recordedRideDelete,
                                  style: const TextStyle(color: Colors.redAccent)),
                            ]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
