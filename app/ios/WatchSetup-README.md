# Wegwiesel Watch — Xcode Setup

Diese Dateien sind der WatchOS-Companion für Wegwiesel (v2.2 Phase 1).
Code ist fertig, aber das Xcode-Target muss einmalig in der Xcode-GUI
angelegt werden — `project.pbxproj` direkt zu editieren wäre zu brüchig
und würde Codemagic-Builds kaputt machen.

## Was hier liegt

```
ios/WegwieselWatch Watch App/        ← Xcode-Standardname für Watch-only-Targets
├── WegwieselWatchApp.swift          – @main-Entry, hält den WatchSessionController
├── WatchSessionController.swift     – WCSessionDelegate + @Published-State
├── NavigationGlanceView.swift       – SwiftUI: Pfeil + Distanz + ETA
└── Info.plist                       – WKApplication=true, Companion-Bundle-ID
```

Xcode setzt für „Watch-only App"-Targets per default einen Ordnernamen
mit der `Watch App`-Suffix — Leerzeichen inklusive. Wir folgen dieser
Convention, damit `project.pbxproj` und Filesystem konsistent bleiben.

Plus, schon eingecheckt:

```
ios/Runner/WatchBridge.swift    – Phone-Seite: Method-Channel → WCSession
ios/Runner/AppDelegate.swift    – registriert WatchBridge beim Start
lib/services/watch_sync_service.dart  – Dart-API für die Navigation-Screen
```

## Setup in Xcode (einmalig, ~5 Minuten)

1. **Öffne** `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target…**
   - Plattform: **watchOS**
   - Template: **App** (NICHT „Watch App for iOS App", das ist die alte
     mit Extension-Target — wir wollen den modernen single-target App-Style)
   - Product Name: `WegwieselWatch`
   - Bundle Identifier: `com.thomaspeterson.bikerouter.watchkitapp`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - „Embed in Companion Application" auf **Runner**
3. Xcode legt ein Verzeichnis `WegwieselWatch/` mit Standard-Files an.
   **Lösche** alle vier automatisch erzeugten Dateien (`*App.swift`,
   `ContentView.swift`, `Assets.xcassets`, `Preview Content/`).
4. **Rechtsklick** auf den (jetzt leeren) `WegwieselWatch`-Ordner →
   **Add Files to "Runner"…** → wähle die vier Dateien aus
   `ios/WegwieselWatch/` aus diesem Repo:
   - `WegwieselWatchApp.swift`
   - `WatchSessionController.swift`
   - `NavigationGlanceView.swift`
   - `Info.plist`
   - **Wichtig**: Target-Membership = nur `WegwieselWatch`, nicht
     `Runner`.
5. Im **WegwieselWatch-Target** → **Build Settings**:
   - `INFOPLIST_FILE` = `WegwieselWatch/Info.plist`
   - `MARKETING_VERSION` und `CURRENT_PROJECT_VERSION` aus dem Runner-
     Target übernehmen (oder leer lassen — Codemagic überschreibt eh
     mit `pubspec.yaml`).
6. **Signing & Capabilities**:
   - Team auf dasselbe wie Runner.
   - Bundle-Identifier wie oben.

## Test im Simulator

1. Xcode → Scheme auswählen: `WegwieselWatch`.
2. Destination: ein iPhone-Simulator MIT gepaarter Apple Watch
   (z.B. „iPhone 15 Pro + Apple Watch Series 9 45mm").
3. **Run**. Beim Start macht der Bridge nichts; sobald in der App
   Navigation gestartet wird, sollte die Watch den Pfeil + die Distanz
   zeigen.

## Codemagic

Der `WegwieselWatch`-Target muss in der Codemagic-Workflow-Definition
mitgebaut werden. Im **Workflow Editor**:

- iOS-Workflow → **Build for distribution**: das Runner-Schema umfasst
  per Default das eingebettete Watch-Target — sollte automatisch
  funktionieren.
- Falls nicht: in **Custom signing identities** beide Bundle-IDs
  hinzufügen (`com.thomaspeterson.bikerouter` und
  `…watchkitapp`). App Store Connect verlangt für die Watch eine
  separate App-Record-Eintragung; das ist nur die erste Submission, ab
  dann läuft sie als Teil der iOS-App mit.

## Datenfluss

```
NavigationScreen (Dart)
  └─ WatchSyncService.updateNavigation(direction, distM, km, min, street?)
     └─ MethodChannel('wegwiesel/watch')
        └─ WatchBridge.handle (Swift, Phone)
           ├─ WCSession.transferUserInfo  (durable queue)
           └─ WCSession.sendMessage       (live wenn Watch wach + foreground)
              └─ WatchSessionController.applyPayload (Swift, Watch)
                 └─ NavigationGlanceView (SwiftUI)
```

Method-Calls vom Phone:

| Method            | Args                                                                | Effect                                       |
|-------------------|---------------------------------------------------------------------|----------------------------------------------|
| `isReachable`     | —                                                                   | `Future<bool>` — Watch erreichbar?           |
| `updateNavigation`| `{direction, distanceMeters, remainingKm, remainingMinutes, streetName?}` | Watch zeigt neue Anweisung                   |
| `stopNavigation`  | —                                                                   | Watch fällt zurück in den "idle"-Zustand     |

## v2.2 Phase 2 — was noch fehlt

- Wear OS Companion (Android-Modul, Kotlin + Compose-for-Wear, Wear
  Data Layer API). Mirror dieser Architektur, einfach mit anderen
  Klassennamen.
- Optional: Watch-Komplikation (`WidgetKit` für watchOS) mit „nächste
  Abbiegung in X m". Wenn die App-Variante stabil läuft.
