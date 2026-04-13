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
  BikeProfile(id: 'fastbike-lowtraffic', name: 'Wenig Verkehr', category: 'Rennrad', icon: '🏎️', avgSpeedKmh: 27),
  BikeProfile(id: 'fastbike-verylowtraffic', name: 'Sehr wenig Verkehr', category: 'Rennrad', icon: '🏎️', avgSpeedKmh: 26),
  BikeProfile(id: 'randonneur', name: 'Randonneur', category: 'Rennrad', icon: '🏎️', avgSpeedKmh: 25),
  // Gravel
  BikeProfile(id: 'quaelnix-gravel', name: 'Gravel (quaelnix)', category: 'Gravel', icon: '🪨', avgSpeedKmh: 22),
  BikeProfile(id: 'm11n-gravel', name: 'Gravel (m11n)', category: 'Gravel', icon: '🪨', avgSpeedKmh: 22),
  BikeProfile(id: 'cxb-gravel', name: 'Gravel (cxb)', category: 'Gravel', icon: '🪨', avgSpeedKmh: 22),
  // Trekking
  BikeProfile(id: 'trekking', name: 'Trekking', category: 'Trekking', icon: '🚲', avgSpeedKmh: 18),
  BikeProfile(id: 'safety', name: 'Sicherste Route', category: 'Trekking', icon: '🛡️', avgSpeedKmh: 16),
  // MTB
  BikeProfile(id: 'mtb-zossebart', name: 'MTB', category: 'MTB', icon: '⛰️', avgSpeedKmh: 15),
  BikeProfile(id: 'mtb-zossebart-hard', name: 'MTB (hart)', category: 'MTB', icon: '⛰️', avgSpeedKmh: 13),
  // Sonstige
  BikeProfile(id: 'hiking-beta', name: 'Wandern', category: 'Sonstige', icon: '🥾', avgSpeedKmh: 5),
  BikeProfile(id: 'shortest', name: 'Kürzeste', category: 'Sonstige', icon: '📏', avgSpeedKmh: 20),
];

const quickProfiles = ['fastbike', 'quaelnix-gravel', 'trekking', 'mtb-zossebart'];
