import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class WeatherSample {
  final double distanceKm;
  final double lat;
  final double lon;
  final DateTime eta;
  final double? tempC;
  final double? precipMm;
  final double? windKmh;
  final double? windDirDeg;
  final int? weatherCode;

  const WeatherSample({
    required this.distanceKm,
    required this.lat,
    required this.lon,
    required this.eta,
    this.tempC,
    this.precipMm,
    this.windKmh,
    this.windDirDeg,
    this.weatherCode,
  });
}

class WeatherService {
  /// Fetches a forecast along the route. Samples at ~[sampleEveryKm] km.
  static Future<List<WeatherSample>> forecastAlongRoute({
    required List<List<double>> coordinates, // [lon, lat, elev]
    required DateTime departure,
    required double avgSpeedKmh,
    double sampleEveryKm = 10,
  }) async {
    if (coordinates.length < 2) return const [];

    // Build per-coordinate cumulative distance.
    final cumKm = <double>[0];
    for (int i = 1; i < coordinates.length; i++) {
      cumKm.add(cumKm.last + _haversine(coordinates[i - 1], coordinates[i]));
    }
    final total = cumKm.last;
    if (total <= 0) return const [];

    final sampleCount = max(2, (total / sampleEveryKm).ceil() + 1);
    final sampleIdx = <int>[];
    for (int n = 0; n < sampleCount; n++) {
      final target = total * n / (sampleCount - 1);
      int idx = 0;
      for (int i = 0; i < cumKm.length; i++) {
        if (cumKm[i] <= target) {
          idx = i;
        } else {
          break;
        }
      }
      sampleIdx.add(idx);
    }

    // Deduplicate consecutive identical indices.
    final uniqueIdx = <int>[];
    for (final i in sampleIdx) {
      if (uniqueIdx.isEmpty || uniqueIdx.last != i) uniqueIdx.add(i);
    }

    final results = <WeatherSample>[];
    for (final i in uniqueIdx) {
      final km = cumKm[i];
      final hours = km / avgSpeedKmh;
      final eta = departure.add(Duration(minutes: (hours * 60).round()));
      final lat = coordinates[i][1];
      final lon = coordinates[i][0];
      final sample = await _fetchPoint(lat, lon, eta, km);
      if (sample != null) results.add(sample);
    }
    return results;
  }

  static Future<WeatherSample?> _fetchPoint(
    double lat,
    double lon,
    DateTime eta,
    double distanceKm,
  ) async {
    final now = DateTime.now();
    final etaLocal = eta.isBefore(now) ? now : eta;
    final forecastDays = ((etaLocal.difference(now).inHours) / 24).ceil().clamp(1, 16);
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&hourly=temperature_2m,precipitation,windspeed_10m,winddirection_10m,weathercode'
      '&timezone=auto'
      '&forecast_days=$forecastDays',
    );
    try {
      final r = await http.get(uri).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final json = jsonDecode(r.body) as Map<String, dynamic>;
      final hourly = json['hourly'] as Map<String, dynamic>;
      final times = (hourly['time'] as List).cast<String>();
      // Match hour — Open-Meteo returns ISO local-time strings per requested tz.
      final target = DateTime(etaLocal.year, etaLocal.month, etaLocal.day, etaLocal.hour);
      int bestIdx = 0;
      int bestDiff = 1 << 30;
      for (int i = 0; i < times.length; i++) {
        final t = DateTime.parse(times[i]);
        final diff = (t.difference(target).inMinutes).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          bestIdx = i;
        }
      }
      double? doubleAt(String key) {
        final list = hourly[key] as List?;
        if (list == null || bestIdx >= list.length) return null;
        final v = list[bestIdx];
        return v == null ? null : (v as num).toDouble();
      }
      int? intAt(String key) {
        final list = hourly[key] as List?;
        if (list == null || bestIdx >= list.length) return null;
        final v = list[bestIdx];
        return v == null ? null : (v as num).toInt();
      }
      return WeatherSample(
        distanceKm: distanceKm,
        lat: lat,
        lon: lon,
        eta: etaLocal,
        tempC: doubleAt('temperature_2m'),
        precipMm: doubleAt('precipitation'),
        windKmh: doubleAt('windspeed_10m'),
        windDirDeg: doubleAt('winddirection_10m'),
        weatherCode: intAt('weathercode'),
      );
    } catch (_) {
      return null;
    }
  }

  static double _haversine(List<double> a, List<double> b) {
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

/// Open-Meteo / WMO weather code → emoji + label.
String weatherCodeEmoji(int? code) {
  if (code == null) return '·';
  if (code == 0) return '☀️';
  if (code <= 2) return '🌤️';
  if (code == 3) return '☁️';
  if (code >= 45 && code <= 48) return '🌫️';
  if (code >= 51 && code <= 57) return '🌦️';
  if (code >= 61 && code <= 67) return '🌧️';
  if (code >= 71 && code <= 77) return '🌨️';
  if (code >= 80 && code <= 82) return '🌧️';
  if (code >= 85 && code <= 86) return '🌨️';
  if (code >= 95) return '⛈️';
  return '·';
}
