import '../models/route_poi.dart';
import '../models/route_result.dart';

class GpxBuilder {
  static String build({
    required RouteResult route,
    required String trackName,
    required List<RoutePoi> pois,
    String creator = 'BikeRouter (bikerouter.thomas-peterson.de)',
  }) {
    final buf = StringBuffer();
    final now = DateTime.now().toUtc().toIso8601String();

    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln(
        '<gpx version="1.1" creator="${_esc(creator)}" xmlns="http://www.topografix.com/GPX/1/1">');
    buf.writeln('  <metadata>');
    buf.writeln('    <name>${_esc(trackName)}</name>');
    buf.writeln('    <time>$now</time>');
    buf.writeln('  </metadata>');

    // POIs as waypoints (must come before trk per GPX spec)
    for (final p in pois) {
      buf.writeln('  <wpt lat="${p.lat}" lon="${p.lon}">');
      if (p.name != null && p.name!.isNotEmpty) {
        buf.writeln('    <name>${_esc(p.name!)}</name>');
      } else {
        buf.writeln('    <name>${_esc(p.category.label)}</name>');
      }
      if (p.note != null && p.note!.isNotEmpty) {
        buf.writeln('    <desc>${_esc(p.note!)}</desc>');
      }
      buf.writeln('    <sym>${_esc(p.category.gpxSym)}</sym>');
      buf.writeln('    <type>${_esc(p.category.gpxType)}</type>');
      buf.writeln('  </wpt>');
    }

    // Track
    buf.writeln('  <trk>');
    buf.writeln('    <name>${_esc(trackName)}</name>');
    buf.writeln('    <trkseg>');
    for (final c in route.coordinates) {
      final lon = c[0];
      final lat = c[1];
      final ele = c.length > 2 ? c[2] : null;
      if (ele != null) {
        buf.writeln('      <trkpt lat="$lat" lon="$lon"><ele>$ele</ele></trkpt>');
      } else {
        buf.writeln('      <trkpt lat="$lat" lon="$lon"/>');
      }
    }
    buf.writeln('    </trkseg>');
    buf.writeln('  </trk>');
    buf.writeln('</gpx>');

    return buf.toString();
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
