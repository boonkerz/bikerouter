import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum GpxImportMode { reroute, track }

/// After fetching a GPX, asks whether to re-route it through BRouter (gets
/// surface info, turn hints, navigation) or keep it as a fixed track (1:1
/// geometry from the source).
Future<GpxImportMode?> askGpxImportMode(
  BuildContext context, {
  required int pointCount,
  required double distanceKm,
}) {
  return showDialog<GpxImportMode>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final l = AppLocalizations.of(ctx);
      return AlertDialog(
        title: Text(l.gpxModeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.gpxModeSummary(pointCount, distanceKm.toStringAsFixed(1))),
            const SizedBox(height: 16),
            _option(
              icon: Icons.auto_awesome,
              title: l.gpxModeRerouteTitle,
              body: l.gpxModeRerouteBody,
              onTap: () => Navigator.of(ctx).pop(GpxImportMode.reroute),
              highlighted: true,
            ),
            const SizedBox(height: 8),
            _option(
              icon: Icons.route,
              title: l.gpxModeTrackTitle,
              body: l.gpxModeTrackBody,
              onTap: () => Navigator.of(ctx).pop(GpxImportMode.track),
              highlighted: false,
            ),
          ],
        ),
      );
    },
  );
}

Widget _option({
  required IconData icon,
  required String title,
  required String body,
  required VoidCallback onTap,
  required bool highlighted,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF6a4a28)
              : Colors.black26,
          width: highlighted ? 2 : 1,
        ),
        color: highlighted ? const Color(0xFFebd9bd) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6a4a28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2a2014))),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
