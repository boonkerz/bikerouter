#!/bin/bash
# Download BRouter segment files for DACH region (Germany, Austria, Switzerland)
# Segments are 5x5 degree tiles

SEGMENTS_DIR="$(dirname "$0")/../segments4"
BASE_URL="https://brouter.de/brouter/segments4"

mkdir -p "$SEGMENTS_DIR"

# DACH region tiles:
# E5_N45.rd5  - Switzerland south, northern Italy
# E5_N50.rd5  - Western Germany, Benelux, eastern France
# E10_N45.rd5 - Austria, northern Italy, Slovenia
# E10_N50.rd5 - Central/Eastern Germany, Czech Republic, western Poland
# E15_N45.rd5 - Eastern Austria, Hungary, Croatia
# E15_N50.rd5 - Eastern Germany, Poland, Czech Republic

TILES=(
  "E5_N45"
  "E5_N50"
  "E10_N45"
  "E10_N50"
  "E15_N45"
  "E15_N50"
)

echo "Downloading BRouter segments for DACH region..."
echo "Target directory: $SEGMENTS_DIR"
echo ""

for tile in "${TILES[@]}"; do
  file="${tile}.rd5"
  url="${BASE_URL}/${file}"
  target="${SEGMENTS_DIR}/${file}"

  if [ -f "$target" ]; then
    echo "  [skip] $file already exists"
    continue
  fi

  echo "  [download] $file ..."
  curl -L --progress-bar -o "$target" "$url"

  if [ $? -eq 0 ] && [ -f "$target" ]; then
    size=$(du -h "$target" | cut -f1)
    echo "  [done] $file ($size)"
  else
    echo "  [error] Failed to download $file"
    rm -f "$target"
  fi
done

echo ""
echo "Segment download complete."
ls -lh "$SEGMENTS_DIR"/*.rd5 2>/dev/null
