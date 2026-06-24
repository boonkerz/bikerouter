import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Modeled e-mobility charging-card tariffs ("Weg 1").
///
/// There is no free, open feed for EMP roaming/card tariffs (AFIR only mandates
/// the ad-hoc price; full roaming data is commercial — Hubject, Chargeprice at
/// ~109 €/mo, Eco-Movement). So we keep a small, hand-maintained table on our
/// own server (`/api/charging-tariffs`, fetched + cached here) and a built-in
/// copy as offline fallback. A rider picks their card per stop and sees roughly
/// what it costs, instead of only the AFIR ad-hoc price (which a card user does
/// not pay).
///
/// Model per card:
///  * [home] = AFIR operator ids that count as the card's OWN network. At those
///    stations the exact [homePerKwh] applies.
///  * elsewhere (roaming) the AC/DC estimate ([acPerKwh] / [dcPerKwh]) applies —
///    usually the provider's "ab X" lower bound, so treat it as approximate.
///  * [monthlyFee] is informational (a monthly subscription, NOT per charge).
///  * blocking fee = [blockingPerMin] beyond [blockingAfterMin] minutes, capped
///    at [blockingMaxEur], optionally DC-only.
///
/// Values are approximate gross € (mid-2026) and change over time; maintained
/// centrally in the server JSON so all users stay current without an app update.
class ChargingCard {
  final String id;
  final String name;
  final List<String> home;
  final double? homePerKwh;
  final double? acPerKwh;
  final double? dcPerKwh;
  final double monthlyFee;
  final double blockingPerMin;
  final int blockingAfterMin;
  final double blockingMaxEur;
  final bool blockingDcOnly;

  const ChargingCard({
    required this.id,
    required this.name,
    this.home = const [],
    this.homePerKwh,
    this.acPerKwh,
    this.dcPerKwh,
    this.monthlyFee = 0,
    this.blockingPerMin = 0,
    this.blockingAfterMin = 0,
    this.blockingMaxEur = 0,
    this.blockingDcOnly = true,
  });

  bool get isAdhoc => id == 'adhoc';

  static ChargingCard fromJson(Map<String, dynamic> m) => ChargingCard(
        id: m['id'] as String,
        name: m['name'] as String,
        home: ((m['home'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        homePerKwh: (m['homePerKwh'] as num?)?.toDouble(),
        acPerKwh: (m['acPerKwh'] as num?)?.toDouble(),
        dcPerKwh: (m['dcPerKwh'] as num?)?.toDouble(),
        monthlyFee: (m['monthlyFee'] as num?)?.toDouble() ?? 0,
        blockingPerMin: (m['blockingPerMin'] as num?)?.toDouble() ?? 0,
        blockingAfterMin: (m['blockingAfterMin'] as num?)?.toInt() ?? 0,
        blockingMaxEur: (m['blockingMaxEur'] as num?)?.toDouble() ?? 0,
        blockingDcOnly: (m['blockingDcOnly'] as bool?) ?? true,
      );
}

class ChargingTariffs {
  static const _endpoint = 'https://wegwiesel.app/api/charging-tariffs';

  /// Ad-hoc / direct payment — uses the live AFIR price, not a fixed rate.
  static const _adhoc = ChargingCard(id: 'adhoc', name: 'Ad-hoc');

  /// Built-in fallback used until the server list loads (and offline). Kept in
  /// sync with server/charging-prices/tariffs.json.
  static const _defaults = <ChargingCard>[
    _adhoc,
    ChargingCard(
        id: 'enbw_s',
        name: 'EnBW mobility+ S',
        home: ['DE-NAP-EnBWAG'],
        homePerKwh: 0.56,
        acPerKwh: 0.56,
        dcPerKwh: 0.56,
        blockingPerMin: 0.10,
        blockingAfterMin: 240,
        blockingMaxEur: 12.0,
        blockingDcOnly: false),
    ChargingCard(
        id: 'enbw_m',
        name: 'EnBW mobility+ M',
        home: ['DE-NAP-EnBWAG'],
        homePerKwh: 0.46,
        acPerKwh: 0.56,
        dcPerKwh: 0.56,
        monthlyFee: 5.99,
        blockingPerMin: 0.10,
        blockingAfterMin: 240,
        blockingMaxEur: 12.0,
        blockingDcOnly: false),
    ChargingCard(
        id: 'enbw_l',
        name: 'EnBW mobility+ L',
        home: ['DE-NAP-EnBWAG'],
        homePerKwh: 0.39,
        acPerKwh: 0.56,
        dcPerKwh: 0.56,
        monthlyFee: 11.99,
        blockingPerMin: 0.10,
        blockingAfterMin: 240,
        blockingMaxEur: 12.0,
        blockingDcOnly: false),
    ChargingCard(
        id: 'adac', name: 'ADAC e-Charge', acPerKwh: 0.55, dcPerKwh: 0.55),
    ChargingCard(
        id: 'maingau',
        name: 'Maingau',
        acPerKwh: 0.52,
        dcPerKwh: 0.62,
        blockingPerMin: 0.10,
        blockingAfterMin: 240),
    ChargingCard(
        id: 'ewego',
        name: 'EWE Go',
        acPerKwh: 0.62,
        dcPerKwh: 0.62,
        blockingPerMin: 0.10,
        blockingAfterMin: 240,
        blockingMaxEur: 24.0,
        blockingDcOnly: false),
    ChargingCard(
        id: 'shell', name: 'Shell Recharge', acPerKwh: 0.59, dcPerKwh: 0.79),
  ];

  static List<ChargingCard> _cards = _defaults;
  static bool _loaded = false;

  static List<ChargingCard> get cards => _cards;

  /// Fetch the latest tariff table from our server (best-effort; keeps the
  /// built-in defaults on any failure). Cached after the first success.
  static Future<void> load() async {
    if (_loaded) return;
    try {
      final resp = await http
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = (data['cards'] as List?) ?? const [];
      final parsed = <ChargingCard>[];
      for (final c in list) {
        try {
          parsed.add(ChargingCard.fromJson(c as Map<String, dynamic>));
        } catch (_) {
          // skip malformed entries
        }
      }
      if (parsed.any((c) => c.isAdhoc)) {
        _cards = parsed;
      } else {
        _cards = [_adhoc, ...parsed];
      }
      _loaded = true;
    } catch (_) {
      // keep defaults
    }
  }

  static ChargingCard byId(String id) =>
      _cards.firstWhere((c) => c.id == id, orElse: () => _adhoc);

  /// Cost of one charge under [card] at a station operated by [stationOperator]
  /// (the AFIR `op`), or null when the price can't be derived. Returns the
  /// effective €/kWh [rate], total [cost] incl. capped blocking fee, and whether
  /// the price is a [roaming] estimate (i.e. not the card's own network).
  static ({double rate, double cost, bool roaming})? cost({
    required ChargingCard card,
    required String? stationOperator,
    required bool dc,
    required double kwh,
    required double minutes,
    double? adhocKwh,
    double? adhocPerMin,
  }) {
    if (card.isAdhoc) {
      if (adhocKwh == null) return null;
      var c = kwh * adhocKwh;
      if (adhocPerMin != null && adhocPerMin > 0) c += minutes * adhocPerMin;
      return (rate: adhocKwh, cost: c, roaming: false);
    }
    final atHome = card.homePerKwh != null &&
        stationOperator != null &&
        card.home.contains(stationOperator);
    final rate = atHome ? card.homePerKwh : (dc ? card.dcPerKwh : card.acPerKwh);
    if (rate == null) return null;
    var c = kwh * rate;
    if (card.blockingPerMin > 0 && (!card.blockingDcOnly || dc)) {
      final over = minutes - card.blockingAfterMin;
      if (over > 0) {
        var fee = over * card.blockingPerMin;
        if (card.blockingMaxEur > 0 && fee > card.blockingMaxEur) {
          fee = card.blockingMaxEur;
        }
        c += fee;
      }
    }
    return (rate: rate, cost: c, roaming: !atHome);
  }

  // Last card the user picked, reused as the default for the next plan.
  static const _kLastCard = 'ev_last_card_v1';

  static Future<String> lastCardId() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString(_kLastCard);
    return (id != null && _cards.any((c) => c.id == id)) ? id : _adhoc.id;
  }

  static Future<void> setLastCardId(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLastCard, id);
  }
}
