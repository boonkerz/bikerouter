#!/usr/bin/env python3
"""Tiny bbox API for AFIR ad-hoc charging prices.

Serves only the points inside a requested bounding box, so the (growing) full
dataset is never handed out in one piece — keeps it "use in our app" rather than
re-publishing the raw dataset, and keeps responses small.

  GET /api/charging-prices?bbox=<west>,<south>,<east>,<north>
      bbox order = lon,lat,lon,lat (GeoJSON order). Returns JSON:
      { generated, attribution, count, points:[ {op,name,lat,lon,kwh,min,cur,kw,upd}, ... ] }

Binds to 127.0.0.1; put Caddy in front (reverse_proxy /api/charging-prices*).
No third-party deps.

Env: DATA_FILE (default ./data/charging_prices.json), HOST, PORT,
     MAX_SPAN_DEG (reject bboxes larger than this per axis, default 3.0),
     MAX_POINTS (cap returned points, default 1000).
"""
import json
import os
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

HERE = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.environ.get("DATA_FILE", os.path.join(HERE, "data", "charging_prices.json"))
MAX_SPAN = float(os.environ.get("MAX_SPAN_DEG", "3.0"))
MAX_POINTS = int(os.environ.get("MAX_POINTS", "1000"))

_lock = threading.Lock()
_cache = {"mtime": 0, "data": {"points": [], "generated": None, "attribution": None}}


def load_data():
    """Reload the dataset when the file changes (the cron fetcher rewrites it)."""
    try:
        mtime = os.path.getmtime(DATA_FILE)
    except OSError:
        return _cache["data"]
    with _lock:
        if mtime != _cache["mtime"]:
            with open(DATA_FILE) as f:
                _cache["data"] = json.load(f)
            _cache["mtime"] = mtime
        return _cache["data"]


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _send(self, code, obj):
        body = json.dumps(obj, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "public, max-age=3600")
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def do_GET(self):
        u = urlparse(self.path)
        if u.path.rstrip("/") != "/api/charging-prices":
            return self._send(404, {"error": "not found"})
        q = parse_qs(u.query)
        bbox = (q.get("bbox") or [""])[0]
        try:
            w, s, e, n = (float(x) for x in bbox.split(","))
        except ValueError:
            return self._send(400, {"error": "bbox required as west,south,east,north (lon,lat,lon,lat)"})
        if e < w or n < s:
            return self._send(400, {"error": "bbox min/max swapped"})
        if (e - w) > MAX_SPAN or (n - s) > MAX_SPAN:
            return self._send(400, {"error": f"bbox too large (max {MAX_SPAN} deg per axis)"})

        data = load_data()
        out = []
        for p in data.get("points", []):
            if w <= p["lon"] <= e and s <= p["lat"] <= n:
                out.append(p)
                if len(out) >= MAX_POINTS:
                    break
        self._send(200, {
            "generated": data.get("generated"),
            "attribution": data.get("attribution"),
            "count": len(out),
            "points": out,
        })

    do_HEAD = do_GET

    def log_message(self, *a):  # quiet
        pass


def main():
    host = os.environ.get("HOST", "127.0.0.1")
    port = int(os.environ.get("PORT", "8088"))
    load_data()
    srv = ThreadingHTTPServer((host, port), Handler)
    print(f"charging-prices API on http://{host}:{port}/api/charging-prices  ({_cache['data'].get('count', 0)} points loaded)")
    srv.serve_forever()


if __name__ == "__main__":
    main()
