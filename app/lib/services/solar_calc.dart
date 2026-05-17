import 'dart:math';

class SolarTimes {
  final DateTime sunriseUtc;
  final DateTime sunsetUtc;

  const SolarTimes(this.sunriseUtc, this.sunsetUtc);

  /// Local-time variants. Dart's [DateTime.toLocal] uses the device timezone,
  /// which is what a user planning a tour wants to see ("21:34 sunset" rather
  /// than "19:34 UTC").
  DateTime get sunriseLocal => sunriseUtc.toLocal();
  DateTime get sunsetLocal => sunsetUtc.toLocal();
}

/// NOAA solar calculator (Fourier-series fits, accurate to ~1 min for civil
/// sunrise/sunset between latitudes -65..65). Polar day/night returns null.
class SolarCalc {
  static const _zenithDeg = 90.833; // civil sunrise/sunset

  static SolarTimes? compute({
    required double lat,
    required double lon,
    required DateTime date,
  }) {
    final dayOfYear = date.difference(DateTime(date.year)).inDays + 1;
    // Fractional year in radians. Hour-of-day correction is omitted — we
    // compute sunrise/sunset for the calendar day in UTC.
    final fracYear = 2 * pi / 365.0 * (dayOfYear - 1);

    // Equation of time (minutes).
    final eqTime = 229.18 *
        (0.000075 +
            0.001868 * cos(fracYear) -
            0.032077 * sin(fracYear) -
            0.014615 * cos(2 * fracYear) -
            0.040849 * sin(2 * fracYear));

    // Solar declination (radians).
    final decl = 0.006918 -
        0.399912 * cos(fracYear) +
        0.070257 * sin(fracYear) -
        0.006758 * cos(2 * fracYear) +
        0.000907 * sin(2 * fracYear) -
        0.002697 * cos(3 * fracYear) +
        0.00148 * sin(3 * fracYear);

    final latRad = lat * pi / 180;
    final cosHa = (cos(_zenithDeg * pi / 180) - sin(latRad) * sin(decl)) /
        (cos(latRad) * cos(decl));
    if (cosHa.isNaN || cosHa < -1 || cosHa > 1) return null;
    final haDeg = acos(cosHa) * 180 / pi;

    // Solar noon in UTC minutes.
    final solarNoonUtcMin = 720 - 4 * lon - eqTime;
    final sunriseUtcMin = solarNoonUtcMin - 4 * haDeg;
    final sunsetUtcMin = solarNoonUtcMin + 4 * haDeg;

    DateTime utcAt(double minutes) {
      final base = DateTime.utc(date.year, date.month, date.day);
      return base.add(Duration(seconds: (minutes * 60).round()));
    }

    return SolarTimes(utcAt(sunriseUtcMin), utcAt(sunsetUtcMin));
  }
}
