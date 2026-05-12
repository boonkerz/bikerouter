import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

Future<({String name, Uint8List bytes})?> pickGpxFile() async {
  const typeGroup = XTypeGroup(
    label: 'GPX',
    extensions: ['gpx'],
    mimeTypes: ['application/gpx+xml', 'application/xml', 'text/xml'],
  );
  final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return (name: file.name, bytes: bytes);
}
