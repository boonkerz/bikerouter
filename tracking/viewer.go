package main

import "fmt"

func viewerTemplate(id string) []byte {
	const tpl = `<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Wegwiesel · Live</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
<style>
  html, body { margin:0; padding:0; height:100%%; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif; background:#f5e9d8; color:#2a2014; }
  #map { position:absolute; inset:0; }
  #panel { position:absolute; top:12px; left:12px; right:12px; padding:10px 14px; background:#f5e9d8; border-radius:12px; box-shadow:0 4px 16px rgba(0,0,0,.12); z-index:1000; font-size:13px; }
  #panel b { color:#6a4a28; }
  .pulse { width:14px; height:14px; border-radius:50%%; background:#c62828; box-shadow:0 0 0 0 rgba(198,40,40,.7); animation:pulse 1.5s infinite; display:inline-block; vertical-align:middle; margin-right:6px; }
  @keyframes pulse { 0%%{box-shadow:0 0 0 0 rgba(198,40,40,.7)} 70%%{box-shadow:0 0 0 10px rgba(198,40,40,0)} 100%%{box-shadow:0 0 0 0 rgba(198,40,40,0)} }
  #expired { padding:24px; text-align:center; }
</style>
</head>
<body>
<div id="panel"><span class="pulse"></span><span id="status">Verbinde…</span></div>
<div id="map"></div>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
const id = %q;
const map = L.map('map').setView([52, 9], 6);
L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', { attribution:'© OpenStreetMap', maxZoom:19 }).addTo(map);
let marker, line;
let pointCount = 0;
async function tick() {
  try {
    const r = await fetch('/api/track/' + id, { cache:'no-store' });
    if (r.status === 404 || r.status === 410) {
      document.getElementById('status').textContent = 'Tracking beendet oder abgelaufen';
      document.querySelector('.pulse').style.background = '#888';
      return;
    }
    const d = await r.json();
    const trail = d.trail || [];
    if (trail.length === 0) {
      document.getElementById('status').textContent = 'Warte auf Position…';
      return;
    }
    const pts = trail.map(p => [p.lat, p.lon]);
    const last = pts[pts.length-1];
    if (!marker) {
      marker = L.circleMarker(last, { radius:8, color:'#fff', weight:3, fillColor:'#c62828', fillOpacity:1 }).addTo(map);
      map.setView(last, 16);
    } else {
      marker.setLatLng(last);
    }
    if (!line) {
      line = L.polyline(pts, { color:'#c62828', weight:5 }).addTo(map);
    } else {
      line.setLatLngs(pts);
    }
    if (pts.length !== pointCount) {
      pointCount = pts.length;
      map.panTo(last);
    }
    const lp = d.last || {};
    const ageS = lp.t ? Math.round((Date.now() - lp.t)/1000) : '?';
    document.getElementById('status').innerHTML = '<b>Live</b> · ' + pts.length + ' Punkte · letztes Update vor ' + ageS + ' s';
  } catch (e) {
    document.getElementById('status').textContent = 'Verbindung verloren — versuche neu…';
  }
  setTimeout(tick, 8000);
}
tick();
</script>
</body>
</html>
`
	return []byte(fmt.Sprintf(tpl, id))
}
