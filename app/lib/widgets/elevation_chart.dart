import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ElevationChart extends StatelessWidget {
  final List<List<double>> coordinates;
  final ValueChanged<int?>? onHover;

  const ElevationChart({
    super.key,
    required this.coordinates,
    this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final result = _buildPoints();
    final points = result.spots;
    if (points.isEmpty) return const SizedBox.shrink();

    final elevations = points.map((p) => p.y).toList();
    final minElev = elevations.reduce(min) - 20;
    final maxElev = elevations.reduce(max) + 20;
    final maxDist = points.last.x;

    return Container(
      height: 140,
      padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: LineChart(
        LineChartData(
          minY: minElev,
          maxY: maxElev,
          minX: 0,
          maxX: maxDist,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _niceInterval(maxElev - minElev, 4),
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withValues(alpha: 0.08),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: _niceInterval(maxElev - minElev, 4),
                getTitlesWidget: (value, meta) => Text(
                  '${value.round()} m',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: _niceInterval(maxDist, 6),
                getTitlesWidget: (value, meta) => Text(
                  '${value.round()} km',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchCallback: (event, response) {
              if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
                final spotIdx = response.lineBarSpots!.first.spotIndex;
                // Map sampled spot index back to original coordinate index
                if (spotIdx < result.originalIndices.length) {
                  onHover?.call(result.originalIndices[spotIdx]);
                }
              } else {
                onHover?.call(null);
              }
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF222244),
              getTooltipItems: (spots) => spots.map((spot) {
                return LineTooltipItem(
                  '${spot.x.toStringAsFixed(1)} km\n${spot.y.round()} m',
                  const TextStyle(color: Color(0xFF4fc3f7), fontSize: 12),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: points,
              isCurved: true,
              curveSmoothness: 0.15,
              color: const Color(0xFF4fc3f7),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF4fc3f7).withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _SampledPoints _buildPoints() {
    final spots = <FlSpot>[];
    final originalIndices = <int>[];
    double dist = 0;

    for (int i = 0; i < coordinates.length; i++) {
      if (i > 0) {
        dist += _haversine(coordinates[i - 1], coordinates[i]);
      }
      if (i == 0 ||
          i == coordinates.length - 1 ||
          dist - (spots.isEmpty ? 0 : spots.last.x) > 0.1) {
        spots.add(FlSpot(dist, coordinates[i][2]));
        originalIndices.add(i);
      }
    }
    return _SampledPoints(spots: spots, originalIndices: originalIndices);
  }

  double _haversine(List<double> a, List<double> b) {
    const r = 6371.0;
    final dLat = (b[1] - a[1]) * pi / 180;
    final dLon = (b[0] - a[0]) * pi / 180;
    final lat1 = a[1] * pi / 180;
    final lat2 = b[1] * pi / 180;
    final x = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(x), sqrt(1 - x));
  }

  double _niceInterval(double range, int targetTicks) {
    if (range <= 0) return 1;
    final rough = range / targetTicks;
    final magnitude = pow(10, (log(rough) / ln10).floor()).toDouble();
    final residual = rough / magnitude;
    if (residual <= 1.5) return magnitude;
    if (residual <= 3) return 2 * magnitude;
    if (residual <= 7) return 5 * magnitude;
    return 10 * magnitude;
  }
}

class _SampledPoints {
  final List<FlSpot> spots;
  final List<int> originalIndices;

  _SampledPoints({required this.spots, required this.originalIndices});
}
