import '../l10n/app_localizations.dart';

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

  String localizedName(AppLocalizations l) {
    switch (id) {
      case 'osm':
        return l.mapStyleStandard;
      case 'cyclosm':
        return l.mapStyleCycling;
      case 'topo':
        return l.mapStyleTopo;
      case 'satellite':
        return l.mapStyleSatellite;
      default:
        return name;
    }
  }
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

  String localizedName(AppLocalizations l) {
    switch (id) {
      case 'cycling':
        return l.routeOverlayCycling;
      case 'hiking':
        return l.routeOverlayHiking;
      case 'mtb':
        return l.routeOverlayMtb;
      default:
        return name;
    }
  }
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
