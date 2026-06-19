#!/bin/sh
# One container, three jobs:
#  - static prices: initial + daily fetch (needs the mTLS cert)
#  - live status:   frequent dyn poll (delta feeds, ~every STATUS_INTERVAL s)
#  - bbox API:      foreground
# Fetch failures are non-fatal — the API keeps serving the last good data.
set -e

python fetch_prices.py || echo "initial price fetch failed" >&2

(
  while true; do
    sleep "$(( ${FETCH_INTERVAL_HOURS:-24} * 3600 ))"
    python fetch_prices.py || echo "scheduled price fetch failed" >&2
  done
) &

# Live status: only if dyn subscriptions are configured.
if [ -s "${STATUS_SUBSCRIPTIONS:-/config/status_subscriptions.txt}" ]; then
  (
    while true; do
      python fetch_status.py || echo "status poll failed" >&2
      sleep "${STATUS_INTERVAL:-150}"
    done
  ) &
fi

exec python serve_prices.py
