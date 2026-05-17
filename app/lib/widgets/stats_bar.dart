import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
  /// User-set average speed override in km/h. When provided, the time stat
  /// displays distance / speed instead of BRouter's profile-based estimate.
  final int? userSpeedKmh;
  /// When true the ascent stat is rendered with stronger emphasis. Hikers
  /// and runners read ascent first; cyclists read distance first.
  final bool highlightAscent;
  /// When true, render a SAC-difficulty badge below the stats if the route
  /// touches any SAC-tagged segment. Set on hiking profiles only.
  final bool showSacBadge;

  const StatsBar({
    super.key,
    required this.route,
    this.actions = const [],
    this.userSpeedKmh,
    this.highlightAscent = false,
    this.showSacBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final effectiveSeconds = userSpeedKmh != null && userSpeedKmh! > 0
        ? (route.distance / userSpeedKmh!) * 3600
        : route.time;
    final hours = (effectiveSeconds / 3600).floor();
    final minutes = ((effectiveSeconds % 3600) / 60).round();
    final timeStr = hours > 0 ? '${hours}h ${minutes}min' : '$minutes min';
    final distStr = route.distance < 10
        ? '${route.distance.toStringAsFixed(1)} km'
        : '${route.distance.round()} km';

    final sacLevel = route.maxSacLevel;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFf5e9d8),
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(label: l.statsDistance, value: distStr),
                _Stat(
                  label: l.statsAscent,
                  value: '${route.ascent.round()} m',
                  highlight: highlightAscent,
                ),
                _Stat(label: l.statsDescent, value: '${route.descent.round()} m'),
                _Stat(label: l.statsTime, value: timeStr),
              ],
            ),
          ),
          if (showSacBadge && sacLevel > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _SacBadge(level: sacLevel),
            ),
          if (actions.isNotEmpty)
            Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
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
    final color = action.active ? const Color(0xFFf5e9d8) : const Color(0xFF6a4a28);
    final bg = action.active ? const Color(0xFF6a4a28) : Colors.transparent;
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

class _SacBadge extends StatelessWidget {
  final int level;

  const _SacBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = _colorForLevel(level);
    final desc = _descForLevel(l, level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'T$level',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${l.sacBadgePrefix} $desc',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6a4a28)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForLevel(int l) {
    if (l <= 1) return const Color(0xFF66bb6a);
    if (l == 2) return const Color(0xFF9ccc65);
    if (l == 3) return const Color(0xFFffa726);
    if (l == 4) return const Color(0xFFef6c00);
    if (l == 5) return const Color(0xFFd84315);
    return const Color(0xFFb71c1c);
  }

  String _descForLevel(AppLocalizations l, int level) {
    switch (level) {
      case 1:
        return l.sacT1;
      case 2:
        return l.sacT2;
      case 3:
        return l.sacT3;
      case 4:
        return l.sacT4;
      case 5:
        return l.sacT5;
      case 6:
        return l.sacT6;
    }
    return '';
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _Stat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF6a4a28),
            fontSize: highlight ? 19 : 16,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withValues(alpha: highlight ? 0.7 : 0.5),
            fontSize: 11,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
