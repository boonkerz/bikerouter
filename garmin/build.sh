#!/usr/bin/env bash
# Builds WegwieselSync.prg for Edge 830.
# Sideload: plug the Edge in via USB, then copy the .prg into /GARMIN/APPS/.
set -e

SDK_ROOT="${SDK_ROOT:-$HOME/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.1.0-2026-03-09-6a872a80b}"
DEV_KEY="${DEV_KEY:-$HOME/.Garmin/ConnectIQ/developer_key.der}"
DEVICE="${DEVICE:-edge830}"
OUT="${OUT:-WegwieselSync.prg}"

cd "$(dirname "$0")"

if [ ! -d "$SDK_ROOT" ]; then
    echo "Connect IQ SDK not found at $SDK_ROOT" >&2
    exit 1
fi
if [ ! -f "$DEV_KEY" ]; then
    echo "Developer key not found at $DEV_KEY" >&2
    exit 1
fi

"$SDK_ROOT/bin/monkeyc" \
    -d "$DEVICE" \
    -f monkey.jungle \
    -o "$OUT" \
    -y "$DEV_KEY" \
    --warn

echo "Built $OUT ($(stat -c%s "$OUT") bytes)"
echo "To install: copy $OUT to /GARMIN/APPS/ on the Edge over USB."
