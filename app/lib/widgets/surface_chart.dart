import 'package:flutter/material.dart';

import '../models/route_segment.dart';

class SurfaceChart extends StatelessWidget {
  final List<RouteSegment> segments;
  final double totalDistanceKm;
  final ValueChanged<int?>? onHover;

  const SurfaceChart({
    super.key,
    required this.segments,
    required this.totalDistanceKm,
    this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty || totalDistanceKm <= 0) {
      return const SizedBox.shrink();
    }

    final tally = <SurfaceCategory, double>{};
    for (final s in segments) {
      tally[s.category] = (tally[s.category] ?? 0) + s.lengthKm;
    }
    final entries = tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Beschaffenheit',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${totalDistanceKm.toStringAsFixed(1)} km',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 22,
            child: _SurfaceBar(
              segments: segments,
              totalDistanceKm: totalDistanceKm,
              onHover: onHover,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              for (final e in entries)
                _Legend(
                  color: e.key.color,
                  label: e.key.label,
                  km: e.value,
                  totalKm: totalDistanceKm,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurfaceBar extends StatefulWidget {
  final List<RouteSegment> segments;
  final double totalDistanceKm;
  final ValueChanged<int?>? onHover;

  const _SurfaceBar({
    required this.segments,
    required this.totalDistanceKm,
    this.onHover,
  });

  @override
  State<_SurfaceBar> createState() => _SurfaceBarState();
}

class _SurfaceBarState extends State<_SurfaceBar> {
  RouteSegment? _hovered;
  double? _hoverX;

  void _handle(Offset pos, double width) {
    if (width <= 0) return;
    final ratio = (pos.dx / width).clamp(0.0, 1.0);
    final distKm = ratio * widget.totalDistanceKm;
    RouteSegment? found;
    for (final s in widget.segments) {
      if (distKm >= s.startDistanceKm && distKm <= s.endDistanceKm) {
        found = s;
        break;
      }
    }
    found ??= widget.segments.last;
    setState(() {
      _hovered = found;
      _hoverX = pos.dx;
    });
    final span = found.endDistanceKm - found.startDistanceKm;
    final local = span > 0
        ? ((distKm - found.startDistanceKm) / span).clamp(0.0, 1.0)
        : 0.0;
    final coordSpan = found.endCoordIdx - found.startCoordIdx;
    final idx = found.startCoordIdx + (local * coordSpan).round();
    widget.onHover?.call(idx);
  }

  void _clear() {
    setState(() {
      _hovered = null;
      _hoverX = null;
    });
    widget.onHover?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return MouseRegion(
          onHover: (e) => _handle(e.localPosition, w),
          onExit: (_) => _clear(),
          child: GestureDetector(
            onHorizontalDragUpdate: (d) => _handle(d.localPosition, w),
            onHorizontalDragEnd: (_) => _clear(),
            onTapDown: (d) => _handle(d.localPosition, w),
            onTapUp: (_) => _clear(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      for (final s in widget.segments)
                        Expanded(
                          flex: (s.lengthKm * 10000).round().clamp(1, 1 << 30),
                          child: Container(color: s.category.color),
                        ),
                    ],
                  ),
                ),
                if (_hoverX != null)
                  Positioned(
                    left: _hoverX! - 1,
                    top: -2,
                    bottom: -2,
                    child: Container(width: 2, color: Colors.white),
                  ),
                if (_hovered != null && _hoverX != null)
                  Positioned(
                    left: (_hoverX! - 60).clamp(0.0, w - 120),
                    top: -28,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF222244),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_hovered!.category.label} · ${(_hovered!.lengthKm).toStringAsFixed(2)} km',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final double km;
  final double totalKm;

  const _Legend({
    required this.color,
    required this.label,
    required this.km,
    required this.totalKm,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalKm > 0 ? (km / totalKm * 100) : 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ${pct.toStringAsFixed(0)}%',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
