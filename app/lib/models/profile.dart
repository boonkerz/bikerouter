import '../l10n/app_localizations.dart';

enum ProfileCategory { road, gravel, trekking, mtb, other }

class BikeProfile {
  final String id;
  final ProfileCategory category;
  final String icon;
  final int avgSpeedKmh;

  const BikeProfile({
    required this.id,
    required this.category,
    required this.icon,
    required this.avgSpeedKmh,
  });

  String localizedName(AppLocalizations l) {
    switch (id) {
      case 'fastbike':
        return l.profileFastbike;
      case 'fastbike-lowtraffic':
        return l.profileFastbikeLowTraffic;
      case 'fastbike-verylowtraffic':
        return l.profileFastbikeVeryLowTraffic;
      case 'randonneur':
        return l.profileRandonneur;
      case 'm11n-gravel':
        return l.profileGravelM11n;
      case 'quaelnix-gravel':
        return l.profileGravelQuaelnix;
      case 'cxb-gravel':
        return l.profileGravelCxb;
      case 'trekking':
        return l.profileTrekking;
      case 'safety':
        return l.profileSafety;
      case 'mtb-zossebart':
        return l.profileMtbZossebart;
      case 'mtb-zossebart-hard':
        return l.profileMtbZossebartHard;
      case 'hiking-beta':
        return l.profileHiking;
      case 'shortest':
        return l.profileShortest;
    }
    return id;
  }

  String localizedCategory(AppLocalizations l) {
    switch (category) {
      case ProfileCategory.road:
        return l.profileCategoryRoad;
      case ProfileCategory.gravel:
        return l.profileCategoryGravel;
      case ProfileCategory.trekking:
        return l.profileCategoryTrekking;
      case ProfileCategory.mtb:
        return l.profileCategoryMtb;
      case ProfileCategory.other:
        return l.profileCategoryOther;
    }
  }

  static BikeProfile? byId(String id) {
    try {
      return profiles.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

const profiles = [
  // Road
  BikeProfile(id: 'fastbike', category: ProfileCategory.road, icon: '🏎️', avgSpeedKmh: 28),
  BikeProfile(id: 'fastbike-lowtraffic', category: ProfileCategory.road, icon: '🏎️', avgSpeedKmh: 27),
  BikeProfile(id: 'fastbike-verylowtraffic', category: ProfileCategory.road, icon: '🏎️', avgSpeedKmh: 26),
  BikeProfile(id: 'randonneur', category: ProfileCategory.road, icon: '🏎️', avgSpeedKmh: 25),
  // Gravel
  BikeProfile(id: 'm11n-gravel', category: ProfileCategory.gravel, icon: '🪨', avgSpeedKmh: 22),
  BikeProfile(id: 'quaelnix-gravel', category: ProfileCategory.gravel, icon: '🪨', avgSpeedKmh: 22),
  BikeProfile(id: 'cxb-gravel', category: ProfileCategory.gravel, icon: '🪨', avgSpeedKmh: 22),
  // Trekking
  BikeProfile(id: 'trekking', category: ProfileCategory.trekking, icon: '🚲', avgSpeedKmh: 18),
  BikeProfile(id: 'safety', category: ProfileCategory.trekking, icon: '🛡️', avgSpeedKmh: 16),
  // MTB
  BikeProfile(id: 'mtb-zossebart', category: ProfileCategory.mtb, icon: '⛰️', avgSpeedKmh: 15),
  BikeProfile(id: 'mtb-zossebart-hard', category: ProfileCategory.mtb, icon: '⛰️', avgSpeedKmh: 13),
  // Other
  BikeProfile(id: 'hiking-beta', category: ProfileCategory.other, icon: '🥾', avgSpeedKmh: 5),
  BikeProfile(id: 'shortest', category: ProfileCategory.other, icon: '📏', avgSpeedKmh: 20),
];

const quickProfiles = ['fastbike', 'quaelnix-gravel', 'trekking', 'mtb-zossebart'];
