#!/usr/bin/env bash
# Builds WegwieselSync for the Garmin Edge.
#   ./build.sh             -> .prg for sideload (default DEVICE=edge830)
#   ./build.sh store       -> .iq package for Connect IQ Store submission
#   ./build.sh sideload    -> same as default
# Sideload: plug the Edge in via USB, then copy the .prg into /GARMIN/APPS/.
set -e

SDK_ROOT="${SDK_ROOT:-$HOME/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.1.0-2026-03-09-6a872a80b}"
DEV_KEY="${DEV_KEY:-$HOME/.Garmin/ConnectIQ/developer_key.der}"
DEVICE="${DEVICE:-edge830}"
MODE="${1:-sideload}"

cd "$(dirname "$0")"

if [ ! -d "$SDK_ROOT" ]; then
    echo "Connect IQ SDK not found at $SDK_ROOT" >&2
    exit 1
fi
if [ ! -f "$DEV_KEY" ]; then
    echo "Developer key not found at $DEV_KEY" >&2
    exit 1
fi

case "$MODE" in
    store|iq|package)
        OUT="${OUT:-WegwieselSync.iq}"
        "$SDK_ROOT/bin/monkeyc" \
            -e \
            -f monkey.jungle \
            -o "$OUT" \
            -y "$DEV_KEY" \
            -r \
            --warn
        echo "Built $OUT ($(stat -c%s "$OUT") bytes)"
        echo "Upload at https://apps.garmin.com/developer/manage to submit to the Connect IQ Store."
        ;;
    sideload|prg|*)
        OUT="${OUT:-WegwieselSync.prg}"
        "$SDK_ROOT/bin/monkeyc" \
            -d "$DEVICE" \
            -f monkey.jungle \
            -o "$OUT" \
            -y "$DEV_KEY" \
            --warn
        echo "Built $OUT for $DEVICE ($(stat -c%s "$OUT") bytes)"
        echo "To install: copy $OUT to /GARMIN/APPS/ on the Edge over USB."
        ;;
esac
