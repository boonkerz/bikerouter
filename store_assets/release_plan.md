# Wegwiesel Release-Plan

Living document. Updated wave-by-wave. Use this to pick up where the last session left off.

Hauptdomain: https://wegwiesel.app · Bundle: `com.thomaspeterson.bikerouter` · Display-Name: Wegwiesel

---

## Aktueller Stand

| Bereich | Version | Stand |
|---|---|---|
| Flutter App (iOS + Android) | **1.9.0+55** | Code im Repo, Codemagic gebaut, App-Store-Submission ausstehend |
| Web App (wegwiesel.app) | v1.9 | deployt via `scripts/deploy-web.sh` |
| Garmin Connect IQ App (WegwieselSync) | 1.5.1 | `.iq`-Paket gebaut, Store-Submission **wartet auf Garmin-Review** |
| BRouter Profile | inkl. `wegwiesel-ebike` | im Docker-Container deployt |
| Server-Services | brouter + overpass + share + feedback + **tracking** (v1.9 neu) | live auf 204.168.254.31 |

---

## Was in v1.9 reinkam (für Kontext nach Compaction)

„Onboard Companion" — die App wird zum Begleiter auf der Fahrt:

1. **TTS-Sprachausgabe** (DE/EN) — `flutter_tts`, Phasen 500/200/Jetzt, Mute-Toggle, persistente Pref. → `lib/services/navigation_voice_service.dart`
2. **E-Bike-Profil + Ladestationen-POI** — BRouter-Profil `wegwiesel-ebike.brf` (220 W bikerPower, 110 kg Masse, 27 km/h Cap), `PoiCategory.charging` mit `amenity=charging_station`. → `customprofiles/wegwiesel-ebike.brf`, `lib/models/route_poi.dart`
3. **Komoot/URL-Import** — Tour-URL einfügen, Komoot wird zu `api/v007/tours/{id}.gpx` umgeschrieben, generische .gpx-URLs funktionieren auch. Strava blockt mit explizitem Hint (kein OAuth in v1.9). → `lib/services/route_url_import.dart`
4. **Ride-Recording** — Background-GPS (Android Foreground-Service + iOS UIBackgroundModes=location), Pause/Resume, Live-Stats (Distanz, ⌀/Max-Tempo, Höhenmeter, Kalorien per METS×Gewicht), GPX-Export, lokale Rides-Liste. Body-Weight im Settings. → `lib/services/ride_recorder.dart`, `lib/screens/recording_screen.dart`
5. **Live-Tracking-Link** — Go-Service `tracking/` mit In-Memory TTL-Sessions (12 h), Leaflet-Viewer auf `/track/{id}`, App postet alle 20 s. → `tracking/main.go`, `lib/services/live_tracking_service.dart`

---

## v1.10 „Discover" (✓ in Arbeit / ausgeliefert)

Discover-Welle bringt die App auf das nächste Niveau ohne große Architektur-Eingriffe:

### v1.10 Feature 1 — Public Route Library ✓
- Share-Service erweitert um `published/title/description/profile/center_lat/lon/published_at` + `edit_token`
- Endpoints: `PATCH /api/share/{code}` (publish/edit), `DELETE /api/share/{code}` (mit token), `GET /api/library` (paginated, Filter: profile/distance/bbox/search)
- Published shares überleben die 7-Tage-TTL
- App: GarminShareService liefert jetzt `editToken`, `EditTokenStore` persistiert lokal. Menü „Routen entdecken" → `LibraryScreen` mit Chip-Filtern, „Route veröffentlichen" → Dialog → Upload + PATCH
- Caddyfile: `/api/library*` → share-Container

### v1.10 Feature 2 — Wegwiesel-Heatmap-Overlay
- Tabelle `tile_counters (z, x, y, count)` in share.db
- Aggregator: bei jedem Publish wird die GPX-Geometrie zu Zoom-12-Tiles dedupliziert + Counter inkrementiert
- Renderer: `/api/heatmap/{z}/{x}/{y}.png` rendert 256×256 PNG mit Rot-Alpha = `log2(count+1) × 40`
- App: neuer RouteOverlay-Eintrag „🔥 Wegwiesel-Heatmap", Toggle in der bestehenden Overlay-Liste
- Privacy: nur veröffentlichte Routen tragen bei, keine Personen-Tags, keine Zeit-Stamps in den Counters

## v2.0 „Off the grid" (Nächste Welle — ca. 3–4 Wochen)

**Ziel:** Der größte USP-Block. Komoot Premium kann Offline-Maps, Wegwiesel macht es kostenlos und privacy-freundlich.

### v2.0 Feature 1 — Offline-Karten (Vector Tiles)
- **Tech:** OSM Vector Tiles via `flutter_map_vector_renderer` oder `vector_map_tiles` Package; PMTiles als Tile-Container (eine Datei pro Region)
- **Server:** PMTiles per Caddy-Proxy aus `pbf/` ableiten (Tippecanoe + pmtiles converter), Caddy serviert die `.pmtiles` mit Range-Requests
- **Download-UX:** Region-Picker mit Größenanzeige (Deutschland ~1.2 GB, Bayern ~250 MB), Download mit Resume + Fortschrittsbalken, lokal in App-Documents
- **Implementations-Risiko:** PMTiles-Reader in Dart noch wenig getestet — Fallback auf Mapsforge-Format (offizielle Offline-Karten-Engine, Java port nach Flutter existiert)
- **Aufwand:** 8–10 Tage

### v2.0 Feature 2 — Offline-Routing
- **Tech:** BRouter selbst kann offline (das ist der Originalzweck der Engine). Segment-Files (`*.rd5`) müssen lokal liegen, dann läuft BRouter rein im Speicher
- **Architektur:** BRouter-Lib als Flutter Platform-Channel-Wrapper (iOS+Android nativ), oder geringer-Aufwand: nur Segment-Download und Server-Endpoint wechseln (App spricht trotzdem mit lokalem brouter-jar via REST über localhost) — Android: möglich, iOS: schwierig (JVM)
- **Pragmatischer Pfad:** Pure-Dart-Port der BRouter-Kernroute (von @abrensch existiert ein Java-Code, der portierbar ist) — 2-3 Wochen Arbeit
- **Region-Download:** gleicher Picker wie Offline-Maps, lädt die `.rd5`-Segmente der Region
- **Aufwand:** 12–15 Tage

### v2.0 Feature 3 — Wegwiesel-Heatmap-Overlay
- **Datenquelle:** Anonyme Aggregation aller über `share/`-Service erzeugten Routen-Codes — Caddy-Logs reichen erstmal nicht, Server-seitig in `share/main.go` ein optionales Counter-Update einbauen (kein Logging der Route selbst, nur „diese Tile wurde X mal geplant")
- **Server-Job:** monatlicher Aggregation-Cron, der die Tile-Counter-DB in Heatmap-Tiles (256×256 PNG mit Alpha) rasterisiert und unter `https://wegwiesel.app/heatmap/{z}/{x}/{y}.png` serviert
- **App-UX:** Karten-Style-Picker bekommt einen Heatmap-Schalter (Overlay-Layer); Sichtbarkeit nur ab Zoom 8
- **Privacy:** keine Personen-Korrelation, keine Zeit-Tags. Nur „Tile wurde N-mal von irgendwem in einer Route benutzt"
- **Aufwand:** 4–5 Tage

### v2.0 Feature 4 — Public Route Library
- **Server:** existierender `share/`-Service erweitern um `published: BOOLEAN` Spalte; eigener `GET /api/library`-Endpoint mit Pagination, Suche nach Region/Profil/Distanz
- **Veröffentlichen-Flow in der App:** Routen-Detail-Sheet bekommt „Öffentlich teilen"-Schalter mit Titel/Foto/Beschreibung-Felder; ohne Account, lokal generierter Edit-Token im `SharedPreferences` (User kann eigene Routen löschen/bearbeiten)
- **Browse-UX in der App:** neuer Bildschirm „Routen entdecken" mit Filter-Chips + Karten-Vorschau pro Hit
- **Moderation:** Server-seitig manueller Review-Queue, Toggle `approved` in der DB; Spam-Schutz via Codemagic-Verifizierungs-Token oder Rate-Limit
- **SEO-Bonus:** Server gibt eine Sitemap mit allen public Routen aus → Google indexiert → organischer Traffic auf wegwiesel.app
- **Aufwand:** 8 Tage

### v2.0 Versions-Plan
- v1.10.0 könnte Heatmap solo bringen (kleinster Wurf), aber besser im 2.0-Block bündeln
- v2.0.0 = Offline-Maps + Offline-Routing + Heatmap + Library zusammen
- Pre-Release: Beta-Cohort über TestFlight 2 Wochen vor Submission, damit Offline-Funktion in der Praxis getestet wird

---

## v2.1 „Wider reach" (Welle 3 — ca. 2 Wochen)

**Ziel:** Hardware + Zielgruppen-Diversifikation.

### v2.1 Feature 1 — Wahoo-Sync analog zum Garmin-Flow
- **Hintergrund:** Wahoo Bolt/Roam/Ace sind die zweite große Gerätegruppe nach Garmin Edge
- **Wahoo App-API:** Wahoo X / Wahoo Companion App akzeptiert GPX-Routen via Deep-Link `wahoofitness://route?url=...` — die Wahoo-App lädt dann von einer URL
- **Implementierung:** ähnlich Garmin-Share-Flow, aber statt Code-an-Edge-übergeben → Deep-Link mit Share-URL öffnen, Wahoo-App holt GPX vom Share-Service
- **Fallback:** GPX-Datei mit Wahoo-konformen Tags (Wahoo will spezielle XML-Extensions für Turn-Hints) — schon weitgehend kompatibel
- **Aufwand:** 5 Tage (inkl. Test auf realer Wahoo-Hardware → vom User selbst, kein Edge im Schrank)
- **Erweiterung:** Hammerhead Karoo läuft Android → könnte direkt eine Wegwiesel-Android-Variante laden, aber das ist v2.2-Material

### v2.1 Feature 2 — Bikepacking-Modus
- **Multi-Day-Tour-Planung:** Etappen-Planer mit gezielten Camping-/Wasser-/Resupply-Suchen pro Tag
- **Sunrise/Sunset pro Etappe:** Algorithm aus `dart:math`, basierend auf End-Coord der Etappe + Datum — zeigt wieviel Restzeit für Camp-Aufbau
- **Wildcamping-Hinweise:** Deutschland-spezifisch — OSM-Tags `tourism=camp_pitch` (offiziell) vs. „wo wäre es theoretisch erlaubt" (Forst-Regelung, BY/NRW/SH zeigen). Heikel rechtlich, mit Disclaimer
- **Verlängerter Wetter-Forecast:** statt 24h-Vorhersage → 5-Tage-Outlook entlang der Route
- **POI-Kategorien bevorzugen:** „Bikepacking-Mode" Toggle priorisiert Wasserstellen, Schutzhütten, Bahnhöfe in der POI-Suche
- **Aufwand:** 6 Tage

### v2.1 Versions-Plan
- v2.1.0 = beide Features zusammen
- Marketing-Story: „Vom Tagesausflug bis zur 3-Wochen-Bikepacking-Tour"

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

*Letzte Aktualisierung: 2026-05-12 (v1.9.0+55)*
