import maplibregl from 'maplibre-gl';
import { createMap, addRouteLayer, updateRoute, clearRoute, fitRouteBounds, createMarkerElement, createHoverMarker } from './map';
import { calculateRoute, calculateRoundtrip, type Profile, type RouteResult } from './routing';
import { renderElevation, clearElevation, setHoverCallback } from './elevation';
import { downloadGpx, downloadGeojson, encodeRouteToUrl, decodeRouteFromUrl } from './export';

// State
let map: maplibregl.Map;
let mode: 'route' | 'roundtrip' = 'route';
let profile: Profile = 'fastbike';
let waypoints: { lngLat: [number, number]; marker: maplibregl.Marker }[] = [];
let currentRoute: RouteResult | null = null;
let hoverMarker: maplibregl.Marker | null = null;
let isCalculating = false;

// DOM refs
const waypointsList = document.getElementById('waypoints-list')!;
const waypointsPanel = document.getElementById('waypoints-panel')!;
const roundtripPanel = document.getElementById('roundtrip-panel')!;
const statsPanel = document.getElementById('stats-panel')!;
const exportPanel = document.getElementById('export-panel')!;
const elevationContainer = document.getElementById('elevation-container')!;
const clearRouteBtn = document.getElementById('clear-route')!;

function init(): void {
  map = createMap('map');

  map.on('load', () => {
    addRouteLayer(map);
    hoverMarker = createHoverMarker(map);
    hoverMarker.getElement().style.display = 'none';

    setupMapInteraction();
    setupControls();
    restoreFromUrl();
    showHint();
  });
}

function showHint(): void {
  const hint = document.createElement('div');
  hint.className = 'map-hint';
  hint.textContent = 'Klicke auf die Karte um Wegpunkte zu setzen';
  document.getElementById('map-container')!.appendChild(hint);
  setTimeout(() => { hint.style.opacity = '0'; setTimeout(() => hint.remove(), 300); }, 4000);
}

function setupMapInteraction(): void {
  map.on('click', (e: maplibregl.MapMouseEvent) => {
    const lngLat: [number, number] = [e.lngLat.lng, e.lngLat.lat];

    if (mode === 'route') {
      addWaypoint(lngLat);
    } else {
      // Roundtrip: only one start point
      clearAllWaypoints();
      addWaypoint(lngLat);
    }
  });

  // Cursor style when hovering route
  map.on('mouseenter', 'route-line', () => {
    map.getCanvas().style.cursor = 'pointer';
  });
  map.on('mouseleave', 'route-line', () => {
    map.getCanvas().style.cursor = '';
  });

  // Click on route to add via point
  map.on('click', 'route-line', (e: maplibregl.MapMouseEvent) => {
    if (mode !== 'route' || waypoints.length < 2) return;
    e.preventDefault();
    const lngLat: [number, number] = [e.lngLat.lng, e.lngLat.lat];
    insertViaPoint(lngLat);
  });
}

function addWaypoint(lngLat: [number, number]): void {
  const idx = waypoints.length;
  const type = idx === 0 ? 'start' : 'end';
  const label = idx === 0 ? 'A' : String.fromCharCode(65 + idx);

  // If adding a third+ point, relabel the previous "end" as "via"
  if (idx >= 2) {
    const prev = waypoints[idx - 1];
    const prevEl = createMarkerElement('via', '·');
    prev.marker.getElement().replaceWith(prevEl);
    prev.marker = new maplibregl.Marker({ element: prevEl, draggable: true })
      .setLngLat(prev.lngLat)
      .addTo(map);
    setupMarkerDrag(prev, idx - 1);
  }

  const el = createMarkerElement(type, label);
  const marker = new maplibregl.Marker({ element: el, draggable: true })
    .setLngLat(lngLat)
    .addTo(map);

  const wp = { lngLat, marker };
  waypoints.push(wp);
  setupMarkerDrag(wp, idx);
  updateWaypointsList();

  if (mode === 'route' && waypoints.length >= 2) {
    recalculateRoute();
  }
}

function insertViaPoint(lngLat: [number, number]): void {
  // Find the best position to insert (between which existing waypoints)
  let bestIdx = 1;
  let bestDist = Infinity;

  for (let i = 1; i < waypoints.length; i++) {
    const a = waypoints[i - 1].lngLat;
    const b = waypoints[i].lngLat;
    const dist = pointToSegmentDist(lngLat, a, b);
    if (dist < bestDist) {
      bestDist = dist;
      bestIdx = i;
    }
  }

  const el = createMarkerElement('via', '·');
  const marker = new maplibregl.Marker({ element: el, draggable: true })
    .setLngLat(lngLat)
    .addTo(map);

  const wp = { lngLat, marker };
  waypoints.splice(bestIdx, 0, wp);

  // Re-setup drag handlers and labels
  relabelMarkers();
  recalculateRoute();
}

function setupMarkerDrag(wp: { lngLat: [number, number]; marker: maplibregl.Marker }, _idx: number): void {
  wp.marker.on('dragend', () => {
    const pos = wp.marker.getLngLat();
    wp.lngLat = [pos.lng, pos.lat];
    if (mode === 'route' && waypoints.length >= 2) {
      recalculateRoute();
    }
  });
}

function removeWaypoint(idx: number): void {
  const wp = waypoints[idx];
  wp.marker.remove();
  waypoints.splice(idx, 1);
  relabelMarkers();

  if (waypoints.length >= 2) {
    recalculateRoute();
  } else {
    clearCurrentRoute();
  }
}

function relabelMarkers(): void {
  waypoints.forEach((wp, i) => {
    const type = i === 0 ? 'start' : i === waypoints.length - 1 ? 'end' : 'via';
    const label = type === 'via' ? '·' : String.fromCharCode(65 + (type === 'start' ? 0 : waypoints.length - 1));
    const el = createMarkerElement(type, i === 0 ? 'A' : i === waypoints.length - 1 ? 'B' : '·');
    const oldEl = wp.marker.getElement();
    const lngLat = wp.marker.getLngLat();
    wp.marker.remove();
    wp.marker = new maplibregl.Marker({ element: el, draggable: true })
      .setLngLat(lngLat)
      .addTo(map);
    setupMarkerDrag(wp, i);
  });
  updateWaypointsList();
}

function clearAllWaypoints(): void {
  waypoints.forEach(wp => wp.marker.remove());
  waypoints = [];
  clearCurrentRoute();
}

function clearCurrentRoute(): void {
  currentRoute = null;
  clearRoute(map);
  clearElevation('elevation-chart');
  elevationContainer.style.display = 'none';
  statsPanel.style.display = 'none';
  exportPanel.style.display = 'none';
  clearRouteBtn.style.display = 'none';
  updateWaypointsList();
}

function updateWaypointsList(): void {
  waypointsList.innerHTML = '';
  waypoints.forEach((wp, i) => {
    const type = i === 0 ? 'start' : i === waypoints.length - 1 && waypoints.length > 1 ? 'end' : 'via';
    const label = i === 0 ? 'A' : i === waypoints.length - 1 ? 'B' : String(i);
    const item = document.createElement('div');
    item.className = 'waypoint-item';
    item.innerHTML = `
      <span class="waypoint-marker ${type}">${label}</span>
      <span class="waypoint-name">${wp.lngLat[1].toFixed(4)}, ${wp.lngLat[0].toFixed(4)}</span>
      <button class="waypoint-remove" title="Entfernen">&times;</button>
    `;
    item.querySelector('.waypoint-remove')!.addEventListener('click', () => removeWaypoint(i));
    waypointsList.appendChild(item);
  });
  clearRouteBtn.style.display = waypoints.length > 0 ? 'block' : 'none';
}

async function recalculateRoute(): Promise<void> {
  if (isCalculating) return;
  if (waypoints.length < 2) return;

  isCalculating = true;
  document.getElementById('app')!.classList.add('loading');

  try {
    const pts = waypoints.map(wp => wp.lngLat);
    currentRoute = await calculateRoute({ waypoints: pts, profile });
    displayRoute(currentRoute);
    encodeRouteToUrl(pts, profile, mode);
  } catch (err) {
    console.error('Route calculation failed:', err);
    alert(`Routing fehlgeschlagen: ${(err as Error).message}`);
  } finally {
    isCalculating = false;
    document.getElementById('app')!.classList.remove('loading');
  }
}

async function recalculateRoundtrip(): Promise<void> {
  if (isCalculating) return;
  if (waypoints.length < 1) return;

  isCalculating = true;
  document.getElementById('app')!.classList.add('loading');

  const distanceSlider = document.getElementById('rt-distance') as HTMLInputElement;
  const directionSlider = document.getElementById('rt-direction') as HTMLInputElement;
  // roundTripDistance is the radius, not total distance
  // total ≈ radius × π, so radius ≈ total / π
  const totalKm = parseInt(distanceSlider.value);
  const distance = Math.round((totalKm * 1000) / Math.PI);
  const direction = parseInt(directionSlider.value);

  try {
    currentRoute = await calculateRoundtrip({
      start: waypoints[0].lngLat,
      profile,
      distance,
      direction,
    });
    displayRoute(currentRoute);
    document.getElementById('rt-shuffle')!.style.display = 'block';
  } catch (err) {
    console.error('Roundtrip failed:', err);
    alert(`Rundtour fehlgeschlagen: ${(err as Error).message}`);
  } finally {
    isCalculating = false;
    document.getElementById('app')!.classList.remove('loading');
  }
}

function displayRoute(route: RouteResult): void {
  updateRoute(map, route.geojson);
  fitRouteBounds(map, route.coordinates);
  updateStats(route);

  elevationContainer.style.display = 'block';
  renderElevation('elevation-chart', route.coordinates);
  statsPanel.style.display = 'block';
  exportPanel.style.display = 'block';

  setHoverCallback((point) => {
    if (!hoverMarker) return;
    if (point) {
      hoverMarker.setLngLat([point.lng, point.lat]);
      hoverMarker.getElement().style.display = 'block';
    } else {
      hoverMarker.getElement().style.display = 'none';
    }
  });
}

function updateStats(route: RouteResult): void {
  document.getElementById('stat-distance')!.textContent =
    route.distance < 10 ? `${route.distance.toFixed(1)} km` : `${Math.round(route.distance)} km`;
  document.getElementById('stat-ascent')!.textContent = `${Math.round(route.ascent)} m`;
  document.getElementById('stat-descent')!.textContent = `${Math.round(route.descent)} m`;

  const hours = Math.floor(route.time / 3600);
  const minutes = Math.round((route.time % 3600) / 60);
  document.getElementById('stat-time')!.textContent =
    hours > 0 ? `${hours}h ${minutes}min` : `${minutes} min`;
}

function setupControls(): void {
  // Mode toggle
  document.querySelectorAll('.mode-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const newMode = (btn as HTMLElement).dataset.mode as 'route' | 'roundtrip';
      if (newMode === mode) return;
      mode = newMode;
      document.querySelectorAll('.mode-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      waypointsPanel.style.display = mode === 'route' ? 'block' : 'none';
      roundtripPanel.style.display = mode === 'roundtrip' ? 'block' : 'none';

      clearAllWaypoints();
    });
  });

  // Profile select - sync quick buttons and dropdown
  const profileDropdown = document.getElementById('profile-dropdown') as HTMLSelectElement;

  function setProfile(newProfile: string): void {
    profile = newProfile;
    // Sync quick buttons
    document.querySelectorAll('.profile-btn').forEach(b => b.classList.remove('active'));
    const matchBtn = document.querySelector(`.profile-btn[data-profile="${newProfile}"]`);
    if (matchBtn) matchBtn.classList.add('active');
    // Sync dropdown
    if (profileDropdown.value !== newProfile) {
      profileDropdown.value = newProfile;
    }
    // Recalculate if route exists
    if (mode === 'route' && waypoints.length >= 2) {
      recalculateRoute();
    }
  }

  document.querySelectorAll('.profile-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      setProfile((btn as HTMLElement).dataset.profile!);
    });
  });

  profileDropdown.addEventListener('change', () => {
    setProfile(profileDropdown.value);
  });

  // Roundtrip controls
  const distSlider = document.getElementById('rt-distance') as HTMLInputElement;
  const distLabel = document.getElementById('rt-distance-label')!;
  distSlider.addEventListener('input', () => { distLabel.textContent = distSlider.value; });

  const dirSlider = document.getElementById('rt-direction') as HTMLInputElement;
  const dirLabel = document.getElementById('rt-direction-label')!;
  dirSlider.addEventListener('input', () => { dirLabel.textContent = dirSlider.value; });

  document.querySelectorAll('.direction-compass span').forEach(span => {
    span.addEventListener('click', () => {
      const dir = (span as HTMLElement).dataset.dir!;
      dirSlider.value = dir;
      dirLabel.textContent = dir;
    });
  });

  document.getElementById('rt-generate')!.addEventListener('click', recalculateRoundtrip);
  document.getElementById('rt-shuffle')!.addEventListener('click', () => {
    const dirSlider = document.getElementById('rt-direction') as HTMLInputElement;
    const newDir = (parseInt(dirSlider.value) + 60) % 360;
    dirSlider.value = String(newDir);
    document.getElementById('rt-direction-label')!.textContent = String(newDir);
    recalculateRoundtrip();
  });

  // Clear route
  clearRouteBtn.addEventListener('click', () => {
    clearAllWaypoints();
    updateWaypointsList();
  });

  // Elevation close
  document.getElementById('elevation-close')!.addEventListener('click', () => {
    elevationContainer.style.display = 'none';
  });

  // Export
  document.getElementById('export-gpx')!.addEventListener('click', () => {
    if (waypoints.length >= 2) {
      downloadGpx(waypoints.map(wp => wp.lngLat), profile);
    }
  });

  document.getElementById('export-geojson')!.addEventListener('click', () => {
    if (currentRoute) {
      downloadGeojson(currentRoute.geojson);
    }
  });
}

function restoreFromUrl(): void {
  const saved = decodeRouteFromUrl();
  if (!saved || saved.waypoints.length === 0) return;

  // Set profile
  profile = saved.profile;
  document.querySelectorAll('.profile-btn').forEach(b => {
    b.classList.toggle('active', (b as HTMLElement).dataset.profile === profile);
  });
  const dropdown = document.getElementById('profile-dropdown') as HTMLSelectElement;
  dropdown.value = profile;

  // Set mode
  if (saved.mode === 'roundtrip') {
    mode = 'roundtrip';
    document.querySelectorAll('.mode-btn').forEach(b => {
      b.classList.toggle('active', (b as HTMLElement).dataset.mode === 'roundtrip');
    });
    roundtripPanel.style.display = 'block';
    waypointsPanel.style.display = 'none';
  }

  // Add waypoints
  saved.waypoints.forEach(lngLat => addWaypoint(lngLat));
}

function pointToSegmentDist(p: [number, number], a: [number, number], b: [number, number]): number {
  const dx = b[0] - a[0];
  const dy = b[1] - a[1];
  if (dx === 0 && dy === 0) return Math.hypot(p[0] - a[0], p[1] - a[1]);
  let t = ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy);
  t = Math.max(0, Math.min(1, t));
  return Math.hypot(p[0] - (a[0] + t * dx), p[1] - (a[1] + t * dy));
}

// Boot
init();
