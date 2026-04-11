export type Profile = string;
export type RouteFormat = 'geojson' | 'gpx' | 'kml';

export interface RouteOptions {
  waypoints: [number, number][];
  profile: Profile;
  alternativeIdx?: number;
  format?: RouteFormat;
}

export interface RoundtripOptions {
  start: [number, number];
  profile: Profile;
  distance: number; // meters
  direction?: number; // 0-360 degrees
  format?: RouteFormat;
}

export interface RouteResult {
  geojson: GeoJSON.FeatureCollection;
  distance: number; // km
  ascent: number; // m
  descent: number; // m
  time: number; // seconds
  coordinates: [number, number, number][]; // [lon, lat, elevation]
}

const BROUTER_BASE = '/brouter';

function buildRouteUrl(opts: RouteOptions): string {
  const lonlats = opts.waypoints.map(([lng, lat]) => `${lng},${lat}`).join('|');
  const params = new URLSearchParams({
    lonlats,
    profile: opts.profile,
    alternativeidx: String(opts.alternativeIdx ?? 0),
    format: 'geojson',
    timode: '3',
  });
  return `${BROUTER_BASE}?${params}`;
}

function buildRoundtripUrl(opts: RoundtripOptions): string {
  const params = new URLSearchParams({
    lonlats: `${opts.start[0]},${opts.start[1]}`,
    profile: opts.profile,
    engineMode: '4',
    roundTripDistance: String(opts.distance),
    format: 'geojson',
    timode: '3',
  });
  if (opts.direction !== undefined) {
    params.set('direction', String(opts.direction));
  }
  return `${BROUTER_BASE}?${params}`;
}

function parseRouteResult(geojson: GeoJSON.FeatureCollection): RouteResult {
  const feature = geojson.features[0];
  if (!feature || feature.geometry.type !== 'LineString') {
    throw new Error('Invalid route response');
  }

  const coords = (feature.geometry as GeoJSON.LineString).coordinates as [number, number, number][];
  const props = feature.properties || {};

  // Calculate distance from coordinates if not in properties
  let distance = 0;
  if (props['track-length']) {
    distance = parseFloat(props['track-length']) / 1000;
  } else {
    for (let i = 1; i < coords.length; i++) {
      distance += haversine(coords[i - 1], coords[i]);
    }
  }

  // Calculate elevation stats
  let ascent = 0;
  let descent = 0;
  if (props['filtered ascend']) {
    ascent = parseFloat(props['filtered ascend']);
  }
  if (props['plain-ascend']) {
    ascent = parseFloat(props['plain-ascend']);
  }

  // If no ascent in properties, calculate from coordinates
  if (!ascent) {
    for (let i = 1; i < coords.length; i++) {
      const diff = coords[i][2] - coords[i - 1][2];
      if (diff > 0) ascent += diff;
      else descent += Math.abs(diff);
    }
  } else {
    // Calculate descent from coordinates
    for (let i = 1; i < coords.length; i++) {
      const diff = coords[i][2] - coords[i - 1][2];
      if (diff < 0) descent += Math.abs(diff);
    }
  }

  const time = props['total-time'] ? parseFloat(props['total-time']) : (distance / 20) * 3600;

  return { geojson, distance, ascent, descent, time, coordinates: coords };
}

function haversine(a: [number, number, number], b: [number, number, number]): number {
  const R = 6371;
  const dLat = (b[1] - a[1]) * Math.PI / 180;
  const dLon = (b[0] - a[0]) * Math.PI / 180;
  const lat1 = a[1] * Math.PI / 180;
  const lat2 = b[1] * Math.PI / 180;
  const x = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x));
}

export async function calculateRoute(opts: RouteOptions): Promise<RouteResult> {
  const url = buildRouteUrl(opts);
  const res = await fetch(url);
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Routing failed: ${text}`);
  }
  const geojson = await res.json();
  return parseRouteResult(geojson);
}

export async function calculateRoundtrip(opts: RoundtripOptions): Promise<RouteResult> {
  const url = buildRoundtripUrl(opts);
  const res = await fetch(url);
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Roundtrip failed: ${text}`);
  }
  const geojson = await res.json();
  return parseRouteResult(geojson);
}

export async function fetchRouteRaw(opts: RouteOptions & { format: RouteFormat }): Promise<string> {
  const lonlats = opts.waypoints.map(([lng, lat]) => `${lng},${lat}`).join('|');
  const params = new URLSearchParams({
    lonlats,
    profile: opts.profile,
    alternativeidx: String(opts.alternativeIdx ?? 0),
    format: opts.format,
    timode: '3',
  });
  const res = await fetch(`${BROUTER_BASE}?${params}`);
  if (!res.ok) throw new Error('Export failed');
  return res.text();
}
