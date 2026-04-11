import { fetchRouteRaw, type Profile } from './routing';

export function downloadGpx(waypoints: [number, number][], profile: Profile): void {
  fetchRouteRaw({ waypoints, profile, format: 'gpx' }).then(gpx => {
    download(gpx, `bikerouter-${profile}.gpx`, 'application/gpx+xml');
  });
}

export function downloadGeojson(geojson: GeoJSON.FeatureCollection): void {
  const str = JSON.stringify(geojson, null, 2);
  download(str, 'bikerouter-route.geojson', 'application/geo+json');
}

function download(content: string, filename: string, mime: string): void {
  const blob = new Blob([content], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

export function encodeRouteToUrl(waypoints: [number, number][], profile: Profile, mode: string): void {
  const pts = waypoints.map(([lng, lat]) => `${lng.toFixed(5)},${lat.toFixed(5)}`).join(';');
  const params = new URLSearchParams({ w: pts, p: profile, m: mode });
  const url = `${window.location.origin}${window.location.pathname}?${params}`;
  window.history.replaceState(null, '', url);
}

export function decodeRouteFromUrl(): {
  waypoints: [number, number][];
  profile: Profile;
  mode: string;
} | null {
  const params = new URLSearchParams(window.location.search);
  const w = params.get('w');
  const p = params.get('p');
  const m = params.get('m');
  if (!w) return null;

  const waypoints = w.split(';').map(s => {
    const [lng, lat] = s.split(',').map(Number);
    return [lng, lat] as [number, number];
  });

  return {
    waypoints,
    profile: (p as Profile) || 'trekking',
    mode: m || 'route',
  };
}
