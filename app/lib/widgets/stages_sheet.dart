import 'package:flutter/material.dart';

import '../services/stage_planner.dart';

class StagesResult {
  final List<Stage> stages;
  final double targetKm;
  StagesResult(this.stages, this.targetKm);
}

Future<StagesResult?> showStagesSheet(
  BuildContext context, {
  required List<List<double>> coordinates,
  required double totalDistanceKm,
}) {
  return showModalBottomSheet<StagesResult>(
    context: context,
    backgroundColor: const Color(0xFF1a1a2e),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _Sheet(
      coordinates: coordinates,
      totalKm: totalDistanceKm,
    ),
  );
}

class _Sheet extends StatefulWidget {
  final List<List<double>> coordinates;
  final double totalKm;

  const _Sheet({required this.coordinates, required this.totalKm});

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  double _targetKm = 60;
  List<Stage>? _stages;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Default target: aim for roughly whole-day stages.
    final suggested = (widget.totalKm / 3).clamp(30.0, 120.0);
    _targetKm = (suggested / 10).round() * 10.0;
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final s = await StagePlanner.plan(
        coordinates: widget.coordinates,
        targetKm: _targetKm,
      );
      if (!mounted) return;
      setState(() {
        _stages = s;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, sc) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Etappenplaner',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${widget.totalKm.toStringAsFixed(0)} km gesamt',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Tagesziel', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _targetKm,
                    min: 20,
                    max: 150,
                    divisions: 26,
                    label: '${_targetKm.round()} km',
                    activeColor: const Color(0xFF4fc3f7),
                    onChanged: (v) => setState(() => _targetKm = v),
                    onChangeEnd: (_) => _fetch(),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text('${_targetKm.round()} km',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 16),
            Expanded(child: _buildList(sc)),
            if (_stages != null && _stages!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Etappen auf Karte zeigen'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4fc3f7)),
                  onPressed: () => Navigator.pop(context, StagesResult(_stages!, _targetKm)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ScrollController sc) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4fc3f7)));
    }
    final stages = _stages;
    if (stages == null || stages.isEmpty) {
      return const Center(
        child: Text('Keine Etappen', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.separated(
      controller: sc,
      itemCount: stages.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
      itemBuilder: (ctx, i) => _row(stages[i]),
    );
  }

  Widget _row(Stage s) {
    final title = s.townName ?? 'Etappe ${s.index}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF4fc3f7),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('${s.index}',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${s.lengthKm.toStringAsFixed(1)} km · ${s.ascentM.round()} hm · bis ${s.endKm.toStringAsFixed(0)} km',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
