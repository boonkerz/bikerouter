class BikeProfile {
  final String id;
  final String name;
  final String category;
  final String icon;

  const BikeProfile({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
  });
}

const profiles = [
  // Rennrad
  BikeProfile(id: 'fastbike', name: 'Rennrad', category: 'Rennrad', icon: '🏎️'),
  BikeProfile(id: 'fastbike-lowtraffic', name: 'Wenig Verkehr', category: 'Rennrad', icon: '🏎️'),
  BikeProfile(id: 'fastbike-verylowtraffic', name: 'Sehr wenig Verkehr', category: 'Rennrad', icon: '🏎️'),
  BikeProfile(id: 'randonneur', name: 'Randonneur', category: 'Rennrad', icon: '🏎️'),
  // Gravel
  BikeProfile(id: 'quaelnix-gravel', name: 'Gravel (quaelnix)', category: 'Gravel', icon: '🪨'),
  BikeProfile(id: 'm11n-gravel', name: 'Gravel (m11n)', category: 'Gravel', icon: '🪨'),
  BikeProfile(id: 'cxb-gravel', name: 'Gravel (cxb)', category: 'Gravel', icon: '🪨'),
  // Trekking
  BikeProfile(id: 'trekking', name: 'Trekking', category: 'Trekking', icon: '🚲'),
  BikeProfile(id: 'safety', name: 'Sicherste Route', category: 'Trekking', icon: '🛡️'),
  // MTB
  BikeProfile(id: 'mtb-zossebart', name: 'MTB', category: 'MTB', icon: '⛰️'),
  BikeProfile(id: 'mtb-zossebart-hard', name: 'MTB (hart)', category: 'MTB', icon: '⛰️'),
  // Sonstige
  BikeProfile(id: 'hiking-beta', name: 'Wandern', category: 'Sonstige', icon: '🥾'),
  BikeProfile(id: 'shortest', name: 'Kürzeste', category: 'Sonstige', icon: '📏'),
];

const quickProfiles = ['fastbike', 'quaelnix-gravel', 'trekking', 'mtb-zossebart'];
