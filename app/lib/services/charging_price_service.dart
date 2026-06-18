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

  const AfirPrice({
    this.kwh,
    this.perMin,
    this.kw,
    this.operator,
    this.currency = 'EUR',
  });
}

class _PricePoint {
  final double lat;
  final double lon;
  final AfirPrice price;
  const _PricePoint(this.lat, this.lon, this.price);
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
          ),
        ));
      }
    } catch (_) {
      // best-effort
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
