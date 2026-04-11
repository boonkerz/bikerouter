import 'package:flutter/material.dart';

class RoundtripPanel extends StatefulWidget {
  final int distanceKm;
  final int direction;
  final bool hasStart;
  final ValueChanged<int> onDistanceChanged;
  final ValueChanged<int> onDirectionChanged;
  final VoidCallback onGenerate;
  final VoidCallback onShuffle;

  const RoundtripPanel({
    super.key,
    required this.distanceKm,
    required this.direction,
    required this.hasStart,
    required this.onDistanceChanged,
    required this.onDirectionChanged,
    required this.onGenerate,
    required this.onShuffle,
  });

  @override
  State<RoundtripPanel> createState() => _RoundtripPanelState();
}

class _RoundtripPanelState extends State<RoundtripPanel> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            onPressed: widget.hasStart ? widget.onGenerate : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4fc3f7),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Rundtour berechnen', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: widget.hasStart ? widget.onShuffle : null,
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
}
