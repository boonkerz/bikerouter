import maplibregl from 'maplibre-gl';

const STYLE_URL = 'https://tiles.openfreemap.org/styles/liberty';

export function createMap(container: string): maplibregl.Map {
  const map = new maplibregl.Map({
    container,
    style: STYLE_URL,
    center: [10.45, 51.16], // Germany center
    zoom: 6,
    attributionControl: {},
  });

  map.addControl(new maplibregl.NavigationControl(), 'top-right');
  map.addControl(new maplibregl.GeolocateControl({
    positionOptions: { enableHighAccuracy: true },
    trackUserLocation: false,
  }), 'top-right');
  map.addControl(new maplibregl.ScaleControl({ unit: 'metric' }), 'bottom-left');

  return map;
}

export function addRouteLayer(map: maplibregl.Map): void {
  map.addSource('route', {
    type: 'geojson',
    data: { type: 'FeatureCollection', features: [] },
  });

  // Route outline (wider, darker)
  map.addLayer({
    id: 'route-outline',
    type: 'line',
    source: 'route',
    layout: { 'line-join': 'round', 'line-cap': 'round' },
    paint: {
      'line-color': '#1565c0',
      'line-width': 8,
      'line-opacity': 0.4,
    },
  });

  // Route line
  map.addLayer({
    id: 'route-line',
    type: 'line',
    source: 'route',
    layout: { 'line-join': 'round', 'line-cap': 'round' },
    paint: {
      'line-color': '#4fc3f7',
      'line-width': 4,
      'line-opacity': 0.9,
    },
  });
}

export function updateRoute(map: maplibregl.Map, geojson: GeoJSON.FeatureCollection): void {
  const source = map.getSource('route') as maplibregl.GeoJSONSource;
  if (source) {
    source.setData(geojson);
  }
}

export function clearRoute(map: maplibregl.Map): void {
  updateRoute(map, { type: 'FeatureCollection', features: [] });
}

export function fitRouteBounds(map: maplibregl.Map, coordinates: [number, number, number][]): void {
  if (coordinates.length === 0) return;
  const bounds = new maplibregl.LngLatBounds();
  for (const [lng, lat] of coordinates) {
    bounds.extend([lng, lat]);
  }
  map.fitBounds(bounds, { padding: 60, maxZoom: 15 });
}

export function createMarkerElement(type: 'start' | 'end' | 'via', label?: string): HTMLElement {
  const el = document.createElement('div');
  el.className = `marker-${type}`;
  el.textContent = label ?? (type === 'start' ? 'A' : type === 'end' ? 'B' : '·');
  return el;
}

export function createHoverMarker(map: maplibregl.Map): maplibregl.Marker {
  const el = document.createElement('div');
  el.className = 'marker-hover';
  return new maplibregl.Marker({ element: el }).setLngLat([0, 0]).addTo(map);
}
