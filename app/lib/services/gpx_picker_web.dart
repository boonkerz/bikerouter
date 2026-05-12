import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Browser-native file picker for .gpx — sidesteps file_selector_web,
/// which has historically been flaky to register on Flutter web builds.
/// Creates a transient <input type="file">, listens for the change event,
/// reads the chosen file via FileReader as an ArrayBuffer.
Future<({String name, Uint8List bytes})?> pickGpxFile() async {
  final input = web.document.createElement('input') as web.HTMLInputElement;
  input.type = 'file';
  input.accept = '.gpx,application/gpx+xml,application/xml,text/xml';
  input.style.display = 'none';
  web.document.body!.appendChild(input);

  final completer = Completer<({String name, Uint8List bytes})?>();
  void finishWith(({String name, Uint8List bytes})? value) {
    if (input.isConnected) input.remove();
    if (!completer.isCompleted) completer.complete(value);
  }

  input.onchange = ((web.Event _) {
    final files = input.files;
    if (files == null || files.length == 0) {
      finishWith(null);
      return;
    }
    final file = files.item(0)!;
    final reader = web.FileReader();
    reader.onload = ((web.Event _) {
      final result = reader.result;
      if (result == null) {
        finishWith(null);
        return;
      }
      final buffer = (result as JSArrayBuffer).toDart;
      finishWith((name: file.name, bytes: buffer.asUint8List()));
    }).toJS;
    reader.onerror = ((web.Event _) => finishWith(null)).toJS;
    reader.readAsArrayBuffer(file);
  }).toJS;

  // Newer browsers fire `cancel` when the user dismisses the picker. Older
  // ones don't, so we also arm a 5-minute backstop so the UI cannot hang
  // forever if the user just clicks elsewhere.
  input.oncancel = ((web.Event _) => finishWith(null)).toJS;
  Timer(const Duration(minutes: 5), () => finishWith(null));

  input.click();
  return completer.future;
}
