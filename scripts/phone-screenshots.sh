#!/usr/bin/env bash
#
# Generates Android + iPhone phone store screenshots locally from the deployed
# web build (wegwiesel.app) via headless Chromium — no Mac, simulator or GPU
# needed. Runs on any machine with Node installed.
#
#   bash scripts/phone-screenshots.sh
#
# Output (override with ANDROID_OUT / IOS_OUT):
#   store_assets/android/screenshots   1080×1920
#   store_assets/ios/screenshots       1290×2796  (iPhone 6.9")
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
cd "$here/screenshot-runner"

# Install Playwright + its bundled Chromium on first run.
npm ci >/dev/null 2>&1 || npm install
npx playwright install chromium >/dev/null 2>&1 || true

echo "== Android (1080×1920) =="
SHOT_OUT="${ANDROID_OUT:-$root/store_assets/android/screenshots}" node run.mjs

echo "== iPhone 6.9\" (1290×2796) =="
SHOT_OUT="${IOS_OUT:-$root/store_assets/ios/screenshots}" SHOT_W=1290 SHOT_H=2796 node run.mjs

echo "done"
