import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// A run of consecutive route coordinates sharing the same OSM way tags.
class RouteSegment {
  final int startCoordIdx;
  final int endCoordIdx;
  final double startDistanceKm;
  final double endDistanceKm;
  final String wayTagsRaw;

  const RouteSegment({
    required this.startCoordIdx,
    required this.endCoordIdx,
    required this.startDistanceKm,
    required this.endDistanceKm,
    required this.wayTagsRaw,
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

  double get lengthKm => endDistanceKm - startDistanceKm;

  /// Broad category used for color coding.
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
    // Fall back to highway class
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
