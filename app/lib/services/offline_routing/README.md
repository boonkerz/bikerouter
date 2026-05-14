# Offline Routing — Pure-Dart-Port der BRouter-Routing-Engine

Roadmap für v2.0. Phasen 1-2 sind in `main` committed, der Rest steht aus.

## Phase 1 — Scaffolding ✓
- [x] `OfflineRouter` abstrakte Schnittstelle
- [x] `Lookups` Parser für `lookups.dat` (Text)
- [x] `Rd5Reader` mit Header- / Sub-Tile-Index-Parsing
- [x] Region-Download-Service (.rd5-Segmente von `wegwiesel.app`)
- [x] Pure-Dart-Routingkern: Graph-Modell, Trekking-Profil, A*-Suche,
  GeoJSON/`RouteResult`-Ausgabe

## Phase 2 — RD5 Decoder ✓ MVP
Die binären Sub-Tiles enthalten Huffman-codierte Bitstreams mit Knoten und ausgehenden Ways. Die Kern-Logik aus BRouter Java übersetzt:

- [x] `MicroCache2` (Java) → `Rd5MicroCacheDecoder` (Dart)
- [x] `StatCoderContext` → `BrouterBitCoder`
- [x] Lat/Lon-Diff-Encoding gegen den MicroCache-Mittelpunkt
- [x] WayLink-Frames inkl. interner/externer Targets und Geometrie-Skip
- [ ] Semantische Tag-Auflösung aus `lookups.dat` in echte `highway/surface/access`-Maps

Schritt für Schritt:
1. [x] BitStream-Reader mit Variable-Length-Integers (`decodeNoisyNumber`, `decodeVarBits`)
2. [x] NodeData-Frame: lat/lon-Delta, Höhe, Knoten-ID
3. [x] WayLink-Frame: Ziel-NodeID-Delta, Tag-Beschreibung (Huffman-Index)
4. [x] Cross-Sub-Tile-Referenzen als externe Link-Koordinaten

## Phase 3 — Profile-Interpreter
Option A — Eigene Mini-Sprache nachbauen (`assign`, `if`/`then`/`else`, Arithmetik): ~3 Tage
Option B — Ein einziges Profil hardcoden (Trekking): ~1 Tag

Umgesetzt ist B für v2.0.0. A bleibt v2.0.x-Material.

## Phase 4 — A*-Suche
- [x] MVP: vorwärts gerichtete A*-Suche mit Haversine-Heuristik
- [x] Priority Queue auf Basis von `SplayTreeMap`
- [x] Hardcodiertes `trekking`-Kostenmodell als erstes Offline-Profil
- [ ] Knoten-Cache mit LRU (Sub-Tiles werden on-demand decodiert und gehalten)
- [ ] Bidirektionale Suche für große Regionen

## Phase 5 — Region-Download + Integration
- [x] Neuer Endpoint `https://wegwiesel.app/segments/<filename>.rd5` via Caddy → segments4-Volume
- [x] App-UI: „Routing-Region herunterladen" analog zu Offline-Karten
- [x] Routing-Facade in `brouter_service.dart`: lokal versuchen → bei Fehler BRouter-Server
- [x] App-Start initialisiert `Rd5OfflineRouter`, wenn lokale Segmente vorhanden sind

## Referenzen
- Java-Source: https://github.com/abrensch/brouter (subdir `brouter-codec/`)
- File-Format-Notes: BRouter README + `MicroCache2.java` Kommentare
- Lookups-Format: `misc/lookups/lookups.dat` im BRouter-Repo
