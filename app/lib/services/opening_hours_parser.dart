/// Minimal OSM `opening_hours` evaluator. Handles the common cases
/// you actually see on shops/fuel/cafés in Europe — full grammar
/// (https://wiki.openstreetmap.org/wiki/Key:opening_hours) is huge,
/// but the core 80% looks like:
///
///   24/7
///   Mo-Fr 08:00-18:00
///   Mo-Fr 06:00-22:00; Sa,Su 08:00-20:00
///   Mo-Su 00:00-24:00
///   PH off
///
/// Anything we can't confidently parse returns [OpenStatus.unknown]
/// so the UI can show "?" instead of guessing.
enum OpenStatus { open, closed, unknown }

class OpeningHoursParser {
  /// Returns the open/closed status of [raw] at [when] in local time.
  /// Public-holiday rules ("PH") are treated as "any weekday" since
  /// we don't ship a holiday calendar — that's a known limitation.
  static OpenStatus evaluate(String? raw, DateTime when) {
    if (raw == null || raw.trim().isEmpty) return OpenStatus.unknown;
    final s = raw.trim();
    if (s == '24/7') return OpenStatus.open;

    // Split into rules separated by ';' or ',' between rule-clauses.
    // We only split on ';' here — comma is used inside day lists.
    final rules = s.split(';').map((r) => r.trim()).where((r) => r.isNotEmpty);

    bool sawApplicable = false;
    for (final rule in rules) {
      final result = _evaluateRule(rule, when);
      if (result == OpenStatus.unknown) continue;
      sawApplicable = true;
      if (result == OpenStatus.open) return OpenStatus.open;
    }
    if (!sawApplicable) return OpenStatus.unknown;
    return OpenStatus.closed;
  }

  /// "Mo-Fr 08:00-18:00" or "Sa off" or "08:00-22:00" (always)
  /// Returns unknown when the rule's day-spec doesn't apply.
  static OpenStatus _evaluateRule(String rule, DateTime when) {
    final lower = rule.toLowerCase();
    if (lower == 'off' || lower == 'closed') return OpenStatus.closed;

    // Split day-spec from time-spec at the first space.
    // "Mo-Fr 08:00-18:00" → days="Mo-Fr", time="08:00-18:00"
    // "08:00-22:00"        → days="",     time="08:00-22:00"
    // "Mo-Fr off"          → days="Mo-Fr", time="off"
    final parts = rule.split(RegExp(r'\s+'));
    String dayPart = '';
    String timePart = '';
    if (parts.length == 1) {
      timePart = parts[0];
    } else {
      dayPart = parts[0];
      timePart = parts.sublist(1).join(' ');
    }

    // Day match. Empty day-part = applies every day.
    if (dayPart.isNotEmpty && !_dayMatches(dayPart, when.weekday)) {
      return OpenStatus.unknown;
    }

    final tl = timePart.toLowerCase();
    if (tl == 'off' || tl == 'closed') return OpenStatus.closed;

    // Time range. Multiple ranges can be comma-separated:
    // "06:00-12:00,14:00-18:00".
    for (final r in timePart.split(',')) {
      if (_timeInRange(r.trim(), when)) return OpenStatus.open;
    }
    return OpenStatus.closed;
  }

  /// "Mo", "Mo-Fr", "Mo,We,Fr", "Sa-Su" — handles list + range, case
  /// insensitive. Returns false for unrecognised inputs.
  static bool _dayMatches(String spec, int weekday) {
    // OSM week: Mo=1 ... Su=7  — matches Dart's DateTime.weekday.
    const map = {
      'mo': 1, 'tu': 2, 'we': 3, 'th': 4, 'fr': 5, 'sa': 6, 'su': 7,
    };
    for (final piece in spec.toLowerCase().split(',')) {
      final p = piece.trim();
      if (p.contains('-')) {
        final ends = p.split('-');
        final a = map[ends[0]];
        final b = map[ends[1]];
        if (a == null || b == null) return false;
        if (a <= b) {
          if (weekday >= a && weekday <= b) return true;
        } else {
          // Wraps Sa-Mo: weekday >= a OR weekday <= b
          if (weekday >= a || weekday <= b) return true;
        }
      } else {
        if (map[p] == weekday) return true;
      }
    }
    return false;
  }

  /// "08:00-18:00" → true if the current time falls inside. "24:00"
  /// at the end is treated as next-midnight, so 22:00-24:00 includes
  /// 23:59. Overnight ranges like 22:00-06:00 wrap correctly.
  static bool _timeInRange(String range, DateTime when) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})-(\d{1,2}):(\d{2})$').firstMatch(range);
    if (m == null) return false;
    final startMin = int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
    final endMin = int.parse(m.group(3)!) * 60 + int.parse(m.group(4)!);
    final nowMin = when.hour * 60 + when.minute;
    if (startMin <= endMin) {
      return nowMin >= startMin && nowMin < endMin;
    }
    // Overnight wrap.
    return nowMin >= startMin || nowMin < endMin;
  }
}
