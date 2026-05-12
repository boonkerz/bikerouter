import 'dart:convert';

class RecordedPoint {
  final double lat;
  final double lon;
  final double? ele;
  final int t; // millis since epoch
  final double? speed; // m/s

  const RecordedPoint({
    required this.lat,
    required this.lon,
    required this.t,
    this.ele,
    this.speed,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        if (ele != null) 'ele': ele,
        't': t,
        if (speed != null) 'speed': speed,
      };

  factory RecordedPoint.fromJson(Map<String, dynamic> j) => RecordedPoint(
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        ele: (j['ele'] as num?)?.toDouble(),
        t: j['t'] as int,
        speed: (j['speed'] as num?)?.toDouble(),
      );
}

class RecordedRide {
  final String id;
  final String name;
  final DateTime startedAt;
  final DateTime endedAt;
  final int movingSeconds;
  final double distanceKm;
  final int ascent;
  final int descent;
  final double avgSpeedKmh;
  final double? maxSpeedKmh;
  final int? kcal;
  final List<RecordedPoint> points;

  const RecordedRide({
    required this.id,
    required this.name,
    required this.startedAt,
    required this.endedAt,
    required this.movingSeconds,
    required this.distanceKm,
    required this.ascent,
    required this.descent,
    required this.avgSpeedKmh,
    this.maxSpeedKmh,
    this.kcal,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'movingSeconds': movingSeconds,
        'distanceKm': distanceKm,
        'ascent': ascent,
        'descent': descent,
        'avgSpeedKmh': avgSpeedKmh,
        if (maxSpeedKmh != null) 'maxSpeedKmh': maxSpeedKmh,
        if (kcal != null) 'kcal': kcal,
        'points': points.map((p) => p.toJson()).toList(),
      };

  factory RecordedRide.fromJson(Map<String, dynamic> j) => RecordedRide(
        id: j['id'] as String,
        name: j['name'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        endedAt: DateTime.parse(j['endedAt'] as String),
        movingSeconds: j['movingSeconds'] as int,
        distanceKm: (j['distanceKm'] as num).toDouble(),
        ascent: j['ascent'] as int,
        descent: j['descent'] as int,
        avgSpeedKmh: (j['avgSpeedKmh'] as num).toDouble(),
        maxSpeedKmh: (j['maxSpeedKmh'] as num?)?.toDouble(),
        kcal: j['kcal'] as int?,
        points: (j['points'] as List)
            .map((p) => RecordedPoint.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  String toJsonString() => jsonEncode(toJson());
  factory RecordedRide.fromJsonString(String s) =>
      RecordedRide.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// GPX 1.1 export. Single track with one segment containing the full
  /// time-stamped point list. Compatible with Strava, Komoot, Garmin
  /// Connect upload, etc.
  String toGpx() {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln(
        '<gpx version="1.1" creator="Wegwiesel" xmlns="http://www.topografix.com/GPX/1/1">');
    buf.writeln('  <metadata>');
    buf.writeln('    <name>${_escape(name)}</name>');
    buf.writeln('    <time>${startedAt.toUtc().toIso8601String()}</time>');
    buf.writeln('  </metadata>');
    buf.writeln('  <trk>');
    buf.writeln('    <name>${_escape(name)}</name>');
    buf.writeln('    <trkseg>');
    for (final p in points) {
      buf.write('      <trkpt lat="${p.lat}" lon="${p.lon}">');
      if (p.ele != null) buf.write('<ele>${p.ele!.toStringAsFixed(1)}</ele>');
      buf.write(
          '<time>${DateTime.fromMillisecondsSinceEpoch(p.t, isUtc: true).toIso8601String()}</time>');
      buf.writeln('</trkpt>');
    }
    buf.writeln('    </trkseg>');
    buf.writeln('  </trk>');
    buf.writeln('</gpx>');
    return buf.toString();
  }

  static String _escape(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}
