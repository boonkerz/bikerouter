#!/usr/bin/env python3
"""Poll the Mobilithek dynamic (dyn) AFIR status feeds and maintain a live
charging-point status, joined to the static stations by site idG.

The dyn feeds are DELTA deliveries — each pull returns only the points whose
status changed since the last pull (HTTP 204 when nothing changed). So we keep a
persistent per-refill-point store, apply each delta, expire stale entries, and
write a per-site aggregate that the bbox API serves.

Run frequently (entrypoint loops it, ~every 2-3 min). stdlib only.

Env:
  MOBILITHEK_CERT / MOBILITHEK_KEY      mTLS client cert/key
  STATUS_SUBSCRIPTIONS                  comma list or file of dyn subscription IDs
  STORE_FILE   (default ./data/charging_status_store.json)  raw per-point store
  STATUS_FILE  (default ./data/charging_status.json)        per-site aggregate (API reads this)
  STALE_SECONDS (default 7200)          drop statuses older than this
  LOCAL_FILE                            debug: parse this dyn JSON instead of polling
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

AVAILABLE = {"available"}
BUSY = {"charging", "occupied", "reserved", "blocked"}
OFFLINE = {"inoperative", "outofservice", "outoforder", "faulted", "unavailable"}


def cfg(n, d):
    return os.environ.get(n, d)


def sub_ids():
    raw = cfg("STATUS_SUBSCRIPTIONS", os.path.join(HERE, "status_subscriptions.txt"))
    lines = open(raw).read().splitlines() if os.path.isfile(raw) else raw.split(",")
    return [x for x in (l.split("#", 1)[0].strip() for l in lines) if x]


def fetch(sub_id, ctx):
    req = urllib.request.Request(f"{BASE}?subscriptionID={sub_id}",
                                 headers={"Accept-Encoding": "gzip"})
    with urllib.request.urlopen(req, context=ctx, timeout=120) as resp:
        if resp.status == 204:
            return None  # no change since last pull
        body = resp.read()
    if not body:
        return None
    if body[:2] == b"\x1f\x8b":
        body = gzip.decompress(body)
    return json.loads(body)


def apply_delta(doc, store, now):
    """Update the per-refill-point store from one dyn payload."""
    n = 0
    for payload in doc.get("messageContainer", {}).get("payload", []):
        pub = payload.get("aegiEnergyInfrastructureStatusPublication", {})
        for site_st in pub.get("energyInfrastructureSiteStatus", []):
            site = (site_st.get("reference") or {}).get("idG")
            if not site:
                continue
            for stn in site_st.get("energyInfrastructureStationStatus", []):
                for rp in stn.get("refillPointStatus", []):
                    cp = rp.get("aegiElectricChargingPointStatus") or {}
                    evse = (cp.get("reference") or {}).get("idG")
                    status = (cp.get("status") or {}).get("value")
                    if not evse or not status:
                        continue
                    store[evse] = {"st": status, "site": site, "ts": now}
                    n += 1
    return n


def aggregate(store, now, stale):
    """Collapse the per-point store into per-site availability."""
    sites = {}
    for entry in store.values():
        if now - entry["ts"] > stale:
            continue
        site = entry["site"]
        s = entry["st"].lower()
        d = sites.setdefault(site, {"a": 0, "b": 0, "o": 0})
        if s in AVAILABLE:
            d["a"] += 1
        elif s in BUSY:
            d["b"] += 1
        elif s in OFFLINE:
            d["o"] += 1
    out = {}
    for site, d in sites.items():
        if d["a"] > 0:
            state = "available"
        elif d["b"] > 0:
            state = "busy"
        elif d["o"] > 0:
            state = "offline"
        else:
            continue
        out[site] = {"a": d["a"], "k": d["a"] + d["b"] + d["o"], "s": state}
    return out


def main():
    store_file = cfg("STORE_FILE", os.path.join(HERE, "data", "charging_status_store.json"))
    status_file = cfg("STATUS_FILE", os.path.join(HERE, "data", "charging_status.json"))
    stale = int(cfg("STALE_SECONDS", "7200"))
    os.makedirs(os.path.dirname(store_file), exist_ok=True)
    now = time.time()

    store = {}
    if os.path.isfile(store_file):
        try:
            store = json.load(open(store_file))
        except Exception:
            store = {}

    changed = 0
    if os.environ.get("LOCAL_FILE"):
        changed += apply_delta(json.load(open(os.environ["LOCAL_FILE"])), store, now)
    else:
        ctx = ssl.create_default_context()
        ctx.load_cert_chain(cfg("MOBILITHEK_CERT", os.path.join(HERE, "mobilithek.crt")),
                            cfg("MOBILITHEK_KEY", os.path.join(HERE, "mobilithek.key")))
        for sub in sub_ids():
            try:
                doc = fetch(sub, ctx)
                if doc:
                    changed += apply_delta(doc, store, now)
            except Exception as e:
                print(f"  {sub}: FAILED {e}", file=sys.stderr)

    # drop long-stale points so the store can't grow forever
    store = {k: v for k, v in store.items() if now - v["ts"] <= stale}
    for f, data in ((store_file, store),
                    (status_file, {"generated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                                   "sites": aggregate(store, now, stale)})):
        tmp = f + ".tmp"
        json.dump(data, open(tmp, "w"), separators=(",", ":"))
        os.replace(tmp, f)
    agg = json.load(open(status_file))
    print(f"status: +{changed} updates, {len(store)} live points, "
          f"{len(agg['sites'])} sites with state", file=sys.stderr)


if __name__ == "__main__":
    main()
