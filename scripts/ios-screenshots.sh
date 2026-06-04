#!/usr/bin/env bash
#
# Boots an iPhone simulator and drives the Flutter app to capture store
# screenshots into $SHOT_OUT. Run from the app/ directory:
#
#   SHOT_OUT=/abs/path WW_SHARE=<base64> bash ../scripts/ios-screenshots.sh
#
# `flutter drive -d <name>` only sees *booted* simulators, so we resolve a
# concrete device UDID (creating one if the runner has none), boot it, then
# target it by UDID.
set -uo pipefail

SIM_NAME="${IOS_SIM:-iPhone 16 Pro Max}"
OUT="${SHOT_OUT:-$(pwd)/build/screenshots/ios}"
mkdir -p "$OUT"

udid_by_name() {
  xcrun simctl list devices available | grep -F "$1" | grep -oE '[0-9A-F-]{36}' | head -1
}

UDID="$(udid_by_name "$SIM_NAME")"
if [ -z "$UDID" ]; then
  echo "ios-screenshots: '$SIM_NAME' not found — trying any available iPhone"
  UDID="$(xcrun simctl list devices available | grep -E 'iPhone' | grep -oE '[0-9A-F-]{36}' | head -1)"
fi
if [ -z "$UDID" ]; then
  echo "ios-screenshots: no iPhone simulator exists — creating one"
  RUNTIME="$(xcrun simctl list runtimes ios | grep -oE 'com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]+' | tail -1)"
  DEVTYPE="$(xcrun simctl list devicetypes | grep -F "$SIM_NAME" | grep -oE 'com.apple.CoreSimulator.SimDeviceType.[^)]+' | head -1)"
  [ -z "$DEVTYPE" ] && DEVTYPE="$(xcrun simctl list devicetypes | grep -E 'iPhone' | grep -oE 'com.apple.CoreSimulator.SimDeviceType.[^)]+' | tail -1)"
  if [ -n "$RUNTIME" ] && [ -n "$DEVTYPE" ]; then
    UDID="$(xcrun simctl create ww-shots "$DEVTYPE" "$RUNTIME" 2>/dev/null)"
  fi
fi
if [ -z "$UDID" ]; then
  echo "ios-screenshots: could not obtain a simulator" >&2
  exit 1
fi

echo "ios-screenshots: using simulator $UDID"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b || true

# --no-enable-impeller: integration_test's takeScreenshot (via
# convertFlutterSurfaceToImage) returns all-black images under Impeller on the
# iOS simulator; the Skia backend reads back correctly.
SHOT_OUT="$OUT" flutter drive \
  --driver=test_driver/screenshot_driver.dart \
  --target=integration_test/screenshots_test.dart \
  -d "$UDID" \
  --no-enable-impeller \
  --dart-define=WW_SHARE="${WW_SHARE:-}"
