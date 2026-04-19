# App Store Connect – Checkliste für Wegwiesel

Alle Texte und Pläne für das App-Store-Listing. Liste zum Abhaken, Reihenfolge ist egal.

## Texte & Metadaten
- [ ] **App-Name / Untertitel / Keywords / Beschreibung** → `description_de.md`, `description_en.md` 1:1 in App Store Connect einfügen (Locale: Deutsch (DE), English (US))
- [ ] **Promotional Text / Werbetext** → oben in derselben Datei
- [ ] **What's New / Neuerungen** → `whats_new.md`
- [ ] **App Review Information** → `review_info.md` (Telefonnummer ergänzen!)
- [ ] **App Privacy** → `privacy_nutrition_labels.md` in der „App Privacy"-Sektion abarbeiten

## Assets
- [ ] **App Icon 1024×1024** → `app/assets/icon/icon.png` (existiert, ohne Alpha ist in pubspec konfiguriert)
- [ ] **Screenshots** → Shot-Plan in `screenshots.md`. 3–8 Stück für 6.9"/6.5" iPhone
- [ ] **App-Vorschau-Video** (optional, skip für v1)

## URLs
- [x] Privacy: https://wegwiesel.app/legal/datenschutz.html
- [x] Support: https://wegwiesel.app
- [x] Marketing: https://wegwiesel.app

## Build
- [ ] iOS-Build via Codemagic (v1.2.1+33) an App Store Connect hochladen
- [ ] Nach Upload: Processing abwarten (~15–30 min), dann Build in der Version auswählen
- [ ] Kategorien setzen: **Navigation** (primary), **Sports** (secondary)
- [ ] Altersfreigabe: 4+
- [ ] Preis: Free
- [ ] Verfügbarkeit: Weltweit

## Review einreichen
- [ ] TestFlight Internal Testing zuerst (optional aber sinnvoll)
- [ ] „Submit for Review"
- [ ] Export Compliance: ITSAppUsesNonExemptEncryption steht bereits auf `false` (kein zusätzliches Formular)
- [ ] Content Rights: eigene Inhalte, keine Drittrechte
