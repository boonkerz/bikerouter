import 'package:flutter/material.dart';
import '../models/route_result.dart';

class StatsBar extends StatelessWidget {
  final RouteResult route;

  const StatsBar({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final hours = (route.time / 3600).floor();
    final minutes = ((route.time % 3600) / 60).round();
    final timeStr = hours > 0 ? '${hours}h ${minutes}min' : '$minutes min';
    final distStr = route.distance < 10
        ? '${route.distance.toStringAsFixed(1)} km'
        : '${route.distance.round()} km';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Distanz', value: distStr),
          _Stat(label: 'Anstieg', value: '${route.ascent.round()} m'),
          _Stat(label: 'Abstieg', value: '${route.descent.round()} m'),
          _Stat(label: 'Zeit', value: timeStr),
        ],
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
