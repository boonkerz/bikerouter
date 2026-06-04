#!/usr/bin/env bash
#
# Renders Wear OS store screenshots from the :wear module's @Preview
# composables (Compose Preview Screenshot Testing — no emulator needed) and
# copies the generated reference PNGs to $SHOT_OUT. Run from app/android:
#
#   bash ../../scripts/wear-screenshots.sh
#
# `updateDebugScreenshotTest` writes reference images under
# wear/src/debug/screenshotTest/reference/...; we flatten those into $SHOT_OUT.
# Best-effort: the CI step is continue-on-error, so a plugin/AGP mismatch only
# loses the wear shots, not the rest of the job.
set -uo pipefail

OUT="${SHOT_OUT:-$(pwd)/../build/screenshots/wear}"
mkdir -p "$OUT"

echo "wear-screenshots: rendering @Preview composables …"
./gradlew :wear:updateDebugScreenshotTest --no-daemon || {
  echo "wear-screenshots: gradle task failed — skipping" >&2
  exit 1
}

REF_DIR="wear/src/debug/screenshotTest/reference"
count=0
if [ -d "$REF_DIR" ]; then
  while IFS= read -r -d '' png; do
    cp "$png" "$OUT/$(basename "$png")"
    count=$((count + 1))
  done < <(find "$REF_DIR" -name '*.png' -print0)
fi

echo "wear-screenshots: copied $count screenshot(s) → $OUT"
[ "$count" -gt 0 ] || exit 1
