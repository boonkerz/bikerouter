import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> exportGpxFile(String filename, String content) async {
  final bytes = utf8.encode(content);
  final jsArray = bytes.toJS;
  final blob = web.Blob([jsArray].toJS, web.BlobPropertyBag(type: 'application/gpx+xml'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
