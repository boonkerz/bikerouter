# Connect IQ Store Submission — WegwieselSync

## Artefakte
- **App-Paket:** `garmin/WegwieselSync.iq` (148 KB, 17 Edge-Geräte)
- **Store-Icon (500×500):** `store_assets/garmin/store_icon_500.png`
- **Beschreibung DE:** `store_assets/garmin/description_de.md`
- **Beschreibung EN:** `store_assets/garmin/description_en.md`

## Re-Build
```
cd garmin && ./build.sh store
```

## Screenshots aus dem Simulator
Connect IQ Store verlangt mindestens 1 Screenshot, empfohlen 3–5 pro Gerätegröße.

1. Simulator starten:
   ```
   ~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.1.0-2026-03-09-6a872a80b/bin/connectiq
   ```
2. Im Simulator-Fenster: **File → Open** → `garmin/WegwieselSync.prg` (oder nochmal mit `./build.sh sideload` bauen)
3. Device wählen (Empfehlung: 1 großes, 1 mittleres, 1 kleines):
   - Edge 1050 (320×480)
   - Edge 840 (246×322)
   - Edge 530 (246×322)
4. Pro Gerät 3 Screenshots: Startansicht, Code-Eingabe (Text-Picker), Erfolgsmeldung mit "Saved"
5. Über **File → Take Screenshot** (oder `Ctrl+P`) speichern.

## Upload-Schritte
1. https://apps.garmin.com/developer/manage öffnen
2. **Submit New App** → "Watch App" → Garmin Edge wählen
3. Felder:
   - App Name: **WegwieselSync**
   - Short Description: aus `description_de.md` / `description_en.md` übernehmen
   - Long Description: ebenso
   - Category: **Apps → Tools** (oder **Sports & Recreation**)
   - Permissions: Communications (automatisch erkannt)
   - Privacy: "Diese App fragt nur wegwiesel.app ab — keine User-Daten, kein Tracking."
   - Privacy Policy URL: https://wegwiesel.app/datenschutz (falls vorhanden)
4. Artefakte:
   - `.iq`-Datei hochladen
   - Store-Icon `store_icon_500.png` hochladen
   - Screenshots hochladen
5. Sprachen: **Deutsch (primary)** + **English**
6. Submit zur Garmin-Review (Dauer üblicherweise 3–7 Tage)

## Review-Hinweise (häufige Ablehnungsgründe)
- App-Name darf nicht "Garmin" enthalten ✓ (haben wir nicht)
- Communications-Permission braucht eine Erklärung in der Beschreibung ✓ (steht drin)
- Erstveröffentlichung verlangt manchmal eine kurze Test-Anleitung mit echtem Sync-Code — Garmin-Reviewer testet sonst nicht
- Logo muss zur App passen und darf nicht generisch sein ✓ (Wegwiesel-Aquarell)

## Optional: Test-Code für Reviewer
Wenn Garmin einen Demo-Code anfordert, beim Submission-Formular im "Reviewer Notes"-Feld einen permanent gültigen Test-Code hinterlegen — z.B. einen, der auf wegwiesel.app dauerhaft eine kurze Test-FIT-Route hostet. Aktuell ist die Code-Lebensdauer 24 h, das passt nicht zum Review-Zyklus. Lösung: serverseitig einen `TESTAB`-Code als "ewig gültig" markieren, der eine 5 km Demo-Strecke liefert.
