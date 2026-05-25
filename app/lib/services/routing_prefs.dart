import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Abstract user-facing routing toggles. Each enum value maps to one or
/// more BRouter `profile:xxx=` parameters at request time — the mapping
/// lives in [RoutingPrefs.buildBRouterParams] so the UI stays decoupled
/// from BRouter's naming.
enum RoutingFlag {
  // Universal
  considerElevation,    // wenig Höhenmeter
  avoidSteps,           // Treppen meiden
  avoidFerries,         // Fähren meiden

  // Bike
  avoidMainRoads,       // Bundesstraßen / verkehrsreiche Straßen meiden
  preferCycleRoutes,    // Radwege bevorzugen
  preferQuiet,          // Lärm meiden
  preferForest,         // Wald / Park bevorzugen
  preferRiver,          // Fluss / See entlang
  avoidTowns,           // Städte umfahren
  considerTraffic,      // Verkehrsbewertung aktivieren
  avoidPath,            // Schmale Pfade meiden (gravel-spezifisch)
  avoidSteepInclines,   // steile Anstiege strikt meiden

  // Car
  avoidMotorways,
  avoidToll,
  avoidUnpaved,
  shortestRoute,

  // Hike
  avoidNaturalPaths,    // ground/dirt/grass/mud + low-visibility trails
}

/// Which abstract flags each BRouter profile actually understands. The
/// UI only renders chips for the entries here, so a knob never has zero
/// effect.
const Map<String, Set<RoutingFlag>> _profileCapabilities = {
  // ── Car ─────────────────────────────────────────────────────────────
  'car': {
    RoutingFlag.avoidMotorways,
    RoutingFlag.avoidToll,
    RoutingFlag.avoidUnpaved,
    RoutingFlag.shortestRoute,
  },
  'car-trailer': {
    RoutingFlag.avoidMotorways,
    RoutingFlag.avoidToll,
    RoutingFlag.avoidUnpaved,
    RoutingFlag.shortestRoute,
  },

  // ── Fastbike (road) ─────────────────────────────────────────────────
  'fastbike': {
    RoutingFlag.considerElevation,
    RoutingFlag.avoidSteepInclines,
    RoutingFlag.considerTraffic,
    RoutingFlag.preferQuiet,
    RoutingFlag.preferForest,
    RoutingFlag.preferRiver,
    RoutingFlag.avoidTowns,
    RoutingFlag.avoidSteps,
    RoutingFlag.avoidFerries,
  },
  'fastbike-lowtraffic': {
    RoutingFlag.considerElevation,
    RoutingFlag.avoidSteepInclines,
    RoutingFlag.considerTraffic,
    RoutingFlag.avoidMainRoads,
    RoutingFlag.preferCycleRoutes,
    RoutingFlag.avoidSteps,
    RoutingFlag.avoidFerries,
  },
  'fastbike-verylowtraffic': {
    RoutingFlag.considerElevation,
    RoutingFlag.considerTraffic,
    RoutingFlag.avoidPath,
  },
  'randonneur': {
    RoutingFlag.avoidSteps,
    RoutingFlag.avoidFerries,
  },

  // ── Gravel ──────────────────────────────────────────────────────────
  'm11n-gravel': {
    RoutingFlag.considerElevation,
    RoutingFlag.avoidPath,
  },
  'cxb-gravel': {
    RoutingFlag.considerElevation,
    RoutingFlag.avoidPath,
  },
  'quaelnix-gravel': {
    RoutingFlag.considerElevation,
    RoutingFlag.considerTraffic,
    RoutingFlag.preferCycleRoutes,
    RoutingFlag.avoidSteepInclines,
  },

  // ── Trekking / Safety / E-Bike ──────────────────────────────────────
  'trekking': {
    RoutingFlag.considerElevation,
    RoutingFlag.avoidSteepInclines,
    RoutingFlag.considerTraffic,
    RoutingFlag.avoidMainRoads,
    RoutingFlag.preferCycleRoutes,
    RoutingFlag.preferQuiet,
    RoutingFlag.preferForest,
    RoutingFlag.preferRiver,
    RoutingFlag.avoidTowns,
    RoutingFlag.avoidSteps,
    RoutingFlag.avoidFerries,
  },
  'safety': {
    RoutingFlag.considerElevation,
    RoutingFlag.avoidMainRoads,
    RoutingFlag.preferCycleRoutes,
    RoutingFlag.avoidSteps,
    RoutingFlag.avoidFerries,
  },
  'wegwiesel-ebike': {
    RoutingFlag.considerElevation,
    RoutingFlag.avoidSteepInclines,
    RoutingFlag.considerTraffic,
    RoutingFlag.avoidMainRoads,
    RoutingFlag.preferCycleRoutes,
    RoutingFlag.preferQuiet,
    RoutingFlag.preferForest,
    RoutingFlag.preferRiver,
    RoutingFlag.avoidTowns,
    RoutingFlag.avoidSteps,
    RoutingFlag.avoidFerries,
  },

  // ── MTB ─────────────────────────────────────────────────────────────
  'mtb-zossebart': {
    RoutingFlag.avoidSteps,
    RoutingFlag.avoidFerries,
  },
  'mtb-zossebart-hard': {
    RoutingFlag.avoidSteps,
    RoutingFlag.avoidFerries,
  },

  // Hiking-specific. The Preset + prefer_hiking_routes still live in
  // HikingPrefs for now; avoid_natural_paths is the one new knob added
  // in Phase 2 of the routing-options work.
  'hiking-beta': {
    RoutingFlag.avoidNaturalPaths,
  },
  'wegwiesel-running': {},
  'shortest': {},
};

/// Default value for a flag — most flags are off by default, but a few
/// profiles ship with an opinion (trailer avoids unpaved out of the box).
const Map<String, Map<RoutingFlag, bool>> _profileDefaults = {
  'car-trailer': {RoutingFlag.avoidUnpaved: true},
};

class RoutingPrefs {
  static const _key = 'routing_prefs_v1';
  // profileId → {flagName: bool}. We persist by flag name string so
  // adding/removing/reordering enum values doesn't corrupt saved state.
  static final Map<String, Map<String, bool>> _overrides = {};
  static bool _loaded = false;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        final m = (jsonDecode(raw) as Map).cast<String, dynamic>();
        _overrides.clear();
        for (final e in m.entries) {
          final inner = (e.value as Map).cast<String, dynamic>();
          _overrides[e.key] = {
            for (final f in inner.entries) f.key: f.value as bool,
          };
        }
      } catch (_) {
        // ignore corrupt prefs
      }
    }
    _loaded = true;
  }

  static bool get isLoaded => _loaded;

  /// Which abstract toggles this profile actually has a back-end for.
  /// Returned in a stable order (declaration order in [RoutingFlag])
  /// so the UI doesn't shuffle on rebuild.
  static List<RoutingFlag> applicableFlagsFor(String profileId) {
    final caps = _profileCapabilities[profileId] ?? const <RoutingFlag>{};
    return RoutingFlag.values.where(caps.contains).toList(growable: false);
  }

  static bool flagValue(String profileId, RoutingFlag flag) {
    final saved = _overrides[profileId]?[flag.name];
    if (saved != null) return saved;
    return _profileDefaults[profileId]?[flag] ?? false;
  }

  static Future<void> setFlag(
      String profileId, RoutingFlag flag, bool value) async {
    _overrides.putIfAbsent(profileId, () => {})[flag.name] = value;
    await _persist();
  }

  /// Translate the user's choices into BRouter URL parameters. The
  /// returned string is empty or starts with `&` so it can be appended
  /// directly to the existing profile URL.
  static String buildBRouterParams(String profileId) {
    final flags = _overrides[profileId];
    if (flags == null || flags.isEmpty) {
      // Apply hard-coded defaults (e.g. trailer/avoid_unpaved) so the
      // user can clear an override and still get sane behaviour.
      final defaults = _profileDefaults[profileId];
      if (defaults == null || defaults.isEmpty) return '';
      return _serialise(profileId, {
        for (final e in defaults.entries) e.key.name: e.value,
      });
    }
    return _serialise(profileId, flags);
  }

  static String _serialise(String profileId, Map<String, bool> flags) {
    final caps = _profileCapabilities[profileId] ?? const <RoutingFlag>{};
    final parts = <String>[];
    for (final flag in caps) {
      // Only emit parameters for flags whose value diverges from the
      // BRouter profile's own default. Sending the default explicitly
      // is harmless but pollutes route logs.
      final saved = flags[flag.name];
      final defaultVal = _profileDefaults[profileId]?[flag] ?? false;
      final value = saved ?? defaultVal;
      if (value == defaultVal && !flags.containsKey(flag.name)) continue;
      final mapped = _toBRouterParam(flag, value);
      if (mapped != null) parts.add(mapped);
    }
    return parts.isEmpty ? '' : '&${parts.join('&')}';
  }

  static String? _toBRouterParam(RoutingFlag flag, bool on) {
    // BRouter parses URL-supplied `profile:*=` parameters as numbers
    // and rejects "true"/"false" with `For input string: "true"`. So
    // every bool maps to 1/0 regardless of how the .brf file labels it.
    final v = on ? 1 : 0;
    switch (flag) {
      case RoutingFlag.considerElevation:
        return 'profile:consider_elevation=$v';
      case RoutingFlag.avoidSteps:
        return 'profile:allow_steps=${on ? 0 : 1}';
      case RoutingFlag.avoidFerries:
        return 'profile:allow_ferries=${on ? 0 : 1}';
      case RoutingFlag.avoidMainRoads:
        return 'profile:avoid_unsafe=$v';
      case RoutingFlag.preferCycleRoutes:
        // quaelnix uses prefer_cycle_routes; others use
        // stick_to_cycleroutes. Sending both is harmless — BRouter
        // ignores unknown profile params per-profile.
        return on
            ? 'profile:stick_to_cycleroutes=1&profile:prefer_cycle_routes=1'
            : null;
      case RoutingFlag.preferQuiet:
        return 'profile:consider_noise=$v';
      case RoutingFlag.preferForest:
        return 'profile:consider_forest=$v';
      case RoutingFlag.preferRiver:
        return 'profile:consider_river=$v';
      case RoutingFlag.avoidTowns:
        return 'profile:consider_town=$v';
      case RoutingFlag.considerTraffic:
        return 'profile:consider_traffic=$v';
      case RoutingFlag.avoidPath:
        return 'profile:avoid_path=$v';
      case RoutingFlag.avoidSteepInclines:
        return on ? 'profile:avoid_steep_inclines=1' : null;
      case RoutingFlag.avoidNaturalPaths:
        return on ? 'profile:avoid_natural_paths=1' : null;
      case RoutingFlag.avoidMotorways:
        return on ? 'profile:avoid_motorways=1' : null;
      case RoutingFlag.avoidToll:
        return on ? 'profile:avoid_toll=1' : null;
      case RoutingFlag.avoidUnpaved:
        return 'profile:avoid_unpaved=$v';
      case RoutingFlag.shortestRoute:
        return on ? 'profile:shortest_route=1' : null;
    }
  }

  static Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(_overrides));
  }
}
