import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

/// A real AFIR ad-hoc charging price for one station, sourced from the
/// server-side Mobilithek feed via wegwiesel.app/api/charging-prices.
class AfirPrice {
  final double? kwh; // gross (tax-incl.) € per kWh
  final double? perMin; // gross € per minute (e.g. blocking fee)
  final double? kw; // max charging power
  final String? operator;
  final String currency;
  final String? state; // live: 'available' | 'busy' | 'offline' | null=unknown
  final int? avail; // live: number of available points known

  const AfirPrice({
    this.kwh,
    this.perMin,
    this.kw,
    this.operator,
    this.currency = 'EUR',
    this.state,
    this.avail,
  });

  bool get isBusy => state == 'busy' || state == 'offline';
}

class _PricePoint {
  final double lat;
  final double lon;
  final AfirPrice price;
  const _PricePoint(this.lat, this.lon, this.price);
}

/// One charging station with its live price/status and how far it is from the
/// query point — result of the "nearest free station" search.
class NearbyStation {
  final double lat;
  final double lon;
  final AfirPrice price;
  final double distanceM;
  const NearbyStation(this.lat, this.lon, this.price, this.distanceM);
}

/// Fetches real ad-hoc charging prices for the area around the planned charging
/// stops and matches them to charging POIs by proximity. The app never holds the
/// Mobilithek mTLS certificate — it only asks the server for a small bbox, so the
/// full (growing) dataset is never downloaded.
class ChargingPriceService {
  ChargingPriceService._();
  static final ChargingPriceService instance = ChargingPriceService._();

  static const _base = 'https://wegwiesel.app/api/charging-prices';

  final List<_PricePoint> _points = [];
  final Set<String> _loadedTiles = {};

  /// Loads prices around each spot (one small bbox per ~0.1° tile, deduplicated).
  /// Best-effort: network/parse errors are swallowed so the EV flow still works.
  Future<void> loadAround(Iterable<({double lat, double lon})> spots) async {
    final futures = <Future<void>>[];
    for (final s in spots) {
      final key = '${(s.lat * 10).floor()},${(s.lon * 10).floor()}';
      if (!_loadedTiles.add(key)) continue;
      futures.add(_loadBbox(s.lon - 0.06, s.lat - 0.06, s.lon + 0.06, s.lat + 0.06));
    }
    if (futures.isNotEmpty) await Future.wait(futures);
  }

  Future<void> _loadBbox(double w, double s, double e, double n) async {
    try {
      final uri = Uri.parse(
          '$_base?bbox=${w.toStringAsFixed(4)},${s.toStringAsFixed(4)},${e.toStringAsFixed(4)},${n.toStringAsFixed(4)}');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      for (final p in (data['points'] as List? ?? const [])) {
        final m = p as Map<String, dynamic>;
        final lat = (m['lat'] as num?)?.toDouble();
        final lon = (m['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;
        _points.add(_PricePoint(
          lat,
          lon,
          AfirPrice(
            kwh: (m['kwh'] as num?)?.toDouble(),
            perMin: (m['min'] as num?)?.toDouble(),
            kw: (m['kw'] as num?)?.toDouble(),
            operator: m['op'] as String?,
            currency: (m['cur'] as String?) ?? 'EUR',
            state: m['st'] as String?,
            avail: (m['av'] as num?)?.toInt(),
          ),
        ));
      }
    } catch (_) {
      // best-effort
    }
  }

  /// Charging stations around (lat, lon) that are currently reporting live
  /// availability ('available'), within a [radiusKm] box, sorted nearest-first
  /// and capped at [limit]. Empty on error/none. Fetched fresh on every call
  /// (live status is time-sensitive, so never cached) and independent of the
  /// route-planner cache.
  Future<List<NearbyStation>> nearbyAvailable(double lat, double lon,
      {double radiusKm = 12, int limit = 25}) async {
    final dLat = radiusKm / 111.0;
    final dLon = radiusKm / (111.0 * cos(lat * pi / 180).abs().clamp(0.01, 1.0));
    try {
      final w = lon - dLon, s = lat - dLat, e = lon + dLon, n = lat + dLat;
      final uri = Uri.parse(
          '$_base?bbox=${w.toStringAsFixed(4)},${s.toStringAsFixed(4)},${e.toStringAsFixed(4)},${n.toStringAsFixed(4)}');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return const [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final out = <NearbyStation>[];
      for (final p in (data['points'] as List? ?? const [])) {
        final m = p as Map<String, dynamic>;
        if (m['st'] != 'available') continue;
        final plat = (m['lat'] as num?)?.toDouble();
        final plon = (m['lon'] as num?)?.toDouble();
        if (plat == null || plon == null) continue;
        out.add(NearbyStation(
          plat,
          plon,
          AfirPrice(
            kwh: (m['kwh'] as num?)?.toDouble(),
            perMin: (m['min'] as num?)?.toDouble(),
            kw: (m['kw'] as num?)?.toDouble(),
            operator: m['op'] as String?,
            currency: (m['cur'] as String?) ?? 'EUR',
            state: m['st'] as String?,
            avail: (m['av'] as num?)?.toInt(),
          ),
          _haversineM(lat, lon, plat, plon),
        ));
      }
      out.sort((a, b) => a.distanceM.compareTo(b.distanceM));
      return out.length > limit ? out.sublist(0, limit) : out;
    } catch (_) {
      return const [];
    }
  }

  /// Nearest cached priced station within [maxMeters] of (lat, lon), or null.
  AfirPrice? lookup(double lat, double lon, {double maxMeters = 150}) {
    AfirPrice? best;
    var bestM = maxMeters;
    for (final p in _points) {
      final d = _haversineM(lat, lon, p.lat, p.lon);
      if (d <= bestM) {
        bestM = d;
        best = p.price;
      }
    }
    return best;
  }

  double _haversineM(double la1, double lo1, double la2, double lo2) {
    const r = 6371000.0;
    final dLa = (la2 - la1) * pi / 180;
    final dLo = (lo2 - lo1) * pi / 180;
    final a = sin(dLa / 2) * sin(dLa / 2) +
        cos(la1 * pi / 180) * cos(la2 * pi / 180) * sin(dLo / 2) * sin(dLo / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
