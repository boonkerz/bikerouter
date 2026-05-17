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

  bool get _isOnFoot =>
      widget.profile == 'hiking-beta' || widget.profile == 'wegwiesel-running';
  bool get _isCar =>
      widget.profile == 'car' || widget.profile == 'car-trailer';

  // Slider geometry per category. Hiking/running realistically tops out around
  // a long day-tour (~50 km), so the bike-default 5..200 with 5-km steps is
  // far too coarse — at the short end you can't even pick a 5 km tour without
  // already being at the minimum. Car gets larger steps and a higher max.
  ({int min, int max, int div}) get _distanceConfig {
    if (_isOnFoot) return (min: 2, max: 50, div: 48);   // 1 km steps
    if (_isCar)    return (min: 10, max: 500, div: 49); // 10 km steps
    return (min: 5, max: 200, div: 39);                 // 5 km steps
  }

  ({int min, int max, int div}) get _timeConfig {
    return (min: 30, max: 480, div: 30);                // 15 min steps
  }

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
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            Builder(builder: (_) {
              final t = _timeConfig;
              return Slider(
                value: _timeMinutes.toDouble().clamp(t.min.toDouble(), t.max.toDouble()),
                min: t.min.toDouble(),
                max: t.max.toDouble(),
                divisions: t.div,
                activeColor: const Color(0xFF6a4a28),
                inactiveColor: Colors.black26,
                onChanged: (v) {
                  setState(() => _timeMinutes = v.round());
                  widget.onDistanceChanged(_computedDistanceKm);
                },
              );
            }),
            Text(
              l.roundtripApproxAt(_computedDistanceKm, _speed),
              style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 11),
            ),
          ] else ...[
            Text(
              l.roundtripDistanceLabel(widget.distanceKm),
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            Builder(builder: (_) {
              final d = _distanceConfig;
              return Slider(
                value: widget.distanceKm.toDouble().clamp(d.min.toDouble(), d.max.toDouble()),
                min: d.min.toDouble(),
                max: d.max.toDouble(),
                divisions: d.div,
                activeColor: const Color(0xFF6a4a28),
                inactiveColor: Colors.black26,
                onChanged: (v) => widget.onDistanceChanged(v.round()),
              );
            }),
          ],
          const SizedBox(height: 4),
          Text(
            l.roundtripDirectionLabel(widget.direction),
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          Slider(
            value: widget.direction.toDouble(),
            min: 0,
            max: 350,
            divisions: 35,
            activeColor: const Color(0xFF6a4a28),
            inactiveColor: Colors.black26,
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
                            ? const Color(0xFF6a4a28)
                            : Colors.black54,
                      )),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: widget.hasStart ? () => widget.onGenerate(_request) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6a4a28),
              foregroundColor: const Color(0xFFf5e9d8),
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
              foregroundColor: const Color(0xFF6a4a28),
              side: const BorderSide(color: Color(0xFF6a4a28)),
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
          color: active ? const Color(0xFF6a4a28).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? const Color(0xFF6a4a28) : Colors.black26,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF6a4a28) : Colors.black54,
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
