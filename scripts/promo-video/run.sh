#!/usr/bin/env bash
# Record every promo scene, one OS-timeout-guarded process each, so a wedged
# headless renderer can't deadlock the whole run.
set -u
cd "$(dirname "$0")"
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/home/thomas/.cache/ms-playwright}"
ln -sf ../screenshot-runner/node_modules node_modules 2>/dev/null || true

N="${1:-4}"   # number of scenes
for i in $(seq 0 $((N-1))); do
  echo "=== scene $i ==="
  timeout --kill-after=10 90 node record.mjs "$i" || echo "  scene $i timed out / failed"
done
echo "=== raw clips ==="
ls -la raw/*.webm 2>/dev/null
