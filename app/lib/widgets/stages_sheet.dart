import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/solar_calc.dart';
import '../services/stage_planner.dart';
import '../services/weather_service.dart';

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
    backgroundColor: const Color(0xFFf5e9d8),
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
  // Start date for stage 1. Stage N runs on _startDate + (N-1) days. We
  // strip the time-of-day because the planner doesn't model intra-day
  // start times — sunrise/sunset are calendar-day values at the endpoint.
  DateTime _startDate = DateTime.now();
  // Per-stage weather sample. Populated lazily after stages load + when the
  // start date changes; keys are stage indices.
  final Map<int, WeatherSample?> _weather = {};
  bool _weatherLoading = false;
  // Per-stage suggested overnight POI (camp_site > alpine_hut > hostel >
  // hotel). Sentinel `null` value means "looked up, none found nearby" —
  // distinguished from "not yet looked up" via map containsKey.
  final Map<int, OvernightAnchor?> _overnight = {};

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
        _weather.clear();
        _overnight.clear();
      });
      _fetchWeather();
      _fetchOvernights();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// One Overpass call per stage endpoint, looking for the closest
  /// camp_site/alpine_hut/hostel/hotel. Only runs on multi-day plans —
  /// for a single-day route the destination is the user's own choice.
  Future<void> _fetchOvernights() async {
    final stages = _stages;
    if (stages == null || stages.length < 2) return;
    for (final s in stages) {
      // The final stage is the route's actual destination — don't suggest
      // a different overnight spot there.
      if (s.index == stages.length) continue;
      final anchor = await OvernightAnchorFinder.findNear(lat: s.lat, lon: s.lon);
      if (!mounted) return;
      setState(() => _overnight[s.index] = anchor);
    }
  }

  /// Pulls a weather sample per stage endpoint at noon on that stage's day.
  /// Only triggered for multi-day plans; single-day routes use the existing
  /// route-weather flow (called from the Wetter action on the map screen).
  Future<void> _fetchWeather() async {
    final stages = _stages;
    if (stages == null || stages.length < 2) return;
    if (_weatherLoading) return;
    setState(() => _weatherLoading = true);
    try {
      for (final s in stages) {
        final stageDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
        ).add(Duration(days: s.index - 1));
        final sample = await WeatherService.forecastForDay(
          lat: s.lat,
          lon: s.lon,
          date: stageDate,
        );
        if (!mounted) return;
        setState(() => _weather[s.index] = sample);
      }
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(l.stagesTitle,
                    style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(l.stagesTotalKm(widget.totalKm.toStringAsFixed(0)),
                    style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(l.stagesTargetLabel, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _targetKm,
                    min: 20,
                    max: 150,
                    divisions: 26,
                    label: '${_targetKm.round()} km',
                    activeColor: const Color(0xFF6a4a28),
                    onChanged: (v) => setState(() => _targetKm = v),
                    onChangeEnd: (_) => _fetch(),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text('${_targetKm.round()} km',
                      style: const TextStyle(color: Colors.black87, fontSize: 12)),
                ),
              ],
            ),
            // Start-date picker — only useful when the route splits into 2+
            // stages, otherwise sunset on day-1 is just for "today" anyway.
            if ((_stages?.length ?? 0) > 1) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(l.stagesStartDateLabel,
                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _pickStartDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6a4a28).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF6a4a28).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event, size: 14, color: Color(0xFF6a4a28)),
                            const SizedBox(width: 6),
                            Text(_formatDate(_startDate),
                                style: const TextStyle(color: Color(0xFF6a4a28), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const Divider(color: Colors.black26, height: 16),
            Expanded(child: _buildList(sc, l)),
            if (_stages != null && _stages!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(l.stagesShowOnMap),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6a4a28),
                    foregroundColor: const Color(0xFFf5e9d8),
                  ),
                  onPressed: () => Navigator.pop(context, StagesResult(_stages!, _targetKm)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ScrollController sc, AppLocalizations l) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6a4a28)));
    }
    final stages = _stages;
    if (stages == null || stages.isEmpty) {
      return Center(
        child: Text(l.stagesEmpty, style: const TextStyle(color: Colors.black54)),
      );
    }
    return ListView.separated(
      controller: sc,
      itemCount: stages.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.black12, height: 1),
      itemBuilder: (ctx, i) => _row(stages[i], l),
    );
  }

  Widget _row(Stage s, AppLocalizations l) {
    final title = s.townName ?? l.stagesDefault(s.index);
    final stageCount = _stages?.length ?? 0;
    final stageDate = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
    ).add(Duration(days: s.index - 1));
    final solar = SolarCalc.compute(lat: s.lat, lon: s.lon, date: stageDate);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF6a4a28),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('${s.index}',
                  style: const TextStyle(color: Color(0xFFf5e9d8), fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  l.stagesRowSummary(
                    s.lengthKm.toStringAsFixed(1),
                    s.ascentM.round(),
                    s.endKm.toStringAsFixed(0),
                  ),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                if (stageCount > 1) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (solar != null)
                        Text(
                          '🌅 ${_formatTime(solar.sunriseLocal)}  ·  🌇 ${_formatTime(solar.sunsetLocal)}',
                          style: const TextStyle(
                            color: Color(0xFF6a4a28),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (_weather.containsKey(s.index)) ...[
                        const SizedBox(width: 12),
                        _weatherChip(_weather[s.index]),
                      ],
                    ],
                  ),
                  if (_overnight[s.index] != null) ...[
                    const SizedBox(height: 4),
                    _overnightChip(_overnight[s.index]!),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        _weather.clear();
      });
      _fetchWeather();
    }
  }

  static String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _overnightChip(OvernightAnchor a) {
    final l = AppLocalizations.of(context);
    String icon;
    switch (a.type) {
      case 'camp_site':
        icon = '🏕️';
        break;
      case 'alpine_hut':
      case 'wilderness_hut':
        icon = '🏠';
        break;
      case 'hostel':
        icon = '🛏️';
        break;
      default:
        icon = '🏨';
    }
    final name = a.name ?? l.stagesOvernightUnnamed;
    final distKm = (a.distanceMeters / 1000).toStringAsFixed(1);
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$name · $distKm km',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black87, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _weatherChip(WeatherSample? w) {
    if (w == null) {
      // Date is beyond the 16-day forecast window — show a muted dash so
      // the row stays aligned and the user can see why it's empty.
      return const Text(
        '–',
        style: TextStyle(color: Colors.black38, fontSize: 12),
      );
    }
    final emoji = weatherCodeEmoji(w.weatherCode);
    final temp = w.tempC == null ? '' : ' ${w.tempC!.round()}°';
    return Text(
      '$emoji$temp',
      style: const TextStyle(color: Color(0xFF6a4a28), fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  static String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }
}
