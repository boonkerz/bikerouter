#!/usr/bin/env python3
"""Pull AFIR ad-hoc charging prices (DATEX II v3) from the Mobilithek for each
subscribed dataset via mTLS and write a compact charging_prices.json that the
bbox API serves.

Runs on the server (cron, ~daily). No third-party deps (stdlib only).

Config via env:
  MOBILITHEK_CERT   client cert PEM            (default ./mobilithek.crt)
  MOBILITHEK_KEY    client private key PEM     (default ./mobilithek.key)
  SUBSCRIPTIONS     comma-separated sub IDs, or path to a file with one ID/line
                                               (default ./subscriptions.txt)
  OUT_FILE          output json                (default ./data/charging_prices.json)
  LOCAL_FILE        debug: parse this JSON file instead of downloading
"""
import gzip
import json
import os
import ssl
import sys
import time
import urllib.request

BASE = "https://mobilithek.info:8443/mobilithek/api/v1.0/subscription/datexv3"
HERE = os.path.dirname(os.path.abspath(__file__))


def cfg(name, default):
    return os.environ.get(name, default)


def subscription_ids():
    raw = cfg("SUBSCRIPTIONS", os.path.join(HERE, "subscriptions.txt"))
    if os.path.isfile(raw):
        with open(raw) as f:
            lines = [l.strip() for l in f]
    else:
        lines = raw.split(",")
    return [x for x in (l.split("#", 1)[0].strip() for l in lines) if x]


def fetch(sub_id, ctx):
    url = f"{BASE}?subscriptionID={sub_id}"
    req = urllib.request.Request(url, headers={"Accept-Encoding": "gzip"})
    with urllib.request.urlopen(req, context=ctx, timeout=180) as resp:
        body = resp.read()
    # The broker always gzip-compresses; urllib does not auto-decode it.
    if body[:2] == b"\x1f\x8b":
        body = gzip.decompress(body)
    return json.loads(body)


def _walk(node):
    """Yield every dict in a nested JSON structure."""
    if isinstance(node, dict):
        yield node
        for v in node.values():
            yield from _walk(v)
    elif isinstance(node, list):
        for v in node:
            yield from _walk(v)


def _gross(price):
    """Convert a DATEX energyPrice entry to a gross (tax-incl.) value."""
    v = price.get("value")
    if v is None:
        return None
    if price.get("taxIncluded"):
        return v
    return v * (1 + (price.get("taxRate") or 0) / 100.0)


def _find_coords(node):
    """First lat/lon pair anywhere in the site. CPOs put coordinates at
    different depths (site- vs station-level), so search recursively rather
    than assuming one fixed path."""
    for obj in _walk(node):
        lat = obj.get("latitude")
        lon = obj.get("longitude")
        if isinstance(lat, (int, float)) and isinstance(lon, (int, float)):
            return lat, lon
    return None


def site_to_point(site, operator):
    coords = _find_coords(site)
    if coords is None:
        return None
    lat, lon = coords
    # name
    name = None
    try:
        name = site["additionalInformation"][0]["values"][0]["value"]
    except (KeyError, IndexError, TypeError):
        pass
    # first ad-hoc rate anywhere under the site + max charging power
    adhoc, max_w = None, None
    for obj in _walk(site):
        rp = obj.get("ratePolicy")
        if adhoc is None and isinstance(rp, dict) and rp.get("value") == "adHoc":
            adhoc = obj
        p = obj.get("availableChargingPower")
        if isinstance(p, list):
            for w in p:
                if isinstance(w, (int, float)) and (max_w is None or w > max_w):
                    max_w = w
    if not adhoc:
        return None
    kwh = per_min = None
    cur = "EUR"
    for price in adhoc.get("energyPrice", []):
        pt = (price.get("priceType") or {}).get("value")
        g = _gross(price)
        if pt == "pricePerKWh" and kwh is None:
            kwh = g
        elif pt == "pricePerMinute" and per_min is None:
            per_min = g
    if adhoc.get("applicableCurrency"):
        cur = adhoc["applicableCurrency"][0]
    if kwh is None:
        return None

    def r(x, n):
        return None if x is None else round(x, n)

    return {
        "op": operator,
        "name": name,
        "lat": round(lat, 6),
        "lon": round(lon, 6),
        "kwh": r(kwh, 3),
        "min": r(per_min, 3),
        "cur": cur,
        "kw": None if max_w is None else round(max_w / 1000.0),
        "upd": adhoc.get("lastUpdated"),
    }


def extract(payload):
    pub = payload["payload"]["aegiEnergyInfrastructureTablePublication"]
    operator = (pub.get("publicationCreator") or {}).get("nationalIdentifier", "unknown")
    points = []
    for table in pub.get("energyInfrastructureTable", []):
        for site in table.get("energyInfrastructureSite", []):
            pt = site_to_point(site, operator)
            if pt:
                points.append(pt)
    return points


def main():
    out_file = cfg("OUT_FILE", os.path.join(HERE, "data", "charging_prices.json"))
    os.makedirs(os.path.dirname(out_file), exist_ok=True)

    local = os.environ.get("LOCAL_FILE")
    all_points = []
    sources = []
    if local:
        with open(local) as f:
            payload = json.load(f)
        all_points = extract(payload)
        sources.append({"file": local, "points": len(all_points)})
    else:
        ctx = ssl.create_default_context()
        ctx.load_cert_chain(cfg("MOBILITHEK_CERT", os.path.join(HERE, "mobilithek.crt")),
                            cfg("MOBILITHEK_KEY", os.path.join(HERE, "mobilithek.key")))
        for sub in subscription_ids():
            try:
                pts = extract(fetch(sub, ctx))
                all_points.extend(pts)
                sources.append({"sub": sub, "points": len(pts)})
                print(f"  {sub}: {len(pts)} priced sites", file=sys.stderr)
            except Exception as e:  # one bad feed must not sink the rest
                print(f"  {sub}: FAILED {e}", file=sys.stderr)
                sources.append({"sub": sub, "error": str(e)})

    result = {
        "generated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "attribution": "Quelle: Mobilithek / AFIR Ad-hoc-Preise; jeweiliger Ladenetzbetreiber",
        "count": len(all_points),
        "sources": sources,
        "points": all_points,
    }
    tmp = out_file + ".tmp"
    with open(tmp, "w") as f:
        json.dump(result, f, ensure_ascii=False, separators=(",", ":"))
    os.replace(tmp, out_file)  # atomic
    print(f"wrote {len(all_points)} points -> {out_file}", file=sys.stderr)


if __name__ == "__main__":
    main()
