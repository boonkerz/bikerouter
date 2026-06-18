# Charging-prices service (Mobilithek AFIR ad-hoc prices)

Server-side fetcher + bbox API that supplies real **ad-hoc charging prices** to the
Wegwiesel app. The app must **not** hold the mTLS client certificate (it's a public
client, and the Mobilithek limits accesses per cert), so the cert stays here on the
server and the app only ever asks for the prices inside a map/route bounding box.

```
cron/timer:  Mobilithek datexv3 (mTLS) ──fetch_prices.py──> data/charging_prices.json
request:     app ──GET /api/charging-prices?bbox=W,S,E,N──> serve_prices.py ──> points in bbox
```

Pure Python stdlib + (optionally) `jq`-free. No external deps.

## Files
- `fetch_prices.py` — pulls every subscribed dataset via mTLS, extracts a compact
  `{op,name,lat,lon,kwh,min,cur,kw,upd}` per priced site (ad-hoc rate, gross/tax-incl.).
- `serve_prices.py` — bbox API (binds `127.0.0.1`, put Caddy in front).
- `subscriptions.txt` — one subscription ID per line (copy from `.example`).
- `mobilithek.crt` / `mobilithek.key` — the M2M client cert/key (copy from your machine;
  **never commit**, already in `.gitignore`).
- `charging-prices-*.service` / `.timer` — systemd units.

## Deploy (example: /opt/wegwiesel/charging-prices)
```bash
sudo mkdir -p /opt/wegwiesel/charging-prices/data
sudo rsync -a fetch_prices.py serve_prices.py /opt/wegwiesel/charging-prices/
# credentials + config (scp from your local ~/mobilithek)
scp mobilithek_client/{mobilithek.crt,mobilithek.key} server:/opt/wegwiesel/charging-prices/
cp subscriptions.txt.example /opt/wegwiesel/charging-prices/subscriptions.txt   # then edit

# first fetch
cd /opt/wegwiesel/charging-prices && python3 fetch_prices.py

# API service + daily fetch timer
sudo cp charging-prices-api.service charging-prices-fetch.service charging-prices-fetch.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now charging-prices-api charging-prices-fetch.timer
```

## Caddy
Add to the `wegwiesel.app` site block (so the app calls the same origin):
```
handle /api/charging-prices* {
    reverse_proxy 127.0.0.1:8088
}
```

## API
```
GET /api/charging-prices?bbox=<west>,<south>,<east>,<north>   # lon,lat,lon,lat (GeoJSON order)
->  { generated, attribution, count, points:[ {op,name,lat,lon,kwh,min,cur,kw,upd}, ... ] }
```
- `kwh` / `min` = gross (tax-incl.) ad-hoc price per kWh / per minute, currency `cur`.
- bboxes larger than `MAX_SPAN_DEG` (3°) per axis are rejected; up to `MAX_POINTS` (1000) returned.

## Adding more CPOs
Subscribe the dataset on Mobilithek, add its ID to `subscriptions.txt`, done — the
parser is schema-driven (DATEX II v3) and handles any AFIR EnergyInfrastructure feed.
