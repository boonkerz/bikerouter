import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bikerouter/main.dart' as app;

/// Drives the real app in a simulator to produce App-Store / Play-Store
/// screenshots. The route is seeded through the `WW_SHARE` compile-time
/// define (decoded by `share_url_stub.dart` → `MapScreen._tryLoadSharedRoute`),
/// so the map opens on a known route without any tapping.
///
/// The shots after the hero are best-effort: each is wrapped so a missing
/// widget or a slow sheet never fails the whole run — the hero shot alone is
/// already a usable store image, and the rest are a bonus.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store screenshots', (tester) async {
    app.main();

    // Map tiles and the brouter route come over the network, so plain
    // pumpAndSettle never settles (tiles keep animating). Pump on a timer.
    await _pumpFor(tester, const Duration(seconds: 20));

    // Required once before takeScreenshot so the GPU surface can be read back.
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();

    await _shot(binding, tester, '01-hero');

    // Weather sheet.
    await _maybe(tester, () async {
      await _tapIcon(tester, Icons.cloud_outlined);
      await _pumpFor(tester, const Duration(seconds: 6));
      await _shot(binding, tester, '02-weather');
      await _dismissSheet(tester);
    });

    // Stage planner.
    await _maybe(tester, () async {
      await _tapIcon(tester, Icons.date_range);
      await _pumpFor(tester, const Duration(seconds: 4));
      await _shot(binding, tester, '03-stages');
      await _dismissSheet(tester);
    });

    // Accommodation sheet.
    await _maybe(tester, () async {
      await _tapIcon(tester, Icons.bed_outlined);
      await _pumpFor(tester, const Duration(seconds: 6));
      await _shot(binding, tester, '04-accommodation');
      await _dismissSheet(tester);
    });
  });
}

/// Pumps frames repeatedly for [d] so network-driven UI (tiles, route) can
/// catch up — a substitute for pumpAndSettle, which never returns while the
/// map keeps animating.
Future<void> _pumpFor(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _shot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pump();
  await binding.takeScreenshot(name);
}

/// Taps the first visible widget carrying [icon], if any.
Future<void> _tapIcon(WidgetTester tester, IconData icon) async {
  final finder = find.byIcon(icon);
  expect(finder, findsWidgets);
  await tester.tap(finder.first, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 500));
}

/// Closes an open modal bottom sheet by tapping the top-left corner (barrier).
Future<void> _dismissSheet(WidgetTester tester) async {
  await tester.tapAt(const Offset(8, 8));
  await _pumpFor(tester, const Duration(seconds: 1));
}

/// Runs [body], swallowing any failure so one flaky shot can't sink the run.
Future<void> _maybe(WidgetTester tester, Future<void> Function() body) async {
  try {
    await body();
  } catch (e) {
    // ignore: avoid_print
    print('screenshot step skipped: $e');
    await _pumpFor(tester, const Duration(seconds: 1));
  }
}
