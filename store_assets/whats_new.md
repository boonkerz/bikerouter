# Versions-Highlights (What's New, 4000 Zeichen max)

> Für ein neues Store-Release nur den jeweiligen Versions-Block kopieren.
> DE → App Store (DE) + Play Store (DE).  EN → App Store (EN) + Play Store (EN).

---

## v2.1.3 (DE) — „Echte Offline-Routenqualität"
**Der Offline-Router kennt jetzt jedes OSM-Tag.**

• lookups.dat wird als App-Asset gebündelt und beim Start eingelesen
• Der RD5-Microcache-Decoder löst die binär kodierten Tag-Indizes über lookups.dat in echte highway/surface/access/cycleway-Werte auf
• Folge: das Trekking-Profil im Offline-Router gewichtet Asphalt vs. Pfad korrekt, vermeidet motorway+steps, bevorzugt cycleways — wie online

## v2.1.3 (EN) — "Real offline routing quality"
**The offline router now sees every OSM tag.**

• lookups.dat is bundled as an app asset and parsed at startup
• The RD5 microcache decoder resolves the binary-encoded tag indices via lookups.dat into real highway/surface/access/cycleway values
• Result: the offline router's trekking profile now weighs asphalt vs path correctly, avoids motorway+steps, prefers cycleways — same behaviour as online

---

## v2.1.2 (DE) — „POI-Fotos & schnellere Offline-Routen"
**Mehr Kontext zu POIs und Offline-Routing wird spürbar flotter.**

• POI-Fotos: Wenn eine OSM-Sehenswürdigkeit ein image= oder wikimedia_commons=-Tag hat, zeigt Wegwiesel das Bild als Vorschau im POI-Sheet und großflächig im Tap-Dialog (Pinch-Zoom in der Vollbildansicht)
• Bidirektionale A* im Offline-Router: lange Routen werden parallel von Start und Ziel berechnet und treffen sich in der Mitte — auf typischen Tagestouren etwa doppelt so schnell wie die alte Vorwärtssuche
• Fix: rd5-Graph-Cache zählt jetzt für beide Suchrichtungen (incoming-Adjazenz)

## v2.1.2 (EN) — "POI photos & faster offline routes"
**More POI context and offline routing gets noticeably snappier.**

• POI photos: OSM features with image= or wikimedia_commons= tags now show a thumbnail in the POI sheet and full-width in the tap dialog (pinch-zoom in the fullscreen view)
• Bidirectional A* in the offline router: long routes are computed from both ends in parallel and meet in the middle — roughly 2× faster than the previous forward-only search on day-trip distances
• Fix: rd5 graph cache now works for both search directions (incoming adjacency)

---

## v2.1.1 (DE) — „Hardware & Schutzanker"
**Drei Punkte, die im Alltag den Unterschied machen.**

• An Wahoo senden: Route mit einem Tipp an die Wahoo Companion App übergeben (Wahoo Bolt/Roam/Ace)
• Aufzeichnung crash-sicher: Tracks werden während der Fahrt alle 10 Punkte auf die Festplatte geschrieben — stürzt die App ab, ist die Fahrt beim nächsten Start wiederhergestellt
• Wildcampen-Hinweis: Bikepacking-Modus zeigt auch informelle Zeltplätze (camp_pitch), mit klarem Rechtshinweis beim ersten Aktivieren
• Offline-Routing schneller: LRU-Cache hält bis zu 200 zuletzt benutzte Microcaches im Speicher, Wiederholungs-Routing in derselben Region ist deutlich schneller

## v2.1.1 (EN) — "Hardware & safety net"
**Three quality-of-life upgrades that pay off on every ride.**

• Send to Wahoo: hand off a route to the Wahoo Companion app with one tap (Wahoo Bolt/Roam/Ace)
• Crash-safe recording: tracks are flushed to disk every 10 points — if the app crashes mid-ride, your track is restored on the next launch
• Wild-camping note: bikepacking mode now includes informal tent pitches (camp_pitch), with a clear legal disclaimer on first activation
• Offline routing speedup: LRU cache keeps up to 200 recently used microcaches in memory, re-planning in the same area is much faster

---

## v2.1.0 (DE) — „Wandern & Bikepacking"
**Zwei neue Welten in Wegwiesel: Wandern wird vollwertig, Mehrtagestouren werden planbar.**

• Neues Lauf-Profil 🏃 und Wandern endlich ohne (beta)
• Wander-Schwierigkeitsstufen Gemütlich/Sportlich/Bergtour, SAC-Skala T1–T6 prominent in der Routenanzeige, Wanderwege-Bevorzugen-Schalter
• Neue POI-Kategorien für Wandern: Schutzhütte, Picknickplatz — und für Bikepacker Bahnhof als Notausstieg
• Bikepacking-Modus im Menü: priorisiert Camping, Wasser, Schutzhütten und Bahnhöfe in der POI-Suche
• Etappen-Planer mit Mehrwert: Starttag-Picker, Sonnenaufgang/-untergang pro Etappe, Wetter-Vorhersage am Etappentag, automatische Übernachtungs-Vorschläge (Camping/Hütte/Hostel)
• Pausen-Empfehlung beim Wandern: ein Picknickplatz oder eine Schutzhütte pro 1,5 h Gehzeit auf der Strecke
• Höhenmeter werden bei Wander-/Lauf-Profilen größer angezeigt
• Rundtour-Fix: BRouter-Iteration kollabiert nicht mehr bei knappen Distanzen, Anker-Marker folgen jetzt der neuen Route bei „Andere Variante"
• Feinere Distanz-Slider bei Wandern (1-km-Schritte 2–50 km) und Auto (10-km-Schritte 10–500 km)

## v2.1.0 (EN) — "Hiking & Bikepacking"
**Two new worlds in Wegwiesel: hiking goes mainstream, multi-day tours get planned properly.**

• New running profile 🏃 and hiking finally drops the (beta)
• Hiking difficulty presets Easy/Sporty/Mountain, prominent SAC T1–T6 grading on each route, prefer-waymarked-trails toggle
• New POI categories for hikers: shelter and picnic — and for bikepackers a train station emergency-exit
• Bikepacking mode in settings: prioritizes camping, water, shelters and train stations in POI search
• Stages planner upgrade: start-date picker, sunrise/sunset per stage, weather forecast on the stage day, automatic overnight suggestions (campsite/hut/hostel)
• Pause recommendations on hiking routes: one picnic spot or shelter every 1.5 h of walking
• Hiking/running profiles highlight ascent prominently in the route header
• Round trip fix: BRouter iteration no longer collapses for short distances, anchor markers now follow the new route after "Another variant"
• Finer distance sliders for hiking (1-km steps, 2–50 km) and car (10-km steps, 10–500 km)

---

## v2.0.0 (DE) — "Off the grid"
**Vorarbeit für echtes Offline-Routing.**

• Pure-Dart-Routingkern mit Trekking-MVP, lokalem Graph-Modell und A*-Suche
• Die App kann einen lokalen Offline-Router nutzen und fällt bei unvollständigen lokalen Daten sauber auf den BRouter-Server zurück

## v2.0.0 (EN) — "Off the grid"
**Groundwork for real offline routing.**

• Pure-Dart routing core with a trekking MVP, local graph model and A* search
• The app can use a local offline router and still falls back cleanly to the BRouter server when local data is incomplete

---

## v1.11.0 (DE) — „Offline-Karten"
**Wegwiesel funktioniert jetzt auch im Funkloch.**

• Karten-Kacheln werden automatisch im Hintergrund gecacht — was du einmal angeschaut hast, ist offline verfügbar
• Neue „Offline-Karten" im Menü: aktuellen Kartenausschnitt vorab herunterladen (Zoom 8–15), Speicher-Limit einstellen (Default 500 MB), Cache komplett leeren
• Gespeicherte Routen funktionieren ohne Netzwerk: beim Speichern wird die komplette Strecke inkl. Turn-Hints lokal mit abgelegt — beim Laden ist sie sofort wieder da, auch offline

## v1.11.0 (EN) — "Offline maps"
**Wegwiesel now works in low-signal areas.**

• Map tiles are automatically cached in the background — anything you've looked at is available offline
• New "Offline maps" menu: pre-download the current viewport (zoom 8–15), configure storage limit (default 500 MB), clear the whole cache
• Saved routes work without a network: the full geometry including turn hints is stored alongside the metadata, so loading a saved route is instant and offline-capable

---

## v1.10.0 (DE) — „Discover"
**Routen entdecken und teilen — mit Heatmap, wo die Community fährt.**

• Öffentliche Routen-Bibliothek: Eigene Touren mit einem Tipp veröffentlichen (Titel + Beschreibung, kein Account)
• „Routen entdecken"-Bildschirm: filter nach Distanz, in deiner Nähe, Titel-Suche, ein Tipp lädt die Strecke
• Wegwiesel-Heatmap: roter Overlay-Layer zeigt, wo Wegwiesel-User Routen geplant haben — schaltbar im Karten-Stil-Picker
• Privacy bleibt Privacy: keine Personen-Tags, kein User-Tracking, nur dein Gerät kann eigene Veröffentlichungen wieder zurückziehen

## v1.10.0 (EN) — "Discover"
**Discover and share routes — with a heatmap of where the community rides.**

• Public route library: publish your tours with one tap (title + description, no account)
• "Discover routes" screen: filter by distance, near me, title search, tap to load
• Wegwiesel heatmap: red overlay shows where Wegwiesel users have planned routes — toggle in the map style picker
• Privacy stays privacy: no user tags, no tracking, only your device can take down your own publications

---

## v1.9.0 (DE) — „Onboard Companion"
**Die App wird zum Begleiter auf der Fahrt.**

• Sprach-Navigation: Turn-by-Turn wird laut angesagt (deutsch + englisch), in 500 m / 200 m / Jetzt-Phasen
• Fahrt aufzeichnen: GPS-Tracking im Hintergrund mit Live-Stats (Distanz, Tempo, Höhenmeter, Kalorien), Pause/Resume, GPX-Export am Ende
• Live-Position teilen: 12 h gültiger Link, Empfänger sieht deine aktuelle Position auf einer Karte — ohne Account, ohne Tracking-Cookies
• E-Bike-Profil mit pedelec-getuneten Reise-Zeiten + neue POI-Kategorie „Ladestation"
• Tour-URL importieren: Komoot-Tour-Link einfügen, GPX wird direkt geladen — oder beliebige andere öffentliche .gpx-URL

## v1.9.0 (EN) — "Onboard Companion"
**The app becomes your ride companion.**

• Voice navigation: spoken turn-by-turn (German + English) at 500 m / 200 m / now phases
• Record your ride: background GPS with live stats (distance, speed, ascent, calories), pause/resume, GPX export when done
• Share your live position: 12-hour link, recipients see your current location on a map — no account, no tracking cookies
• E-bike profile with pedelec-tuned travel times and a new "Charging station" POI category
• Import tour from URL: paste a Komoot tour link to load the GPX directly — or any other public .gpx URL

---

## v1.8.0 KUMULATIV seit v1.4 (DE) — für App Store Release-Notes
**Großes Update mit neuem Design und vielen neuen Funktionen!**

NEUES DESIGN
• Aquarell-Wegweiser-Icon (Wegwiesel = Wegweiser) — passt zu Bike, Wandern und Auto
• Helles Cream-Theme statt Dark Mode, im Tageslicht besser ablesbar

GARMIN EDGE: DIREKT SENDEN
• Routen werden per Bluetooth direkt an die Edge geschickt — wie bei Komoot
• Eigene Connect-IQ-App „WegwieselSync" auf der Edge nimmt die Strecke an
• Funktioniert auf iPhone und Android

NAVIGATION AUF DEM TELEFON
• Turn-by-Turn direkt auf dem Handy, mit Norden- oder Fahrtrichtung-Ansicht
• Auto-Reroute bei mehr als 50 m Abweichung
• Voraussichtliche Ankunftszeit (ETA) als Uhrzeit
• Geglättetes Heading — kein Karten-Zappeln mehr

NEUE PROFILE FÜR AUTO
• „Auto" (max 130 km/h) und „Auto mit Anhänger" (max 80 km/h)
• Bevorzugt Autobahn und Schnellstraße statt Schleichweg

SMARTERES ROUTING
• Zwei Alternativrouten zur Hauptroute (wie Google Maps), per Chip umschaltbar
• Auto-Wegpunkte werden automatisch auf die nächste befahrbare Straße gezogen — keine „target island failed"-Fehler mehr bei Pins hinter Schranken

SUCHE ENTLANG DER ROUTE
• Tankstellen, Einkaufsmöglichkeiten und Sehenswürdigkeiten finden — sortiert nach Routenkilometer, mit Abstand zur Strecke
• Mit einem Tippen als POI zur Route hinzufügen
• POIs reisen mit der Route in Share-Code und GPX-Export

PLUS
• Diverse Stabilitäts-, Kontrast- und Lesbarkeits-Verbesserungen

## v1.8.0 CUMULATIVE since v1.4 (EN) — for App Store release notes
**Major update with a fresh design and a lot of new features!**

NEW DESIGN
• Watercolor signpost icon (Wegwiesel means signpost) — fits bike, hiking and driving alike
• Light cream theme replacing dark mode, more legible in daylight

SEND TO GARMIN EDGE
• Routes are pushed via Bluetooth straight to the Edge — just like Komoot
• Custom Connect IQ companion app "WegwieselSync" on the Edge consumes the share code
• Works on iPhone and Android

PHONE NAVIGATION
• Turn-by-turn directly on the phone, with north-up or heading-up map orientation
• Automatic re-routing if you drift more than 50 m off course
• Estimated time of arrival (ETA) as clock time
• Smoothed GPS heading — no more twitching map

NEW CAR PROFILES
• "Car" (max 130 km/h) and "Car with trailer" (max 80 km/h)
• Prefers motorways and major roads over slow eco shortcuts

SMARTER ROUTING
• Two alternative routes alongside the main route (Google Maps style), switchable with chips
• Car waypoints are automatically snapped to the nearest drivable road — no more "target island failed" errors when the pin sits behind a barrier

ON-ROUTE POI SEARCH
• Find fuel stations, shops and sights along your track — sorted by route kilometer with side distance
• Add to the route with a single tap
• POIs travel with the route in the share code and GPX export

PLUS
• Various stability, contrast and readability improvements

## v1.8.0 KURZ (DE) — für Play Store (500 Zeichen)
Großes Update seit 1.4!
• Neues Wegweiser-Icon im Aquarell-Stil + helles Cream-Theme
• Routen per Bluetooth direkt an die Garmin Edge senden (wie Komoot)
• Turn-by-Turn Navigation auf dem Telefon mit Ankunftszeit
• Auto-Profile (max 130 km/h, mit Anhänger 80 km/h)
• Zwei Alternativrouten zur Hauptroute
• Tankstellen, Einkauf und Sehenswürdigkeiten entlang der Route finden
• Auto-Wegpunkte werden automatisch auf befahrbare Straßen gezogen

## v1.8.0 SHORT (EN) — for Play Store (500 chars)
Big update since 1.4!
• New watercolor signpost icon + light cream theme
• Send routes via Bluetooth straight to the Garmin Edge (Komoot-style)
• Phone turn-by-turn navigation with ETA
• Car profiles (max 130 km/h, with trailer 80 km/h)
• Two alternative routes alongside the main route
• Find fuel, shops, sights along the route
• Car waypoints auto-snap to drivable roads

---

## v1.8.0 (DE) — nur dieser Release (für spätere Updates)
**Neues Wegwiesel-Design & Suche entlang der Route**

• Neues App-Icon im Aquarell-Stil: Wegweiser mit zwei Pfeilen — passt zu Bike, Wandern und Auto
• Komplett neues helles Cream-Theme statt Dark Mode, passt zum Logo und ist im Tageslicht besser ablesbar
• Suche entlang der Route: Tankstellen, Einkaufsmöglichkeiten und Sehenswürdigkeiten direkt entlang der Strecke finden — sortiert nach Routenkilometer, mit Abstand zum Track
• Navigation deutlich ruhiger: kein zappelndes Banner mehr, GPS-Heading wird geglättet, Karte rotiert nur noch bei echtem Vorwärtsbewegen
• Voraussichtliche Ankunftszeit (ETA) als Uhrzeit unten rechts auf dem Navigationsbildschirm
• Diverse Kontrast- und Lesbarkeits-Fixes

## v1.8.0 (EN) — this release only
**New Wegwiesel design & on-route POI search**

• New watercolor-style app icon: signpost with two arrows — fits bike, hiking and driving alike
• Brand-new light cream theme replacing dark mode, matches the logo and reads better in daylight
• Search along the route: find fuel stations, shops and sights directly along your track — sorted by route kilometer with side distance
• Navigation now much calmer: no more twitching banner, GPS heading is smoothed, map only rotates while actually moving
• Estimated time of arrival (ETA) as clock time in the bottom-right of the navigation screen
• Various contrast and readability fixes

---

## v1.7.0 (DE)
**Alternativrouten & smarteres Auto-Routing**

• Zwei Alternativrouten zur Hauptroute anzeigen, wie bei Google Maps, mit Chip-Leiste zum Umschalten
• Auto-Wegpunkte werden automatisch auf die nächste befahrbare Straße gezogen — kein „target island failed" mehr, wenn der Pin hinter einer Schranke landet
• Eigenes Auto-Profil bevorzugt Autobahn/Schnellstraße statt sparsamer Schleichwege
• Buttons links und rechts neben der Karte sitzen jetzt über der Alternativen-Leiste

## v1.7.0 (EN)
**Alternative routes & smarter car routing**

• Show two alternative routes next to the main route, Google-Maps-style, with a chip switcher
• Car waypoints are automatically snapped to the nearest drivable road — no more "target island failed" when the pin sits behind a barrier
• Custom car profile prefers motorways and major roads over slow eco shortcuts
• Side buttons sit above the alternatives bar instead of being hidden behind it

---

## v1.6.0 (DE)
**Navigation auf dem Telefon & Auto-Profile**

• Turn-by-Turn Navigation direkt auf dem Telefon — wahlweise mit nach Norden ausgerichteter Karte oder in Fahrtrichtung
• Automatische Neuberechnung der Route bei >50m Abweichung, kein Sprachausgabe-Zwang
• Zwei neue Profile: „Auto" (max 130 km/h) und „Auto mit Anhänger" (max 80 km/h)
• Geschwindigkeit pro Profil im Detail einstellbar

## v1.6.0 (EN)
**Phone turn-by-turn & car profiles**

• Phone-based turn-by-turn navigation — choose north-up or heading-up map orientation
• Automatic re-routing when you drift more than 50 m off route, no forced voice
• Two new profiles: "Car" (max 130 km/h) and "Car with trailer" (max 80 km/h)
• Per-profile speed customisation in the picker

---

## v1.5.0 (DE)
**Routen direkt an die Garmin Edge senden**

• Routen werden — wie bei Komoot — vom Handy per Bluetooth direkt an die Garmin Edge übertragen, statt über Connect-Sync-Umwege
• Eigene Connect IQ App „WegwieselSync" auf der Edge übernimmt den Code und lädt die FIT-Course
• Funktioniert auf iPhone und Android
• Geräte-Picker mit „neu auswählen"-Option für den Fall dass die Verbindung hakt

## v1.5.0 (EN)
**Send routes straight to the Garmin Edge**

• Routes are pushed — just like with Komoot — from your phone via Bluetooth directly to the Garmin Edge, no Connect-Sync detour
• Custom Connect IQ companion app "WegwieselSync" on the Edge consumes the share code and loads the FIT course
• Works on iPhone and Android
• Device picker with a "re-pick" option if the connection gets stuck

---

## v1.4.0 (DE)
**Höhenschattierung, GPX-Import & No-Go-Bereiche**

• Höhenschattierung (Hillshading) als Karten-Overlay für besseren Geländeüberblick
• GPX-Dateien können importiert und auf der Karte angezeigt werden
• No-Go-Bereiche definieren — Routen umfahren diese Zonen automatisch

## v1.4.0 (EN)
**Hillshading, GPX import & no-go areas**

• Hillshading overlay on the map for better terrain context
• Import GPX files and overlay them on the map
• Define no-go areas — the router avoids these zones automatically

---

## v1.3.1 (DE)
**Höhenprofil-Diagramm neu**

• Höhenprofil komplett neu mit 6 Farbmodi (Steigung, Tempo, Belag, …)
• Zoom und Scroll direkt im Diagramm
• Wegpunkt-Marker im Höhenprofil sichtbar

## v1.3.1 (EN)
**Elevation chart rewrite**

• Elevation chart redone with 6 color modes (gradient, speed, surface, …)
• Zoom and scroll inside the chart
• Waypoint markers visible on the elevation profile

---

## v1.3.0 (DE)
**Mehrsprachigkeit**

• Englische Übersetzung der gesamten App
• Sprache folgt der System-Einstellung
• Vorbereitung der i18n-Infrastruktur für weitere Sprachen

## v1.3.0 (EN)
**Localization**

• Full English translation of the app
• Language follows the system setting
• i18n infrastructure prepared for more languages

---

## v1.2.1 (DE)
• Route-Aktionen kompakt unterhalb der Stats statt in der rechten Spalte
• Karte wird nicht mehr durch FAB-Säule verdeckt
• Kleinere Darstellungs-Fixes

## v1.2.0 (DE)
• Oberflächen-Anzeige: Route farbig nach Belag
• Wetter entlang der Route (Temperatur, Wind, Niederschlag)
• Etappenplaner mit automatischem Orts-Snap
• Unterkunfts-Suche entlang der Route
• Teilen via Link
• Adressen statt Koordinaten als Wegpunkt-Name

## v1.2.1 (EN)
• Route actions now compact below stats instead of right column
• Map no longer obscured by FAB column
• Minor visual fixes

## v1.2.0 (EN)
• Surface display: route colored by surface type
• Weather along the route (temperature, wind, precipitation)
• Stage planner with automatic town snapping
• Accommodation search along the route
• Share via link
• Addresses instead of coordinates as waypoint names
