# Wegwiesel Wear — Wear OS Companion

Standalone Wear OS 3+ Companion-App für Wegwiesel. Spiegelt den Apple-
Watch-Aufbau (siehe `ios/WegwieselWatch/`) mit der Wearable Data Layer
API von Google Play Services.

## Was hier liegt

```
android/wear/
├── build.gradle.kts                      – Gradle-Modul-Definition (Compose-for-Wear)
├── src/main/
│   ├── AndroidManifest.xml               – WearableListenerService + Standalone-Flag
│   ├── res/values/strings.xml            – app_name
│   └── kotlin/.../wear/
│       ├── MainActivity.kt               – ComponentActivity + setContent
│       ├── NavigationState.kt            – NavigationStateHolder (StateFlow)
│       ├── NavigationGlanceScreen.kt     – (in MainActivity inline)
│       └── WearableMessageListener.kt    – empfängt DataItems + Messages vom Phone
```

Plus, schon im Phone-Modul:

```
android/app/src/main/kotlin/.../WatchBridge.kt   – Method-Channel → Wearable APIs
android/app/src/main/kotlin/.../MainActivity.kt  – registriert WatchBridge in configureFlutterEngine
android/app/build.gradle.kts                     – play-services-wearable Dependency
android/settings.gradle.kts                      – include(":wear")
```

## Bauen auf Linux

Im Gegensatz zur Apple-Watch braucht Wear OS **kein Mac** — Android
Studio läuft auf Linux. Lokal probieren:

```bash
cd app/android
./gradlew :wear:assembleRelease     # baut wear-release-APK
```

Das APK landet unter `wear/build/outputs/apk/release/wear-release.apk`.

## Test im Emulator

1. Android Studio öffnen, Tools → Device Manager.
2. **Wear OS-Emulator anlegen**: „Wear OS Large Round 320×320 Wear-OS-3"
   (oder „Square 384×384" für Watch-Face-Geräte).
3. **Phone-Emulator + Watch koppeln**: in Wear OS Emulator → Settings →
   System → About → 7× auf Build-Nummer tippen → Dev-Options → ADB-Debug
   aktivieren. Dann mit Wear OS Companion App auf dem Phone-Emulator
   pairen (Setup-Anleitung in Android Studio Help).
4. Beide gleichzeitig laufen lassen. Phone-App starten, in Navigation
   gehen — Watch sollte den Pfeil zeigen.

## Codemagic

Wear OS hat einen eigenen Application-ID (`…wear`) und damit eine
**eigene Play-Console-Eintragung**. Das ist Wear-OS-3-Konvention
(Standalone-APK). Bedeutet:

1. In der Play Console eine zweite App-Eintragung anlegen mit
   Bundle-ID `com.thomaspeterson.bikerouter.wear`. Wear-OS-Form-Factor
   auswählen.
2. Codemagic-Workflow erweitern um einen zweiten Build-Step:
   - Phone-Build: `flutter build appbundle --release` (wie bisher)
   - Wear-Build: `cd android && ./gradlew :wear:bundleRelease` produziert
     `app/android/wear/build/outputs/bundle/release/wear-release.aab`
3. Beide AABs hochladen — Phone in den normalen Track, Wear in den
   Wear-Track der zweiten App-Eintragung.

Im Codemagic-Workflow-Editor:
- **Add publishing → Google Play** zweimal: einmal für jede App-ID
- Im **Build-Args**-Block: `;./gradlew :wear:bundleRelease` als
  Post-Build-Schritt

## Datenfluss

```
NavigationScreen (Dart)
  └─ WatchSyncService.updateNavigation(direction, distM, km, min, street?)
     └─ MethodChannel('wegwiesel/watch')
        └─ WatchBridge.onMethodCall (Kotlin, Phone)
           ├─ DataClient.putDataItem(/wegwiesel/nav)   – durable
           └─ MessageClient.sendMessage(/wegwiesel/nav) – live (wenn Watch reachable)
              └─ WearableMessageListener.onDataChanged / onMessageReceived (Kotlin, Watch)
                 └─ NavigationStateHolder.apply(payload)
                    └─ Compose UI (Wear OS) → MainActivity.NavigationGlance
```

Wire-Format (PutDataMap):
- `direction` (String) — "straight"/"left"/"right"/"u_turn"/"arrived"/…
- `distanceMeters` (Int)
- `remainingKm` (Double)
- `remainingMinutes` (Int)
- `streetName` (String, optional)
- `ts` (Long) — Timestamp, zwingt PutData-Diff (sonst dedupliziert die Wearable-API identische Payloads)

## Was noch fehlt (v2.2 Phase 3 wenn überhaupt)

- Wear-Komplikationen (Tile-API) mit „Nächste Abbiegung in X m" als
  glance auf der Hauptanzeige
- App-Icon (aktuell System-Compass-Default)
- Lokalisierung (aktuell DE-only Strings inline)
