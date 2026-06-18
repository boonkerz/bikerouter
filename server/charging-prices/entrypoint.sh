#!/bin/sh
# One container does both jobs: an initial + daily fetch (needs the mounted mTLS
# cert) in the background, and the bbox API in the foreground. Fetch failures are
# non-fatal — the API keeps serving the last good data.
set -e

python fetch_prices.py || echo "initial fetch failed (cert/subscriptions present?)" >&2

(
  while true; do
    sleep "$(( ${FETCH_INTERVAL_HOURS:-24} * 3600 ))"
    python fetch_prices.py || echo "scheduled fetch failed" >&2
  done
) &

exec python serve_prices.py
