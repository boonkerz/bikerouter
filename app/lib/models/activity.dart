import '../l10n/app_localizations.dart';
import '../models/route_poi.dart';
import '../services/routing_prefs.dart';

/// A user-facing "what are you doing today?" preset. Selecting an
/// activity configures everything underneath in one tap: the BRouter
/// profile, sensible routing-flag defaults, and whether bikepacking
/// mode is on.
///
/// This is an *additive* layer — the underlying profile string is
/// still what gets serialised into saved routes, share links and the
/// watch payload, so nothing downstream needs to know activities
/// exist. The activity is just a friendlier front door than picking a
/// raw BRouter profile.
class Activity {
  final String id;
  final String icon;
  /// The BRouter profile this activity rides on.
  final String profileId;
  /// Routing flags to switch on when the activity is selected. Flags
  /// not listed are left at the profile's own defaults — we only ever
  /// turn things *on* here so picking an activity can't silently strip
  /// a setting the user toggled by hand on the same profile earlier.
  final Set<RoutingFlag> enableFlags;
  /// Whether bikepacking mode (multi-day POI bias) should be on.
  final bool bikepacking;
  /// POI categories to pre-select in the along-route search when this
  /// activity is active. Empty = no opinion (the search defaults to
  /// all categories, the general-purpose behaviour). This is what
  /// makes an activity feel like a *mode* rather than just a profile
  /// switch — "Wandern" surfaces water + shelters, "E-Bike" surfaces
  /// charging, etc.
  final Set<PoiCategory> poiCategories;

  const Activity({
    required this.id,
    required this.icon,
    required this.profileId,
    this.enableFlags = const {},
    this.bikepacking = false,
    this.poiCategories = const {},
  });

  String localizedName(AppLocalizations l) {
    switch (id) {
      case 'tour':
        return l.activityTour;
      case 'commute':
        return l.activityCommute;
      case 'road':
        return l.activityRoad;
      case 'gravel':
        return l.activityGravel;
      case 'mtb':
        return l.activityMtb;
      case 'ebike':
        return l.activityEbike;
      case 'bikepacking':
        return l.activityBikepacking;
      case 'hiking':
        return l.activityHiking;
      case 'running':
        return l.activityRunning;
      case 'ultra':
        return l.activityUltra;
      case 'car':
        return l.activityCar;
      case 'car-trailer':
        return l.activityCarTrailer;
      case 'safety':
        return l.activitySafety;
    }
    return id;
  }

  static Activity? byId(String id) {
    try {
      return activities.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// The activity whose profile matches [profileId], if any — lets the
  /// UI highlight the active activity when a route was loaded from a
  /// saved route / share link that only carries the profile string.
  static Activity? forProfile(String profileId) {
    try {
      return activities.firstWhere((a) => a.profileId == profileId);
    } catch (_) {
      return null;
    }
  }
}

/// The activity catalogue. Order matters — it's the order they show in
/// the picker grid. Kept deliberately short; power users still reach
/// every raw profile + flag through the tune button.
const activities = [
  Activity(
    id: 'tour',
    icon: '🚴',
    profileId: 'trekking',
    enableFlags: {RoutingFlag.preferCycleRoutes},
  ),
  Activity(
    id: 'commute',
    icon: '🚲',
    profileId: 'trekking',
    enableFlags: {
      RoutingFlag.preferCycleRoutes,
      RoutingFlag.avoidMainRoads,
    },
  ),
  Activity(
    id: 'road',
    icon: '🏎️',
    profileId: 'fastbike',
  ),
  Activity(
    id: 'gravel',
    icon: '🪨',
    profileId: 'quaelnix-gravel',
  ),
  Activity(
    id: 'mtb',
    icon: '⛰️',
    profileId: 'mtb-zossebart',
  ),
  Activity(
    id: 'ebike',
    icon: '⚡',
    profileId: 'wegwiesel-ebike',
    enableFlags: {RoutingFlag.preferCycleRoutes},
    poiCategories: {PoiCategory.charging, PoiCategory.water, PoiCategory.food},
  ),
  Activity(
    id: 'safety',
    icon: '🛡️',
    profileId: 'safety',
    enableFlags: {
      RoutingFlag.avoidMainRoads,
      RoutingFlag.preferCycleRoutes,
    },
  ),
  Activity(
    id: 'bikepacking',
    icon: '⛺',
    profileId: 'trekking',
    enableFlags: {RoutingFlag.preferCycleRoutes},
    bikepacking: true,
    poiCategories: {
      PoiCategory.camping,
      PoiCategory.water,
      PoiCategory.shelter,
      PoiCategory.picnic,
      PoiCategory.station,
      PoiCategory.sights,
    },
  ),
  Activity(
    id: 'hiking',
    icon: '🥾',
    profileId: 'hiking-beta',
    poiCategories: {
      PoiCategory.water,
      PoiCategory.shelter,
      PoiCategory.picnic,
      PoiCategory.scenic,
    },
  ),
  Activity(
    id: 'running',
    icon: '🏃',
    profileId: 'wegwiesel-running',
    poiCategories: {PoiCategory.water, PoiCategory.scenic},
  ),
  Activity(
    id: 'ultra',
    icon: '🌙',
    profileId: 'fastbike-lowtraffic',
    enableFlags: {RoutingFlag.avoidMainRoads},
    poiCategories: {
      PoiCategory.fuel,
      PoiCategory.shop,
      PoiCategory.water,
      PoiCategory.charging,
    },
  ),
  Activity(
    id: 'car',
    icon: '🚗',
    profileId: 'car',
    poiCategories: {PoiCategory.fuel, PoiCategory.charging},
  ),
  Activity(
    id: 'car-trailer',
    icon: '🚙',
    profileId: 'car-trailer',
    poiCategories: {PoiCategory.fuel},
  ),
];

/// POI categories preferred by the currently-active activity, or null
/// when no activity is set / the activity has no opinion (search then
/// defaults to all). Resolved from the last-applied activity id.
Set<PoiCategory>? activePoiCategories(String? lastActivityId, String profileId) {
  Activity? a;
  if (lastActivityId != null) {
    final byId = Activity.byId(lastActivityId);
    if (byId != null && byId.profileId == profileId) a = byId;
  }
  a ??= Activity.forProfile(profileId);
  if (a == null || a.poiCategories.isEmpty) return null;
  return a.poiCategories;
}
