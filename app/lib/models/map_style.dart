class MapStyle {
  final String id;
  final String name;
  final String icon;
  final String urlTemplate;
  final String attribution;
  final int maxZoom;
  final String? labelsOverlay;

  const MapStyle({
    required this.id,
    required this.name,
    required this.icon,
    required this.urlTemplate,
    required this.attribution,
    this.maxZoom = 19,
    this.labelsOverlay,
  });
}

class RouteOverlay {
  final String id;
  final String name;
  final String icon;
  final String urlTemplate;

  const RouteOverlay({
    required this.id,
    required this.name,
    required this.icon,
    required this.urlTemplate,
  });
}

const routeOverlays = [
  RouteOverlay(
    id: 'cycling',
    name: 'Radrouten',
    icon: '🚴',
    urlTemplate: 'https://tile.waymarkedtrails.org/cycling/{z}/{x}/{y}.png',
  ),
  RouteOverlay(
    id: 'hiking',
    name: 'Wanderwege',
    icon: '🥾',
    urlTemplate: 'https://tile.waymarkedtrails.org/hiking/{z}/{x}/{y}.png',
  ),
  RouteOverlay(
    id: 'mtb',
    name: 'MTB-Routen',
    icon: '⛰️',
    urlTemplate: 'https://tile.waymarkedtrails.org/mtb/{z}/{x}/{y}.png',
  ),
];

const mapStyles = [
  MapStyle(
    id: 'osm',
    name: 'Standard',
    icon: '🗺️',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19,
  ),
  MapStyle(
    id: 'cyclosm',
    name: 'Fahrrad',
    icon: '🚲',
    urlTemplate: 'https://a.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
    attribution: '© CyclOSM / OpenStreetMap contributors',
    maxZoom: 20,
  ),
  MapStyle(
    id: 'topo',
    name: 'Topo',
    icon: '⛰️',
    urlTemplate: 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
    attribution: '© OpenTopoMap / OpenStreetMap contributors',
    maxZoom: 17,
  ),
  MapStyle(
    id: 'satellite',
    name: 'Satellit',
    icon: '🛰️',
    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: '© Esri',
    maxZoom: 19,
    labelsOverlay: 'https://a.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png',
  ),
];
