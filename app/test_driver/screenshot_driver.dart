import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver side of the screenshot integration test. Runs on the host (not the
/// device): every `binding.takeScreenshot(name)` call in
/// `integration_test/screenshots_test.dart` ships PNG bytes here, and we write
/// them to `build/screenshots/ios/<name>.png`.
///
/// Run with:
///   flutter drive \
///     --driver=test_driver/screenshot_driver.dart \
///     --target=integration_test/screenshots_test.dart \
///     -d SIMULATOR_UDID \
///     --dart-define=WW_SHARE=BASE64_SHARE_PAYLOAD
Future<void> main() async {
  final outDir = Directory(
    Platform.environment['SHOT_OUT'] ?? 'build/screenshots/ios',
  );
  await outDir.create(recursive: true);

  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('${outDir.path}/$name.png');
      await file.writeAsBytes(bytes);
      stdout.writeln('saved ${file.path} (${bytes.length} bytes)');
      return true;
    },
  );
}
