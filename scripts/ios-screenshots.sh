#!/usr/bin/env bash
#
# Captures iPhone store screenshots by running the real app on an iOS simulator
# and grabbing the screen with `xcrun simctl io screenshot` — the same approach
# that works for the watch. We deliberately do NOT use integration_test's
# takeScreenshot: its convertFlutterSurfaceToImage readback returns all-black
# images on the iOS simulator (with or without Impeller).
#
# Run from the app/ directory:
#   SHOT_OUT=/abs/path bash ../scripts/ios-screenshots.sh
#
# Each shot is the same screen (map + stats) with a different seeded route,
# passed per launch via the WW_SHARE process env (read at runtime by
# share_url_stub.dart), so we build once and just relaunch.
set -uo pipefail

SIM_NAME="${IOS_SIM:-iPhone 16 Pro Max}"
OUT="${SHOT_OUT:-$(pwd)/build/screenshots/ios}"
mkdir -p "$OUT"

udid_by_name() {
  xcrun simctl list devices available | grep -F "$1" | grep -oE '[0-9A-F-]{36}' | head -1
}

# Prefer a "Pro Max" device so screenshots come out at the App Store 6.9" size.
# Order: the configured device by name → any existing Pro Max → create a Pro Max
# → (last resort) any existing iPhone.
UDID="$(udid_by_name "$SIM_NAME")"
if [ -z "$UDID" ]; then
  echo "ios-screenshots: '$SIM_NAME' not found — looking for any Pro Max"
  UDID="$(xcrun simctl list devices available | grep -E 'iPhone.*Pro Max' | grep -oE '[0-9A-F-]{36}' | head -1)"
fi
if [ -z "$UDID" ]; then
  echo "ios-screenshots: no Pro Max present — creating one"
  RUNTIME="$(xcrun simctl list runtimes ios | grep -oE 'com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]+' | tail -1)"
  DEVTYPE="$(xcrun simctl list devicetypes | grep -F "$SIM_NAME" | grep -oE 'com.apple.CoreSimulator.SimDeviceType.[^)]+' | head -1)"
  [ -z "$DEVTYPE" ] && DEVTYPE="$(xcrun simctl list devicetypes | grep -E 'iPhone.*Pro.?Max' | grep -oE 'com.apple.CoreSimulator.SimDeviceType.[^)]+' | tail -1)"
  if [ -n "$RUNTIME" ] && [ -n "$DEVTYPE" ]; then
    UDID="$(xcrun simctl create ww-shots "$DEVTYPE" "$RUNTIME" 2>/dev/null)"
  fi
fi
if [ -z "$UDID" ]; then
  echo "ios-screenshots: falling back to any available iPhone"
  UDID="$(xcrun simctl list devices available | grep -E 'iPhone' | grep -oE '[0-9A-F-]{36}' | head -1)"
fi
if [ -z "$UDID" ]; then
  echo "ios-screenshots: could not obtain a simulator" >&2
  exit 1
fi

echo "ios-screenshots: using simulator $UDID"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b || true

echo "ios-screenshots: building app for the simulator …"
# -d is required because the app embeds a watchOS companion: flutter needs a
# concrete simulator to build the paired watch app against.
flutter build ios --simulator --debug -d "$UDID" | tail -20

APP="$(find build/ios/iphonesimulator -maxdepth 1 -name '*.app' -type d 2>/dev/null | head -1)"
if [ -z "${APP:-}" ]; then
  echo "ios-screenshots: simulator build produced no .app" >&2
  exit 1
fi

BUNDLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist" 2>/dev/null)"
[ -z "$BUNDLE" ] && BUNDLE="com.thomaspeterson.bikerouter"
echo "ios-screenshots: bundle id $BUNDLE"
xcrun simctl install "$UDID" "$APP"

# name <tab> WW_SHARE payload <tab> seconds to wait for tiles + route calc.
# The roundtrip needs longer because the route is computed on-device.
SHOTS=(
  "01-trekking	eyJ3IjpbWzQ4LjEzNywxMS41NzVdLFs0OC4xNjUsMTEuNTJdXSwicCI6InRyZWtraW5nIn0	16"
  "02-gravel	eyJ3IjpbWzQ3Ljg2LDExLjE4XSxbNDcuODMsMTEuMjVdXSwicCI6InF1YWVsbml4LWdyYXZlbCJ9	16"
  "03-roundtrip	eyJ3IjpbWzQ4LjEzNywxMS41NzVdXSwicCI6ImZhc3RiaWtlIiwicnQiOjEsImQiOjIwLCJkaXIiOjkwfQ	26"
  "04-mtb	eyJ3IjpbWzQ3LjQ4LDExLjA5XSxbNDcuNDYsMTEuMTFdXSwicCI6Im10Yi16b3NzZWJhcnQifQ	16"
)

saved=0
for entry in "${SHOTS[@]}"; do
  IFS=$'\t' read -r name share wait <<<"$entry"
  echo "→ $name"
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  if ! SIMCTL_CHILD_WW_SHARE="$share" xcrun simctl launch "$UDID" "$BUNDLE"; then
    echo "  launch failed for $name" >&2
    continue
  fi
  sleep "$wait"
  if xcrun simctl io "$UDID" screenshot "$OUT/$name.png" >/dev/null 2>&1; then
    echo "  saved $name.png"
    saved=$((saved + 1))
  else
    echo "  screenshot failed for $name" >&2
  fi
done

echo "ios-screenshots: $saved/${#SHOTS[@]} screenshots → $OUT"
[ "$saved" -gt 0 ] || exit 1
