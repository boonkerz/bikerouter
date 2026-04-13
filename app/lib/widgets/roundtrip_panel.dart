import 'package:flutter/material.dart';
import '../models/profile.dart';

class RoundtripRequest {
  final bool useTime;
  final int distanceKm;
  final int timeMinutes;

  const RoundtripRequest({
    required this.useTime,
    required this.distanceKm,
    required this.timeMinutes,
  });
}

class RoundtripPanel extends StatefulWidget {
  final int distanceKm;
  final int direction;
  final bool hasStart;
  final String profile;
  final ValueChanged<int> onDistanceChanged;
  final ValueChanged<int> onDirectionChanged;
  final ValueChanged<RoundtripRequest> onGenerate;
  final ValueChanged<RoundtripRequest> onShuffle;

  const RoundtripPanel({
    super.key,
    required this.distanceKm,
    required this.direction,
    required this.hasStart,
    required this.profile,
    required this.onDistanceChanged,
    required this.onDirectionChanged,
    required this.onGenerate,
    required this.onShuffle,
  });

  @override
  State<RoundtripPanel> createState() => _RoundtripPanelState();
}

class _RoundtripPanelState extends State<RoundtripPanel> {
  bool _useTime = false;
  int _timeMinutes = 120; // 2h default

  int get _speed => BikeProfile.byId(widget.profile)?.avgSpeedKmh ?? 20;

  int get _computedDistanceKm {
    if (!_useTime) return widget.distanceKm;
    return (_timeMinutes / 60 * _speed).round();
  }

  RoundtripRequest get _request => RoundtripRequest(
    useTime: _useTime,
    distanceKm: _computedDistanceKm,
    timeMinutes: _timeMinutes,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toggle: Distance / Time
          Row(
            children: [
              _toggleChip('Distanz', !_useTime),
              const SizedBox(width: 8),
              _toggleChip('Zeit', _useTime),
            ],
          ),
          const SizedBox(height: 8),
          if (_useTime) ...[
            Text(
              _formatTime(_timeMinutes),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            Slider(
              value: _timeMinutes.toDouble(),
              min: 30,
              max: 480,
              divisions: 30,
              activeColor: const Color(0xFF4fc3f7),
              inactiveColor: Colors.white24,
              onChanged: (v) {
                setState(() => _timeMinutes = v.round());
                widget.onDistanceChanged(_computedDistanceKm);
              },
            ),
            Text(
              '~$_computedDistanceKm km bei ~$_speed km/h',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
            ),
          ] else ...[
            Text(
              'Distanz: ${widget.distanceKm} km',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            Slider(
              value: widget.distanceKm.toDouble(),
              min: 5,
              max: 200,
              divisions: 39,
              activeColor: const Color(0xFF4fc3f7),
              inactiveColor: Colors.white24,
              onChanged: (v) => widget.onDistanceChanged(v.round()),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Richtung: ${widget.direction}°',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Slider(
            value: widget.direction.toDouble(),
            min: 0,
            max: 350,
            divisions: 35,
            activeColor: const Color(0xFF4fc3f7),
            inactiveColor: Colors.white24,
            onChanged: (v) => widget.onDirectionChanged(v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final d in [('N', 0), ('O', 90), ('S', 180), ('W', 270)])
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  onPressed: () => widget.onDirectionChanged(d.$2),
                  child: Text(d.$1,
                      style: TextStyle(
                        color: widget.direction == d.$2
                            ? const Color(0xFF4fc3f7)
                            : Colors.white54,
                      )),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: widget.hasStart ? () => widget.onGenerate(_request) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4fc3f7),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              widget.hasStart ? 'Rundtour berechnen' : 'Startpunkt auf Karte tippen',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: widget.hasStart ? () => widget.onShuffle(_request) : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4fc3f7),
              side: const BorderSide(color: Color(0xFF4fc3f7)),
            ),
            child: const Text('Andere Variante'),
          ),
        ],
      ),
    );
  }

  Widget _toggleChip(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _useTime = label == 'Zeit'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4fc3f7).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? const Color(0xFF4fc3f7) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF4fc3f7) : Colors.white54,
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return 'Zeit: $m min';
    if (m == 0) return 'Zeit: ${h}h';
    return 'Zeit: ${h}h ${m}min';
  }
}
