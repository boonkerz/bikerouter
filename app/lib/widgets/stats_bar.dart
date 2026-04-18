import 'package:flutter/material.dart';
import '../models/route_result.dart';

class StatsAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool loading;

  const StatsAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.loading = false,
  });
}

class StatsBar extends StatelessWidget {
  final RouteResult route;
  final List<StatsAction> actions;

  const StatsBar({super.key, required this.route, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final hours = (route.time / 3600).floor();
    final minutes = ((route.time % 3600) / 60).round();
    final timeStr = hours > 0 ? '${hours}h ${minutes}min' : '$minutes min';
    final distStr = route.distance < 10
        ? '${route.distance.toStringAsFixed(1)} km'
        : '${route.distance.round()} km';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(label: 'Distanz', value: distStr),
                _Stat(label: 'Anstieg', value: '${route.ascent.round()} m'),
                _Stat(label: 'Abstieg', value: '${route.descent.round()} m'),
                _Stat(label: 'Zeit', value: timeStr),
              ],
            ),
          ),
          if (actions.isNotEmpty)
            Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    for (final a in actions) _ActionIcon(action: a),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final StatsAction action;

  const _ActionIcon({required this.action});

  @override
  Widget build(BuildContext context) {
    final color = action.active ? Colors.black : const Color(0xFF4fc3f7);
    final bg = action.active ? const Color(0xFF4fc3f7) : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: action.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  action.loading ? Icons.hourglass_top : action.icon,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  action.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: action.active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF4fc3f7),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
