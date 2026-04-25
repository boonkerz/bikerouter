import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/profile_speed_prefs.dart';

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
  int _timeMinutes = 120;

  int get _speed => ProfileSpeedPrefs.speedFor(widget.profile);

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
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _toggleChip(l.roundtripDistance, !_useTime, false),
              const SizedBox(width: 8),
              _toggleChip(l.roundtripTime, _useTime, true),
            ],
          ),
          const SizedBox(height: 8),
          if (_useTime) ...[
            Text(
              _formatTime(l, _timeMinutes),
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
              l.roundtripApproxAt(_computedDistanceKm, _speed),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
            ),
          ] else ...[
            Text(
              l.roundtripDistanceLabel(widget.distanceKm),
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
            l.roundtripDirectionLabel(widget.direction),
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
              for (final d in [
                (l.roundtripCompassN, 0),
                (l.roundtripCompassE, 90),
                (l.roundtripCompassS, 180),
                (l.roundtripCompassW, 270),
              ])
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
              widget.hasStart ? l.roundtripGenerate : l.roundtripNeedStart,
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
            child: Text(l.roundtripAlternative),
          ),
        ],
      ),
    );
  }

  Widget _toggleChip(String label, bool active, bool isTime) {
    return GestureDetector(
      onTap: () => setState(() => _useTime = isTime),
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

  String _formatTime(AppLocalizations l, int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return l.roundtripTimeMinutes(m);
    if (m == 0) return l.roundtripTimeHours(h);
    return l.roundtripTimeHoursMinutes(h, m);
  }
}
