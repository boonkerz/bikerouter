#!/usr/bin/env bash
#
# Renders Apple Watch store screenshots on a watchOS simulator and writes PNGs
# to $SHOT_OUT. Run from app/ios (the CI step sets that working directory):
#
#   SHOT_OUT=/abs/path bash ../../scripts/watch-screenshots.sh
#
# How it works: the watch app has a screenshot mode (ScreenshotSupport.swift)
# that shows exactly one seeded screen as its root when launched with
# WW_WATCH_SHOTS=1 and WW_WATCH_SHOT=<screen>. We build that target for a watch
# simulator, install it, then launch it once per screen and grab a real
# `simctl io screenshot` — which captures List/Map content correctly, unlike
# SwiftUI ImageRenderer.
#
# Best-effort by design (the CI step is continue-on-error): if a watch
# simulator or the build is unavailable, we exit non-zero without taking down
# the rest of the screenshot job.
set -uo pipefail

OUT="${SHOT_OUT:-$(pwd)/../build/screenshots/watch}"
mkdir -p "$OUT"

BUNDLE="com.thomaspeterson.bikerouter.WegwieselWatch"
SCHEME="WegwieselWatch Watch App"
DERIVED="$(pwd)/build/watch-shots"

# Resolve a watch simulator UDID — prefer $WATCH_SIM (by name), else the first
# available "Apple Watch" device the runner has.
if [ -n "${WATCH_SIM:-}" ]; then
  UDID="$(xcrun simctl list devices available | grep -F "$WATCH_SIM" | grep -oE '[0-9A-F-]{36}' | head -1)"
else
  UDID="$(xcrun simctl list devices available | grep -i 'Apple Watch' | grep -oE '[0-9A-F-]{36}' | head -1)"
fi

if [ -z "${UDID:-}" ]; then
  echo "watch-screenshots: no watch simulator exists — creating one"
  RUNTIME="$(xcrun simctl list runtimes watchos | grep -oE 'com.apple.CoreSimulator.SimRuntime.watchOS-[0-9-]+' | tail -1)"
  DEVTYPE="$(xcrun simctl list devicetypes | grep -i 'Apple Watch' | grep -oE 'com.apple.CoreSimulator.SimDeviceType.[^)]+' | tail -1)"
  if [ -n "$RUNTIME" ] && [ -n "$DEVTYPE" ]; then
    UDID="$(xcrun simctl create ww-watch-shots "$DEVTYPE" "$RUNTIME" 2>/dev/null)"
  fi
fi

if [ -z "${UDID:-}" ]; then
  echo "watch-screenshots: no watchOS simulator available — skipping" >&2
  exit 1
fi
echo "watch-screenshots: using simulator $UDID"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b || true

echo "watch-screenshots: building '$SCHEME' …"
xcodebuild build \
  -project Runner.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=watchOS Simulator,id=$UDID" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
  | tail -30

APP="$(find "$DERIVED/Build/Products" -maxdepth 2 -name '*.app' -type d 2>/dev/null | head -1)"
if [ -z "${APP:-}" ]; then
  echo "watch-screenshots: build produced no .app — skipping" >&2
  exit 1
fi

xcrun simctl install "$UDID" "$APP"

shoot() {
  local screen="$1" name="$2"
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  SIMCTL_CHILD_WW_WATCH_SHOTS=1 SIMCTL_CHILD_WW_WATCH_SHOT="$screen" \
    xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  sleep 6
  if xcrun simctl io "$UDID" screenshot "$OUT/$name.png" >/dev/null 2>&1; then
    echo "  saved $name.png"
  else
    echo "  failed $name.png" >&2
  fi
}

shoot routes 01-routes
shoot glance 02-glance
shoot navigation 03-navigation

echo "watch-screenshots: done → $OUT"
