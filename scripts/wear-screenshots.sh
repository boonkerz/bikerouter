#!/usr/bin/env bash
#
# Renders Wear OS store screenshots from the :wear module via Paparazzi
# (layoutlib on the JVM — no emulator needed) and copies the generated PNGs to
# $SHOT_OUT. Run from app/android:
#
#   bash ../../scripts/wear-screenshots.sh
#
# `recordPaparazziDebug` writes images to wear/src/test/snapshots/images/;
# we flatten those into $SHOT_OUT. Best-effort: the CI step is
# continue-on-error, so a hiccup here only loses the wear shots.
set -uo pipefail

OUT="${SHOT_OUT:-$(pwd)/../build/screenshots/wear}"
mkdir -p "$OUT"

echo "wear-screenshots: rendering Compose previews via Paparazzi …"
./gradlew :wear:recordPaparazziDebug --no-daemon || {
  echo "wear-screenshots: gradle task failed — skipping" >&2
  exit 1
}

count=0
while IFS= read -r -d '' png; do
  cp "$png" "$OUT/$(basename "$png")"
  count=$((count + 1))
done < <(find wear/src/test/snapshots/images -name '*.png' -print0 2>/dev/null)

echo "wear-screenshots: copied $count screenshot(s) → $OUT"
[ "$count" -gt 0 ] || exit 1
