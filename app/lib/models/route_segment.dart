import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// A run of consecutive route coordinates sharing the same OSM way tags.
class RouteSegment {
  final int startCoordIdx;
  final int endCoordIdx;
  final double startDistanceKm;
  final double endDistanceKm;
  final String wayTagsRaw;
  final double costPerKm;

  const RouteSegment({
    required this.startCoordIdx,
    required this.endCoordIdx,
    required this.startDistanceKm,
    required this.endDistanceKm,
    required this.wayTagsRaw,
    this.costPerKm = 0,
  });

  Map<String, String> get tags {
    final result = <String, String>{};
    for (final kv in wayTagsRaw.split(' ')) {
      final eq = kv.indexOf('=');
      if (eq > 0) result[kv.substring(0, eq)] = kv.substring(eq + 1);
    }
    return result;
  }

  String? get surface => tags['surface'];
  String? get highway => tags['highway'];
  String? get trackType => tags['tracktype'];
  String? get smoothness => tags['smoothness'];
  String? get maxSpeedRaw => tags['maxspeed'];

  /// Parses maxspeed tag. Supports plain numbers (km/h assumed) and "X mph".
  /// Returns null for tags like "walk", "signals", "none".
  double? get maxSpeedKmh {
    final raw = maxSpeedRaw;
    if (raw == null) return null;
    final s = raw.toLowerCase().trim();
    if (s == 'none') return 200;
    if (s == 'walk') return 7;
    if (s == 'signals' || s == 'variable') return null;
    final mph = RegExp(r'^(\d+(?:\.\d+)?)\s*mph$').firstMatch(s);
    if (mph != null) {
      return double.parse(mph.group(1)!) * 1.60934;
    }
    final num = RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(s);
    if (num != null) return double.parse(num.group(1)!);
    return null;
  }

  double get lengthKm => endDistanceKm - startDistanceKm;

  /// Broad surface category used for color coding.
  SurfaceCategory get category {
    final s = surface;
    final h = highway;
    if (s != null) {
      if (_paved.contains(s)) return SurfaceCategory.asphalt;
      if (_cobble.contains(s)) return SurfaceCategory.pavingStones;
      if (_gravel.contains(s)) return SurfaceCategory.gravel;
      if (_unpaved.contains(s)) return SurfaceCategory.unpaved;
      if (_offroad.contains(s)) return SurfaceCategory.offroad;
    }
    if (h != null) {
      if (_pavedHighways.contains(h)) return SurfaceCategory.asphalt;
      if (h == 'track') {
        final tt = trackType;
        if (tt == 'grade1') return SurfaceCategory.asphalt;
        if (tt == 'grade2') return SurfaceCategory.gravel;
        if (tt == 'grade3') return SurfaceCategory.unpaved;
        if (tt == 'grade4' || tt == 'grade5') return SurfaceCategory.offroad;
        return SurfaceCategory.unpaved;
      }
      if (h == 'path' || h == 'footway' || h == 'bridleway') {
        return SurfaceCategory.offroad;
      }
      if (h == 'cycleway' || h == 'pedestrian' || h == 'living_street') {
        return SurfaceCategory.asphalt;
      }
    }
    return SurfaceCategory.unknown;
  }

  HighwayCategory get highwayCategory {
    final h = highway;
    if (h == null) return HighwayCategory.unknown;
    if (h == 'motorway' || h == 'motorway_link' || h == 'trunk' || h == 'trunk_link') {
      return HighwayCategory.motorway;
    }
    if (h == 'primary' || h == 'primary_link' || h == 'secondary' || h == 'secondary_link') {
      return HighwayCategory.primary;
    }
    if (h == 'tertiary' || h == 'tertiary_link' || h == 'unclassified') {
      return HighwayCategory.tertiary;
    }
    if (h == 'residential' || h == 'living_street' || h == 'service') {
      return HighwayCategory.residential;
    }
    if (h == 'cycleway') return HighwayCategory.cycleway;
    if (h == 'track') return HighwayCategory.track;
    if (h == 'path' || h == 'footway' || h == 'bridleway' || h == 'pedestrian' || h == 'steps') {
      return HighwayCategory.path;
    }
    return HighwayCategory.unknown;
  }

  SmoothnessCategory get smoothnessCategory {
    final s = smoothness;
    if (s == null) return SmoothnessCategory.unknown;
    switch (s) {
      case 'excellent':
        return SmoothnessCategory.excellent;
      case 'good':
        return SmoothnessCategory.good;
      case 'intermediate':
        return SmoothnessCategory.intermediate;
      case 'bad':
        return SmoothnessCategory.bad;
      case 'very_bad':
      case 'horrible':
      case 'very_horrible':
      case 'impassable':
        return SmoothnessCategory.bad;
    }
    return SmoothnessCategory.unknown;
  }

  static const _paved = {'asphalt', 'paved', 'concrete', 'concrete:lanes', 'concrete:plates', 'chipseal', 'metal'};
  static const _cobble = {'paving_stones', 'sett', 'cobblestone', 'unhewn_cobblestone', 'bricks'};
  static const _gravel = {'compacted', 'fine_gravel', 'gravel', 'pebblestone'};
  static const _unpaved = {'unpaved', 'ground', 'dirt', 'earth'};
  static const _offroad = {'grass', 'grass_paver', 'mud', 'sand', 'woodchips', 'rock'};
  static const _pavedHighways = {
    'motorway', 'trunk', 'primary', 'secondary', 'tertiary',
    'unclassified', 'residential', 'service', 'motorway_link',
    'trunk_link', 'primary_link', 'secondary_link', 'tertiary_link',
  };
}

enum SurfaceCategory {
  asphalt,
  pavingStones,
  gravel,
  unpaved,
  offroad,
  unknown,
}

extension SurfaceCategoryX on SurfaceCategory {
  Color get color {
    switch (this) {
      case SurfaceCategory.asphalt:
        return const Color(0xFF1E88E5);
      case SurfaceCategory.pavingStones:
        return const Color(0xFFEF6C00);
      case SurfaceCategory.gravel:
        return const Color(0xFFFBC02D);
      case SurfaceCategory.unpaved:
        return const Color(0xFF795548);
      case SurfaceCategory.offroad:
        return const Color(0xFF7CB342);
      case SurfaceCategory.unknown:
        return const Color(0xFF9E9E9E);
    }
  }

  String localizedLabel(AppLocalizations l) {
    switch (this) {
      case SurfaceCategory.asphalt:
        return l.surfaceCategoryAsphalt;
      case SurfaceCategory.pavingStones:
        return l.surfaceCategoryPavingStones;
      case SurfaceCategory.gravel:
        return l.surfaceCategoryGravel;
      case SurfaceCategory.unpaved:
        return l.surfaceCategoryUnpaved;
      case SurfaceCategory.offroad:
        return l.surfaceCategoryOffroad;
      case SurfaceCategory.unknown:
        return l.surfaceCategoryUnknown;
    }
  }
}

enum HighwayCategory {
  motorway,
  primary,
  tertiary,
  residential,
  cycleway,
  track,
  path,
  unknown,
}

extension HighwayCategoryX on HighwayCategory {
  Color get color {
    switch (this) {
      case HighwayCategory.motorway:
        return const Color(0xFFD32F2F);
      case HighwayCategory.primary:
        return const Color(0xFFF57C00);
      case HighwayCategory.tertiary:
        return const Color(0xFFFBC02D);
      case HighwayCategory.residential:
        return const Color(0xFF9E9E9E);
      case HighwayCategory.cycleway:
        return const Color(0xFF43A047);
      case HighwayCategory.track:
        return const Color(0xFF8D6E63);
      case HighwayCategory.path:
        return const Color(0xFF7CB342);
      case HighwayCategory.unknown:
        return const Color(0xFF616161);
    }
  }

  String localizedLabel(AppLocalizations l) {
    switch (this) {
      case HighwayCategory.motorway:
        return l.highwayMotorway;
      case HighwayCategory.primary:
        return l.highwayPrimary;
      case HighwayCategory.tertiary:
        return l.highwayTertiary;
      case HighwayCategory.residential:
        return l.highwayResidential;
      case HighwayCategory.cycleway:
        return l.highwayCycleway;
      case HighwayCategory.track:
        return l.highwayTrack;
      case HighwayCategory.path:
        return l.highwayPath;
      case HighwayCategory.unknown:
        return l.highwayUnknown;
    }
  }
}

enum SmoothnessCategory {
  excellent,
  good,
  intermediate,
  bad,
  unknown,
}

extension SmoothnessCategoryX on SmoothnessCategory {
  Color get color {
    switch (this) {
      case SmoothnessCategory.excellent:
        return const Color(0xFF2E7D32);
      case SmoothnessCategory.good:
        return const Color(0xFF7CB342);
      case SmoothnessCategory.intermediate:
        return const Color(0xFFFBC02D);
      case SmoothnessCategory.bad:
        return const Color(0xFFD32F2F);
      case SmoothnessCategory.unknown:
        return const Color(0xFF9E9E9E);
    }
  }

  String localizedLabel(AppLocalizations l) {
    switch (this) {
      case SmoothnessCategory.excellent:
        return l.smoothnessExcellent;
      case SmoothnessCategory.good:
        return l.smoothnessGood;
      case SmoothnessCategory.intermediate:
        return l.smoothnessIntermediate;
      case SmoothnessCategory.bad:
        return l.smoothnessBad;
      case SmoothnessCategory.unknown:
        return l.smoothnessUnknown;
    }
  }
}
