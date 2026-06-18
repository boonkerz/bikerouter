# Charging-prices service (Mobilithek AFIR ad-hoc prices)

Docker service that supplies real **ad-hoc charging prices** to the Wegwiesel app.
The app must **not** hold the mTLS client certificate (it's a public client, and the
Mobilithek limits accesses per cert), so the cert stays on the server and the app only
asks for the prices inside a map/route bounding box.

```
inside the container:  Mobilithek datexv3 (mTLS) ──fetch_prices.py (daily)──> /data/charging_prices.json
request via Caddy:      app ──GET /api/charging-prices?bbox=W,S,E,N──> serve_prices.py ──> points in bbox
```

Pure Python stdlib, no external deps. Runs as the `charging-prices` service in
`docker-compose.prod.yml`; Caddy routes `/api/charging-prices*` to it.

## Files
- `fetch_prices.py` — pulls every subscribed dataset via mTLS, extracts a compact
  `{op,name,lat,lon,kwh,min,cur,kw,upd}` per priced site (ad-hoc rate, gross/tax-incl.).
- `serve_prices.py` — bbox API (`/api/charging-prices?bbox=W,S,E,N`, lon,lat,lon,lat).
- `entrypoint.sh` — initial + daily fetch in the background, API in the foreground.
- `Dockerfile` — `python:3.12-slim`.
- `subscriptions.txt.example` — one subscription ID per line (copy to `subscriptions.txt`).

## Server provisioning (one-time, on the host /opt/wegwiesel)
The compose service mounts three host paths:
```
/opt/wegwiesel/charging-prices/secrets/mobilithek.crt   # M2M client cert (PEM)
/opt/wegwiesel/charging-prices/secrets/mobilithek.key   # M2M private key
/opt/wegwiesel/charging-prices/subscriptions.txt        # subscribed dataset IDs, one per line
/opt/wegwiesel/charging-prices-data/                    # output (auto-created)
```
Copy the cert/key (from `~/mobilithek/mobilithek.{crt,key}`) into `secrets/` and create
`subscriptions.txt`. Then deploy as usual (Terraform / `docker compose up -d --build
charging-prices` + `caddy reload`). The container fetches on start and then daily.

## API
```
GET /api/charging-prices?bbox=<west>,<south>,<east>,<north>   # lon,lat,lon,lat (GeoJSON order)
->  { generated, attribution, count, points:[ {op,name,lat,lon,kwh,min,cur,kw,upd}, ... ] }
```
- `kwh` / `min` = gross (tax-incl.) ad-hoc price per kWh / per minute, currency `cur`.
- bboxes larger than `MAX_SPAN_DEG` (3°) per axis are rejected; up to `MAX_POINTS` (1000) returned.

## Adding more CPOs
Subscribe the dataset on Mobilithek, add its ID to `subscriptions.txt`, restart the
service — the parser is schema-driven (DATEX II v3) and handles any AFIR
EnergyInfrastructure feed.
