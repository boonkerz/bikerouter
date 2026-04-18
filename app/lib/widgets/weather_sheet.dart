import 'dart:math';

import 'package:flutter/material.dart';

import '../services/weather_service.dart';

Future<void> showWeatherSheet(
  BuildContext context, {
  required List<List<double>> coordinates,
  required double avgSpeedKmh,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1a1a2e),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _WeatherSheet(
      coordinates: coordinates,
      avgSpeedKmh: avgSpeedKmh,
    ),
  );
}

class _WeatherSheet extends StatefulWidget {
  final List<List<double>> coordinates;
  final double avgSpeedKmh;

  const _WeatherSheet({
    required this.coordinates,
    required this.avgSpeedKmh,
  });

  @override
  State<_WeatherSheet> createState() => _WeatherSheetState();
}

class _WeatherSheetState extends State<_WeatherSheet> {
  DateTime _departure = _roundToNextHour(DateTime.now());
  List<WeatherSample>? _samples;
  bool _loading = false;
  String? _error;

  static DateTime _roundToNextHour(DateTime d) {
    final next = DateTime(d.year, d.month, d.day, d.hour).add(const Duration(hours: 1));
    return next;
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await WeatherService.forecastAlongRoute(
        coordinates: widget.coordinates,
        departure: _departure,
        avgSpeedKmh: widget.avgSpeedKmh,
      );
      if (!mounted) return;
      setState(() {
        _samples = s;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Wetter-Abruf fehlgeschlagen';
        _loading = false;
      });
    }
  }

  Future<void> _pickDeparture() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _departure,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 14)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF4fc3f7)),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departure),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF4fc3f7)),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (time == null) return;
    setState(() => _departure = DateTime(date.year, date.month, date.day, time.hour, time.minute));
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Padding(
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
                  const Text('Wetter entlang der Route',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.schedule, size: 16, color: Color(0xFF4fc3f7)),
                    label: Text(
                      _formatDeparture(_departure),
                      style: const TextStyle(color: Color(0xFF4fc3f7)),
                    ),
                    onPressed: _pickDeparture,
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 16),
              Expanded(child: _buildBody(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController sc) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4fc3f7)));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)));
    }
    final samples = _samples;
    if (samples == null || samples.isEmpty) {
      return const Center(
        child: Text('Keine Wetterdaten', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.separated(
      controller: sc,
      itemCount: samples.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
      itemBuilder: (ctx, i) => _row(samples[i]),
    );
  }

  Widget _row(WeatherSample s) {
    final time = '${s.eta.hour.toString().padLeft(2, '0')}:${s.eta.minute.toString().padLeft(2, '0')}';
    final temp = s.tempC == null ? '—' : '${s.tempC!.toStringAsFixed(0)}°C';
    final wind = s.windKmh == null ? '—' : '${s.windKmh!.round()} km/h';
    final rain = (s.precipMm ?? 0) > 0 ? '${s.precipMm!.toStringAsFixed(1)} mm' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.distanceKm.toStringAsFixed(0)} km',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(time, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(weatherCodeEmoji(s.weatherCode), style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          SizedBox(
            width: 54,
            child: Text(temp,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          if (s.windDirDeg != null)
            Transform.rotate(
              angle: (s.windDirDeg! + 180) * pi / 180, // arrow shows wind direction (where it's going toward)
              child: const Icon(Icons.arrow_upward, size: 18, color: Color(0xFF4fc3f7)),
            ),
          const SizedBox(width: 4),
          SizedBox(
            width: 64,
            child: Text(wind, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          if (rain.isNotEmpty)
            Text(rain, style: const TextStyle(color: Color(0xFF81D4FA), fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDeparture(DateTime d) {
    final today = DateTime.now();
    final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
    final tomorrow = today.add(const Duration(days: 1));
    final isTomorrow = d.year == tomorrow.year && d.month == tomorrow.month && d.day == tomorrow.day;
    final hm = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (isToday) return 'Heute $hm';
    if (isTomorrow) return 'Morgen $hm';
    return '${d.day}.${d.month}. $hm';
  }
}
