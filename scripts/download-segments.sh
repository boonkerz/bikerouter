#!/bin/bash
# Download BRouter segment files
# Segments are 5x5 degree tiles covering the whole world
# Usage: ./download-segments.sh [world|dach]

SEGMENTS_DIR="$(dirname "$0")/../segments4"
BASE_URL="https://brouter.de/brouter/segments4"
MODE="${1:-world}"

mkdir -p "$SEGMENTS_DIR"

if [ "$MODE" = "dach" ]; then
  echo "Downloading BRouter segments for DACH region..."
  TILES=(E5_N45 E5_N50 E10_N45 E10_N50 E15_N45 E15_N50)
else
  echo "Downloading BRouter segments for the whole world..."
  TILES=()
  for lon in $(seq -180 5 175); do
    for lat in $(seq -90 5 85); do
      if [ $lon -ge 0 ]; then
        lon_prefix="E${lon}"
      else
        lon_prefix="W$(( -lon ))"
      fi
      if [ $lat -ge 0 ]; then
        lat_prefix="N${lat}"
      else
        lat_prefix="S$(( -lat ))"
      fi
      TILES+=("${lon_prefix}_${lat_prefix}")
    done
  done
fi

echo "Target directory: $SEGMENTS_DIR"
echo "Tiles to check: ${#TILES[@]}"
echo ""

downloaded=0
skipped=0
failed=0

for tile in "${TILES[@]}"; do
  file="${tile}.rd5"
  url="${BASE_URL}/${file}"
  target="${SEGMENTS_DIR}/${file}"

  if [ -f "$target" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  # Check if file exists on server (some ocean tiles don't exist)
  status=$(curl -s -o /dev/null -w "%{http_code}" -L --head "$url")
  if [ "$status" != "200" ]; then
    continue
  fi

  echo "  [download] $file ..."
  curl -L --progress-bar -o "$target" "$url"

  if [ $? -eq 0 ] && [ -f "$target" ]; then
    size=$(du -h "$target" | cut -f1)
    echo "  [done] $file ($size)"
    downloaded=$((downloaded + 1))
  else
    echo "  [error] Failed to download $file"
    rm -f "$target"
    failed=$((failed + 1))
  fi
done

echo ""
echo "Download complete. New: $downloaded, Skipped: $skipped, Failed: $failed"
total=$(ls "$SEGMENTS_DIR"/*.rd5 2>/dev/null | wc -l)
totalsize=$(du -sh "$SEGMENTS_DIR" 2>/dev/null | cut -f1)
echo "Total segments: $total ($totalsize)"
