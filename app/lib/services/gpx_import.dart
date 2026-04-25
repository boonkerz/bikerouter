import 'dart:math';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:xml/xml.dart';

import '../models/route_result.dart';
import '../models/route_segment.dart';

class GpxImport {
  /// Open the platform file picker for a .gpx file and return its bytes,
  /// or null if the user cancelled.
  static Future<({String name, Uint8List bytes})?> pick() async {
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

  /// Parse GPX track XML into a RouteResult-like structure. Concatenates
  /// every `trkseg` in every `trk` into a single coordinate sequence.
  static RouteResult parse(Uint8List bytes) {
    final doc = XmlDocument.parse(String.fromCharCodes(bytes));
    final coords = <List<double>>[];
    for (final trk in doc.findAllElements('trk')) {
      for (final seg in trk.findElements('trkseg')) {
        for (final pt in seg.findElements('trkpt')) {
          final latStr = pt.getAttribute('lat');
          final lonStr = pt.getAttribute('lon');
          if (latStr == null || lonStr == null) continue;
          final lat = double.tryParse(latStr);
          final lon = double.tryParse(lonStr);
          if (lat == null || lon == null) continue;
          double ele = 0;
          final eleEl = pt.findElements('ele').firstOrNull;
          if (eleEl != null) {
            ele = double.tryParse(eleEl.innerText.trim()) ?? 0;
          }
          coords.add([lon, lat, ele]);
        }
      }
    }

    if (coords.isEmpty) {
      throw GpxImportException('empty');
    }

    double distance = 0;
    double ascent = 0;
    double descent = 0;
    for (int i = 1; i < coords.length; i++) {
      distance += _haversineKm(coords[i - 1], coords[i]);
      final dEl = coords[i][2] - coords[i - 1][2];
      if (dEl > 0) {
        ascent += dEl;
      } else {
        descent += -dEl;
      }
    }
    // Rough time estimate at 18 km/h to keep StatsBar useful even without a
    // real routing profile.
    final time = (distance / 18) * 3600;

    return RouteResult(
      geojson: const {},
      distance: distance,
      ascent: ascent,
      descent: descent,
      time: time,
      coordinates: coords,
      segments: const <RouteSegment>[],
    );
  }

  static double _haversineKm(List<double> a, List<double> b) {
    const r = 6371.0;
    final dLat = (b[1] - a[1]) * pi / 180;
    final dLon = (b[0] - a[0]) * pi / 180;
    final lat1 = a[1] * pi / 180;
    final lat2 = b[1] * pi / 180;
    final x = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(x), sqrt(1 - x));
  }
}

class GpxImportException implements Exception {
  final String code;
  GpxImportException(this.code);
  @override
  String toString() => 'GpxImportException($code)';
}
