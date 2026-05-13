# Offline Routing — Pure-Dart-Port der BRouter-Routing-Engine

Roadmap für v2.0. Phasen 1-2 sind in `main` committed, der Rest steht aus.

## Phase 1 — Scaffolding ✓
- [x] `OfflineRouter` abstrakte Schnittstelle
- [x] `Lookups` Parser für `lookups.dat` (Text)
- [x] `Rd5Reader` mit Header- / Sub-Tile-Index-Parsing
- [ ] Region-Download-Service (.rd5-Segmente von `wegwiesel.app`)

## Phase 2 — RD5 Decoder
Die binären Sub-Tiles enthalten Huffman-codierte Bitstreams mit Knoten und ausgehenden Ways. Die Kern-Logik aus BRouter Java übersetzt:

- `MicroCache2` (Java) → `Rd5SubTileDecoder` (Dart)
- `StatCoderContext` → `BitStreamReader`
- `TagValueCoder` → `TagDecoder` (nutzt `Lookups`)
- Lat/Lon-Diff-Encoding gegen den Sub-Tile-Mittelpunkt
- Way-Description-Wiederholung über `count` aus den Lookups (Huffman-Frequenz)

Schritt für Schritt:
1. BitStream-Reader mit Variable-Length-Integers (`decodeNoisyNumber`, `decodeVarBits`)
2. NodeData-Frame: lat/lon-Delta, Höhe, Knoten-ID
3. WayLink-Frame: Ziel-NodeID-Delta, Tag-Beschreibung (Huffman-Index)
4. Cross-Sub-Tile-Referenzen (8 Nachbar-Sub-Tiles für Knoten, die auf der Grenze sitzen)

## Phase 3 — Profile-Interpreter
Option A — Eigene Mini-Sprache nachbauen (`assign`, `if`/`then`/`else`, Arithmetik): ~3 Tage
Option B — Ein einziges Profil hardcoden (Trekking): ~1 Tag

Empfohlen B für v2.0.0, A für v2.0.x wenn andere Profile gewünscht.

## Phase 4 — A*-Suche
- Bidirektionale A* mit Haversine als Heuristik
- Priority Queue (`SplayTreeMap` als Stand-in für Heap, oder `package:collection`)
- Knoten-Cache mit LRU (Sub-Tiles werden on-demand decodiert und gehalten)
- Profile-Filter pro Edge-Traversal

## Phase 5 — Region-Download + Integration
- Neuer Endpoint `https://wegwiesel.app/segments/<filename>.rd5` via Caddy → segments4-Volume
- App-UI: „Routing-Region herunterladen" analog zu Offline-Karten
- Routing-Facade in `brouter_service.dart`: bei Online → BRouter-Server, bei Offline → `OfflineRouter`

## Referenzen
- Java-Source: https://github.com/abrensch/brouter (subdir `brouter-codec/`)
- File-Format-Notes: BRouter README + `MicroCache2.java` Kommentare
- Lookups-Format: `misc/lookups/lookups.dat` im BRouter-Repo
