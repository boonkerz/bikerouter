import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Tells an ultra-cyclist roughly how much power-bank capacity they
/// need for a tour. Inputs the user can change (tour duration + how
/// often they look at the screen + nightriding); outputs an mAh figure
/// at 5V with a comfort margin.
///
/// The numbers are intentionally rough — every phone draws differently
/// and the user just needs an "8000 vs 20000" decision. We model:
///   * idle baseline             ~100 mA at 5V
///   * GPS recording (extra)     +250 mA
///   * Display on (day backlight) +500 mA
///   * Display on (night max)     +800 mA
///   * 30% safety margin on top
///
/// All numbers from running RideRecorder + flutter_map on a midrange
/// 2024-era phone with a SoC-typical LiPo at 3.85V cell.
Future<void> showBatteryBudgetDialog(BuildContext context) async {
  final l = AppLocalizations.of(context);
  double tourHours = 12;
  double displayPct = 25;
  bool nightRiding = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Capacity calculation — see file-level comment for the model.
          const baselineMa = 100.0;
          const gpsExtraMa = 250.0;
          final displayMa = nightRiding ? 800.0 : 500.0;
          final avgMa = baselineMa + gpsExtraMa +
              (displayPct / 100) * displayMa;
          final rawMah = avgMa * tourHours;
          final mah = (rawMah * 1.3).round(); // 30% safety margin
          // Recommend a real power-bank size — phone batteries are
          // typically ~4000-5000 mAh, so add a phone equivalent on top
          // for a "full overnight" feeling.
          final bankMah = ((mah + 4500) / 1000).round() * 1000;

          return AlertDialog(
            backgroundColor: const Color(0xFFf5e9d8),
            title: Row(
              children: [
                const Icon(Icons.battery_charging_full,
                    color: Color(0xFF6a4a28)),
                const SizedBox(width: 8),
                Expanded(child: Text(l.batteryBudgetTitle)),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.batteryBudgetDuration(tourHours.round()),
                      style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600)),
                  Slider(
                    value: tourHours,
                    min: 1,
                    max: 48,
                    divisions: 47,
                    activeColor: const Color(0xFF6a4a28),
                    onChanged: (v) =>
                        setDialogState(() => tourHours = v),
                  ),
                  Text(l.batteryBudgetDisplayPct(displayPct.round()),
                      style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600)),
                  Slider(
                    value: displayPct,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    activeColor: const Color(0xFF6a4a28),
                    onChanged: (v) =>
                        setDialogState(() => displayPct = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.batteryBudgetNight,
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 14)),
                    subtitle: Text(l.batteryBudgetNightSub,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12)),
                    value: nightRiding,
                    activeThumbColor: const Color(0xFF6a4a28),
                    onChanged: (v) =>
                        setDialogState(() => nightRiding = v),
                  ),
                  const Divider(color: Colors.black26),
                  const SizedBox(height: 8),
                  // Phone-internal need
                  Row(
                    children: [
                      const Icon(Icons.smartphone,
                          color: Color(0xFF6a4a28), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l.batteryBudgetNeeded,
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 13)),
                      ),
                      Text('$mah mAh',
                          style: const TextStyle(
                              color: Color(0xFF6a4a28),
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Power-bank recommendation
                  Row(
                    children: [
                      const Icon(Icons.battery_full,
                          color: Color(0xFF6a4a28), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l.batteryBudgetPowerbank,
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 13)),
                      ),
                      Text('$bankMah mAh',
                          style: const TextStyle(
                              color: Color(0xFF6a4a28),
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(l.batteryBudgetDisclaimer,
                      style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l.commonClose,
                    style: const TextStyle(color: Color(0xFF6a4a28))),
              ),
            ],
          );
        },
      );
    },
  );
}
