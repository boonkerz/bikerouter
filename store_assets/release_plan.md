# Wegwiesel Release-Plan

Living document. Updated wave-by-wave. Use this to pick up where the last session left off.

Hauptdomain: https://wegwiesel.app · Bundle: `com.thomaspeterson.bikerouter` · Display-Name: Wegwiesel

---

## Aktueller Stand

| Bereich | Version | Stand |
|---|---|---|
| Flutter App (iOS + Android) | **2.1.0+61** | Code auf `main`, Codemagic-Push für v2.1.0-Release ausgelöst |
| Web App (wegwiesel.app) | v2.1 (Hiking-Pack + Bikepacking live) | deployt via `scripts/deploy-web.sh` |
| Garmin Connect IQ App (WegwieselSync) | 1.5.1 | `.iq`-Paket gebaut, Store-Submission **wartet auf Garmin-Review** |
| BRouter Profile | inkl. `wegwiesel-ebike`, `wegwiesel-running`, `hiking-beta` mit per-Request-Knobs (SAC_scale_limit, prefer_hiking_routes) | im Docker-Container deployt |
| Server-Services | brouter + overpass + share + feedback + tracking + `/segments/*.rd5` | live auf 204.168.254.31 |

---

## Was in v1.9 reinkam (für Kontext nach Compaction)

„Onboard Companion" — die App wird zum Begleiter auf der Fahrt:

1. **TTS-Sprachausgabe** (DE/EN) — `flutter_tts`, Phasen 500/200/Jetzt, Mute-Toggle, persistente Pref. → `lib/services/navigation_voice_service.dart`
2. **E-Bike-Profil + Ladestationen-POI** — BRouter-Profil `wegwiesel-ebike.brf` (220 W bikerPower, 110 kg Masse, 27 km/h Cap), `PoiCategory.charging` mit `amenity=charging_station`. → `customprofiles/wegwiesel-ebike.brf`, `lib/models/route_poi.dart`
3. **Komoot/URL-Import** — Tour-URL einfügen, Komoot wird zu `api/v007/tours/{id}.gpx` umgeschrieben, generische .gpx-URLs funktionieren auch. Strava blockt mit explizitem Hint (kein OAuth in v1.9). → `lib/services/route_url_import.dart`
4. **Ride-Recording** — Background-GPS (Android Foreground-Service + iOS UIBackgroundModes=location), Pause/Resume, Live-Stats (Distanz, ⌀/Max-Tempo, Höhenmeter, Kalorien per METS×Gewicht), GPX-Export, lokale Rides-Liste. Body-Weight im Settings. → `lib/services/ride_recorder.dart`, `lib/screens/recording_screen.dart`
5. **Live-Tracking-Link** — Go-Service `tracking/` mit In-Memory TTL-Sessions (12 h), Leaflet-Viewer auf `/track/{id}`, App postet alle 20 s. → `tracking/main.go`, `lib/services/live_tracking_service.dart`

---

## v1.10 „Discover" (✓ ausgeliefert)

Discover-Welle bringt die App auf das nächste Niveau ohne große Architektur-Eingriffe:

### v1.10 Feature 1 — Public Route Library ✓
- Share-Service erweitert um `published/title/description/profile/center_lat/lon/published_at` + `edit_token`
- Endpoints: `PATCH /api/share/{code}` (publish/edit), `DELETE /api/share/{code}` (mit token), `GET /api/library` (paginated, Filter: profile/distance/bbox/search)
- Published shares überleben die 7-Tage-TTL
- App: GarminShareService liefert jetzt `editToken`, `EditTokenStore` persistiert lokal. Menü „Routen entdecken" → `LibraryScreen` mit Chip-Filtern, „Route veröffentlichen" → Dialog → Upload + PATCH
- Caddyfile: `/api/library*` → share-Container

### v1.10 Feature 2 — Wegwiesel-Heatmap-Overlay ✓
- Tabelle `tile_counters (z, x, y, count)` in share.db
- Aggregator: bei jedem Publish wird die GPX-Geometrie zu Zoom-12-Tiles dedupliziert + Counter inkrementiert
- Renderer: `/api/heatmap/{z}/{x}/{y}.png` rendert 256×256 PNG mit Rot-Alpha = `log2(count+1) × 40`
- App: neuer RouteOverlay-Eintrag „🔥 Wegwiesel-Heatmap", Toggle in der bestehenden Overlay-Liste
- Privacy: nur veröffentlichte Routen tragen bei, keine Personen-Tags, keine Zeit-Stamps in den Counters

## v1.11 „Offline-Karten" (✓ ausgeliefert)

Zweistufiger Pfad statt Big-Bang-v2.0:
- **v1.11** — Offline-Karten (Tile-Cache + Region-Download) + Saved-Routes offline-fähig
- **v2.0** — echtes Offline-Routing (neue Strecken berechnen ohne Netz)

### v1.11 Feature 1 — Offline-Karten ✓
- `WegwieselTileCacheProvider` als `MapCachingProvider` für flutter_map. URL-Hash-Layout, mtime-LRU-Eviction bei Überschreiten des Limits (Default 500 MB)
- Automatischer Cache jedes betrachteten Tiles via NetworkTileProvider-Caching
- `RegionDownloader` lädt Bbox + Zoom 8–15 parallel vorab in den Cache
- `OfflineMapsScreen` (Menü → „Offline-Karten") mit Cache-Anzeige, Limit-Editor, „Aktuellen Ausschnitt herunterladen"

### v1.11 Feature 2 — Saved Routes offline ✓
- `SavedRoute.cached: CachedRoute?` mit flacher `[lon, lat, ele, …]`-Coords-Liste + Turn-Hints
- Beim Speichern wird die komplette Geometrie + alle Turn-Hints snapshotetet
- Beim Laden wird der Cache direkt in `_displayRoute()` gepumpt, kein BRouter-Roundtrip nötig

## v2.0 „Off the grid" (✓ ausgeliefert als MVP — Qualitätsausbau offen)

**Status:** Pure-Dart-Port als MVP **in v2.0.0+59 released**. Routing-Kern, hart codiertes `trekking`-Profil, RD5-Segment-Download, Server-Auslieferung, RD5-MicroCache-Decoder, Graph-Loader und App-Initialisierung sind live. Für v2.0.x bleibt die semantische Tag-Auflösung/Profile-Sprache als Qualitätsausbau (siehe v2.1.x Roadmap unten).

**Ziel:** Der größte USP-Block. Komoot Premium kann Offline-Maps, Wegwiesel macht es kostenlos und privacy-freundlich.

### v2.0 Feature 1 — Offline-Karten (Vector Tiles, optional / nach Routing)
- **Tech:** OSM Vector Tiles via `flutter_map_vector_renderer` oder `vector_map_tiles` Package; PMTiles als Tile-Container (eine Datei pro Region)
- **Server:** PMTiles per Caddy-Proxy aus `pbf/` ableiten (Tippecanoe + pmtiles converter), Caddy serviert die `.pmtiles` mit Range-Requests
- **Download-UX:** Region-Picker mit Größenanzeige (Deutschland ~1.2 GB, Bayern ~250 MB), Download mit Resume + Fortschrittsbalken, lokal in App-Documents
- **Implementations-Risiko:** PMTiles-Reader in Dart noch wenig getestet — Fallback auf Mapsforge-Format (offizielle Offline-Karten-Engine, Java port nach Flutter existiert)
- **Aktueller Code-Stand:** Raster-Offline-Karten sind seit v1.11 vorhanden (`WegwieselTileCacheProvider`, `RegionDownloader`, `OfflineMapsScreen`). Vector-Tiles sind noch nicht implementiert und für den Offline-Routing-MVP nicht blockierend.
- **Aufwand:** 8–10 Tage

### v2.0 Feature 2 — Offline-Routing
- **Erledigt:** `OfflineRouter`-Interface, `Lookups` Parser, `Rd5Reader` Header/Subtile-Index, `BitStreamReader`
- **Erledigt:** Pure-Dart-Graph-Modell + `GraphOfflineRouter` mit vorwärts gerichteter A*-Suche und `RouteResult`/GeoJSON-Ausgabe
- **Erledigt:** hart codiertes `trekking`-Kostenmodell als erstes Profil
- **Erledigt:** `BRouterService.offlineRouter` als Fallback-fähiger Hook: lokal versuchen, bei unvollständigen Daten Server nutzen
- **Erledigt:** `Rd5SegmentDownloader` berechnet BRouter-5°-Segmentnamen, lädt `.rd5` von `https://wegwiesel.app/segments`, speichert lokal und liefert Fortschritt
- **Erledigt:** Caddy/Compose servieren `/segments/*.rd5` aus `/opt/wegwiesel/segments4`
- **Erledigt:** RD5-MicroCache-Decoder (`MicroCache2` → Dart): NodeData, WayLink, externe Link-Koordinaten, Geometrie-Skip
- **Erledigt:** Graph-Loader decodiert lokale `.rd5`-Segmente für die angefragte Route on-demand in `OfflineRoutingGraph`
- **Erledigt:** App-UI: „Routing-Region herunterladen" in `OfflineMapsScreen`, Segment-Speicher anzeigen/löschen
- **Erledigt:** Offline-Router wird beim App-Start initialisiert, wenn lokale Segmente vorhanden sind
- **Offen nach v2.0-MVP:** semantische Tag-Auflösung aus `lookups.dat` (`highway/surface/access`) statt generischer Fahrrad-Kanten
- **Offen nach v2.0-MVP:** LRU-Knoten/Subtile-Cache und bidirektionale Suche für große Regionen
- **Aufwand verbleibend für Qualitätsausbau:** ca. 4–6 Tage

### v2.0 Versions-Plan
- v1.10.0 = Public Route Library + Heatmap ✓
- v1.11.0 = Raster-Offline-Karten + Saved Routes offline ✓
- v2.0.0 = Offline-Routing-MVP mit lokalem RD5-Segmentdownload und Pure-Dart-Routingkern ✓
- Offen: Beta-Cohort über TestFlight (zurückgestellt, weil v2.1.0 zuerst rauskommen sollte)

---

## v2.0.x Hiking-Pack (✓ ausgeliefert als Teil von v2.1.0)

Eingeschoben zwischen v2.0 und v2.1, weil das Bikepacking-Feature konzeptionell darauf aufbaut. Alle Hiking-Features wurden mit v2.1.0 gemeinsam released.

- **Wandern de-beta + neues Lauf-Profil** — `wegwiesel-running.brf` (SAC T1, keine Treppen, prefer_hiking_routes=0)
- **POI-Kategorien Schutzhütte + Picknickplatz** — alpine_hut/wilderness_hut wandern aus Unterkunft raus
- **Höhenmeter prominent + Default-Distanz 8 km bei Wandern** — StatsBar mit `highlightAscent` + Profil-Wechsel-Clamp
- **SAC-Skala-Anzeige T1–T6** — parst sac_scale aus BRouter-Messages, Badge unter Stats
- **„Wanderwege bevorzugen"-Toggle + Schwierigkeitsstufen-Presets** (Gemütlich/Sportlich/Bergtour) — `HikingPrefs`, durchgereicht an BRouter via `&profile:SAC_scale_limit=N&profile:prefer_hiking_routes=N`
- **Pausen-Empfehlungen** auf Fuß-Profilen — Stats-Action pickt ein Picknickplatz/Schutzhütte pro 1.5 h Gehzeit

Außerdem in derselben Welle gefixt:
- **Roundtrip-Iteration** — BRouter `roundTripDistance` ist Suchradius, nicht Ziel-Distanz; Iteration neu mit `radius = target/5`, sqrt-gedämpfter Korrektur, 5 Iter, Best-of, harter Fail bei >50 % Abweichung
- **Anker-Marker-Bug** — `_displayRoute` regeneriert A/B/C/D bei jeder Roundtrip-Anzeige (vorher nur beim allerersten Run)
- **Slider-Granularität** — Wandern/Laufen 1-km-Schritte (2–50 km), Auto 10-km-Schritte (10–500 km), Rad unverändert

---

## v2.1 „Hiking & Bikepacking" (✓ ausgeliefert als v2.1.0+61)

**Ziel:** Wandern und Mehrtagestouren-Planung. Wahoo-Sync wurde aus dem Scope herausgenommen und auf v2.1.1 verschoben.

### v2.1 Feature 1 — Hiking-Pack ✓
Siehe `v2.0.x Hiking-Pack` oben — bewusst getrennter Abschnitt, weil die Features eine eigene Kategorie sind, aber in derselben Release-Welle gingen.

### v2.1 Feature 2 — Bikepacking-Modus ✓
- **Global Toggle in Settings** → `BikepackingPrefs`, persistiert per SharedPreferences
- **Neue POI-Kategorie 🚂 Bahnhof** — `railway=station|halt` + `public_transport=station`
- **POI-Sheet öffnet voreingestellt** mit camping/water/shelter/picnic/station, wenn Modus aktiv ist
- **Etappen-Planer-Aufrüstung:**
  - **Starttag-Picker** (default heute, bis +365 Tage)
  - **Sonnenaufgang/-untergang pro Etappe** via Pure-Dart NOAA-Algorithmus (`solar_calc.dart`, ±1 min, kein Netz)
  - **Wetter pro Etappe** — Open-Meteo bei Mittag des Etappentags, gecappt auf 16-Tage-Fenster
  - **Übernachtungs-Anchor pro Etappe** — Overpass-Query im 5-km-Radius, Ranking camp_site/alpine_hut/wilderness_hut > hostel > hotel

### v2.1 Versions-Plan
- v2.1.0 = Hiking-Pack + Bikepacking-Modus ✓ (released 2026-05-17)
- v2.1.x-Pipeline (in der Reihenfolge der Priorität):
  - Wahoo-Sync (Deep-Link `wahoofitness://route?url=...` mit Share-URL) — 5 Tage
  - Wildcamping-Hinweise (Tag `tourism=camp_pitch` + DE-Rechtshinweis) — 1 Tag
  - Crash-Persistierung beim Recording (Disk-Flush alle N Punkte) — 1 Tag
  - v2.0 Polish: lookups.dat-Tag-Auflösung statt generischer Fahrrad-Kanten, LRU-Subtile-Cache, bidirektionale A* — 4–6 Tage

---

## v2.2 „On your wrist" (Welle 4 — ca. 3 Wochen, aufwendigste Investition)

**Ziel:** Telefon in der Tasche, Navigation am Handgelenk.

### v2.2 Feature 1 — Apple Watch Companion
- **Plattform:** WatchOS App (Swift + WatchKit), separates Xcode-Target im `ios/`-Ordner
- **Datenaustausch Phone↔Watch:** WatchConnectivity-Framework, sendet Turn-by-Turn-Updates ähnlich wie der Voice-Service nur dass die Watch die Anzeige übernimmt
- **UI:** großer Richtungspfeil, Distanz zur nächsten Abbiegung, Restzeit (ETA). Mehr passt eh nicht auf 41 mm
- **Komplikationen:** Watchface-Comp mit „nächste Abbiegung in X m" — Optional
- **Aufwand:** 8 Tage

### v2.2 Feature 2 — Wear OS Companion
- **Plattform:** Wear OS App in Kotlin, eigenes Android-Modul (`android/wear/`)
- **Datenaustausch:** Wear Data Layer API; Phone-Side schickt Turn-Hints als Data-Items
- **UI:** Compose-for-Wear, gleicher Inhalt wie Apple Watch
- **Aufwand:** 8 Tage

### v2.2 Versions-Plan
- v2.2.0 = beide Watch-Companions
- App-Store-Submission: jede Watch-App braucht eigene Screenshots + Beschreibungen

---

## v2.3+ — Backlog (nicht durchgeplant)

Ideen für später, wenn die Hauptwellen ausgerollt sind:

- **OAuth-Komoot/Strava-Integration** — echte Sync-Verbindung statt URL-Paste (braucht App-Registrierung bei beiden Diensten, Datenschutz-Review)
- **Crowdsourced Surface Confirmations** — User-Hint „ist hier wirklich Asphalt?" mit OAuth-OSM-Upload-Button
- **Komplexe Heatmap** mit Wochentag/Stunde-Filtern + Heatmap-Diff zwischen Profilen
- **OSM-Editing-Anbindung** — direkt aus der App falsche Surface-Tags melden
- **Web-App-Vollausbau** mit allen Features die jetzt nur in der Mobile-App sind (Recording, TTS-Demo, etc.)
- **Garmin-Connect-IQ Auto-Sync** ohne Code-Eingabe — App pusht direkt zu gepairter Edge, sobald Route fertig ist (Komoot-Style)
- **POI „Aussicht"-Foto-Vorschauen** aus OSM-Mapillary
- **Tour-Statistik-Aggregat** über mehrere Recordings („Jahresübersicht: X km, Y Höhenmeter")

---

## Operative Notizen

### Deploy-Flow
- **Web + Server:** `scripts/deploy-web.sh` — synced web build + alle docker-compose Services, rebuildet feedback/share/tracking und brouter (für `customprofiles/`)
- **Mobile-App:** Codemagic baut auf Push nach `main`; manuelles Build-Nummern-Bump nicht nötig (pubspec.yaml ist Quelle der Wahrheit)
- **Garmin CIQ App:** `cd garmin && ./build.sh store` für Submission-`.iq`, `./build.sh sideload` für Edge-Testing per USB

### Versions-Hygiene
- pubspec.yaml ist die Quelle für Version-Code/Name
- Pro Welle EIN Major/Minor-Bump
- whats_new.md sollte vor Codemagic-Build aktualisiert sein
- Git-Tags rückwirkend nicht gesetzt — irrelevant solange pubspec.yaml + Codemagic-Build-IDs die Releases identifizieren

### Was nicht in v1.9 reingekommen ist
- Strava-Tour-Import (OAuth braucht App-Registrierung + Datenschutz-Review)
- Komoot-Tour-Import wurde getestet auf 404-Tour-ID, echte Tours stehen aus
- Crash-Persistierung bei Recording: aktuell läuft alles in-memory. Wenn App abstürzt während Recording = Track verloren. Sollte mit Disk-Flush jeder N Punkte gefixt werden — kleines v1.9.1-Polish

---

*Letzte Aktualisierung: 2026-05-18 (v2.1.0+61, Hiking-Pack + Bikepacking-Modus released, Wahoo nach v2.1.1 verschoben)*
