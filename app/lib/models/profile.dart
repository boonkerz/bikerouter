class BikeProfile {
  final String id;
  final String name;
  final String category;
  final String icon;
  final int avgSpeedKmh;

  const BikeProfile({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.avgSpeedKmh,
  });

  static BikeProfile? byId(String id) {
    try {
      return profiles.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

const profiles = [
  // Rennrad
  BikeProfile(id: 'fastbike', name: 'Rennrad', category: 'Rennrad', icon: '🏎️', avgSpeedKmh: 28),
  BikeProfile(id: 'fastbike-lowtraffic', name: 'Rennrad (weniger Verkehr)', category: 'Rennrad', icon: '🏎️', avgSpeedKmh: 27),
  BikeProfile(id: 'fastbike-verylowtraffic', name: 'Rennrad (sehr wenig Verkehr)', category: 'Rennrad', icon: '🏎️', avgSpeedKmh: 26),
  BikeProfile(id: 'randonneur', name: 'Randonneur', category: 'Rennrad', icon: '🏎️', avgSpeedKmh: 25),
  // Gravel
  BikeProfile(id: 'm11n-gravel', name: 'Gravel „m11n“ (mehr offroad)', category: 'Gravel', icon: '🪨', avgSpeedKmh: 22),
  BikeProfile(id: 'quaelnix-gravel', name: 'Gravel „quaelnix“ (wenig Verkehr)', category: 'Gravel', icon: '🪨', avgSpeedKmh: 22),
  BikeProfile(id: 'cxb-gravel', name: 'Gravel „CXB“ (mehr offroad)', category: 'Gravel', icon: '🪨', avgSpeedKmh: 22),
  // Trekking
  BikeProfile(id: 'trekking', name: 'Trekkingrad', category: 'Trekking', icon: '🚲', avgSpeedKmh: 18),
  BikeProfile(id: 'safety', name: 'Sicherste Route', category: 'Trekking', icon: '🛡️', avgSpeedKmh: 16),
  // MTB
  BikeProfile(id: 'mtb-zossebart', name: 'MTB „Zossebart“', category: 'MTB', icon: '⛰️', avgSpeedKmh: 15),
  BikeProfile(id: 'mtb-zossebart-hard', name: 'MTB „Zossebart“ (hart)', category: 'MTB', icon: '⛰️', avgSpeedKmh: 13),
  // Sonstige
  BikeProfile(id: 'hiking-beta', name: 'Wandern (beta)', category: 'Sonstige', icon: '🥾', avgSpeedKmh: 5),
  BikeProfile(id: 'shortest', name: 'Kürzeste Route', category: 'Sonstige', icon: '📏', avgSpeedKmh: 20),
];

const quickProfiles = ['fastbike', 'quaelnix-gravel', 'trekking', 'mtb-zossebart'];
