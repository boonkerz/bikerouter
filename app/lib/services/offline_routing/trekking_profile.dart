import 'offline_routing_graph.dart';

class TrekkingProfile {
  const TrekkingProfile();

  static const supportedProfile = 'trekking';

  bool supports(String profile) => profile == supportedProfile;

  bool allows(OfflineRoutingEdge edge) {
    final tags = edge.tags;
    final highway = tags['highway'];
    if (highway == null) return false;

    final access = tags['access'];
    final bicycle = tags['bicycle'];
    if (access == 'private' || access == 'no') return bicycle == 'yes';
    if (bicycle == 'no') return false;

    if (highway == 'motorway' ||
        highway == 'motorway_link' ||
        highway == 'trunk' ||
        highway == 'trunk_link') {
      return bicycle == 'yes';
    }
    if (highway == 'steps' || highway == 'construction') return false;

    return true;
  }

  double costSeconds(OfflineRoutingEdge edge, double elevationGainMeters) {
    final speedKmh = _speedKmh(edge.tags);
    final baseSeconds = edge.distanceMeters / (speedKmh * 1000 / 3600);
    final surfacePenalty = _surfacePenalty(edge.tags);
    final climbPenalty =
        elevationGainMeters > 0 ? elevationGainMeters * 8.0 : 0;
    return baseSeconds * surfacePenalty + climbPenalty;
  }

  double _speedKmh(Map<String, String> tags) {
    final highway = tags['highway'];
    switch (highway) {
      case 'cycleway':
        return 22;
      case 'primary':
      case 'secondary':
      case 'tertiary':
        return 20;
      case 'residential':
      case 'unclassified':
      case 'service':
        return 18;
      case 'track':
      case 'path':
      case 'bridleway':
        return 14;
      case 'footway':
      case 'pedestrian':
        return 9;
      default:
        return 16;
    }
  }

  double _surfacePenalty(Map<String, String> tags) {
    final surface = tags['surface'];
    switch (surface) {
      case 'asphalt':
      case 'paved':
      case 'concrete':
        return 1.0;
      case 'compacted':
      case 'fine_gravel':
        return 1.15;
      case 'gravel':
      case 'unpaved':
        return 1.35;
      case 'dirt':
      case 'ground':
      case 'grass':
      case 'sand':
        return 1.7;
      default:
        return 1.1;
    }
  }
}
