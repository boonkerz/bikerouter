# Screenshot-Plan für App Store Connect

## Erforderliche iPhone-Größen
Apple will seit Okt 2024 nur noch **6.9"/6.5"** Screenshots verpflichtend:
- **6.9"** (iPhone 16 Pro Max / 15 Pro Max) – 1290 × 2796 px
- **6.5"** (iPhone 11 Pro Max / Xs Max) – 1242 × 2688 px

Optional iPad:
- **13"** (iPad Pro M4) – 2064 × 2752 px

Man kann dieselben 6.9"-Shots auch für 6.5" hochladen (wird akzeptiert).

## Shot-Liste (5–10 empfohlen, 3 Minimum)

1. **Hero: Route mit farbigem Belag**
   Deutsche Route, sichtbar asphalt+pflaster+schotter Segmente, Stats-Leiste mit Aktionen unten.
   → Overlay-Text: „Belag auf einen Blick"

2. **Rundkurs-Planer**
   Runde-Tab aktiv, Slider mit 50 km, Richtungsrose, berechneter Rundkurs auf Karte.
   → „Rundtouren in Sekunden"

3. **Höhenprofil + Oberflächen-Chart**
   Längere Route, beide Charts sichtbar, Hover-Marker auf der Karte.
   → „Höhenmeter & Belag entlang der Strecke"

4. **Wetter entlang der Route**
   Wetter-Bottom-Sheet mit mehreren Zeitpunkten, Windpfeile, Temperatur.
   → „Wetter an jedem Streckenpunkt"

5. **Etappenplaner**
   Etappenplaner-Sheet mit 3–5 Etappen, jeweils mit Ort gesnappt.
   → „Mehrtagestouren mit Orts-Snap"

6. **Unterkünfte**
   Unterkunft-Sheet mit Hotel-Liste, Emojis, Sternen, Entfernungen.
   → „Unterkünfte entlang des Wegs"

7. **Sights / Sehenswürdigkeiten**
   Karte mit Sights-Icons (Burg, Aussichtspunkt, Badestelle).
   → „Entdecke, was am Weg liegt"

8. **Profile & GPX**
   Profil-Dropdown offen (Rennrad/Gravel/Trekking/MTB), GPX-Button sichtbar.
   → „Für jedes Rad das passende Profil"

## Wie erzeugen (automatisiert, empfohlen)
Der GitHub-Actions-Workflow **`.github/workflows/screenshots.yml`** erzeugt alle
Screenshots auf dem self-hosted Mac-Runner und hängt sie als Artefakte an. Manuell
auslösen: GitHub → Actions → **Screenshots** → *Run workflow* (oder beim Veröffentlichen
eines GitHub-Releases). Artefakte: `ios-screenshots` (Phone 1290×2796 + Watch),
`android-screenshots` (Phone aus `wegwiesel.app` + Wear).

Vier Oberflächen, je eigener Mechanismus:
- **iOS-Phone** — aus dem Web-Build (`wegwiesel.app`) in iPhone-6.9"-Auflösung
  (1290×2796), via `scripts/screenshot-runner` (`SHOT_W/SHOT_H`-env). Echte
  iOS-Simulator-Shots sind auf der **GPU-losen Proxmox-macOS-VM nicht möglich**:
  der Simulator braucht Metal und rendert sonst schwarz. `scripts/ios-screenshots.sh`
  (Sim-Weg) bleibt im Repo für den Fall, dass GPU-Passthrough eingerichtet wird.
- **Apple Watch** — `scripts/watch-screenshots.sh`: env-gated Screenshot-Modus der
  Watch-App (`WW_WATCH_SHOTS=1`, `ScreenshotSupport.swift`) zeigt je einen Screen,
  `xcrun simctl io … screenshot` nimmt auf.
- **Android-Phone** — `scripts/screenshot-runner` rendert `wegwiesel.app` headless in
  Chromium (kein Gerät nötig; zeigt den **deployten** Stand).
- **Wear OS** — `scripts/wear-screenshots.sh`: Compose Preview Screenshot Testing
  rendert `@Preview`s (`wear/src/screenshotTest/…`) ohne Emulator zu PNG.

Watch- und Wear-Schritte sind `continue-on-error` und beim ersten echten Lauf noch zu
validieren (Simulator-Name, Plugin-Version).

## Wie erzeugen (manuell, Fallback)
- iOS-Simulator mit iPhone 16 Pro Max Target starten, App installieren, Screenshots via `xcrun simctl io booted screenshot` oder einfach Cmd+S im Simulator.
- Alternativ auf echtem iPhone 16 Pro Max: Side-Button + Lauter kurz drücken.
- Hintergrund-Route: sinnvolle Testrouten (z.B. Bodensee-Rundtour für Shot 5, Alpencross-Stück für Shot 1, Hamburger Stadttour für Shot 6).

## Overlay-Rahmen (optional)
Falls Marketing-Shots gewünscht: Tools wie `Screenshots.pro`, `ScreenshotMaker` oder `Figma` mit iPhone-Frame-Templates nutzen. Für v1 reichen auch pure Simulator-Shots.
