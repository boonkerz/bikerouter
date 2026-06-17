#!/usr/bin/env bash
# Composites the recorded scene clips (raw/*.webm) into the Play Store promo
# video: title card → 4 phone-in-frame scenes with captions → end card.
# Pure ffmpeg + ImageMagick, no filming. Output: out/promo.mp4 (1920x1080, h264).
set -eu
cd "$(dirname "$0")"
RAW=raw; WORK=work; OUT=out
mkdir -p "$WORK" "$OUT"

FB=/usr/share/fonts/noto/NotoSans-Bold.ttf
FR=/usr/share/fonts/noto/NotoSans-Regular.ttf
ICON=../../store_assets/android/icon-512.png
W=1920; H=1080
# phone screen placement (portrait clip scaled to 920px tall)
PW=518; PH=920; PX=150; PY=80

# brand gradient background (Wegwiesel green)
magick -size ${W}x${H} gradient:'#2f6e4d'-'#10291a' "$WORK/bg.png"
magick "$ICON" -resize 220x220 "$WORK/icon220.png"
magick "$ICON" -resize 110x110 "$WORK/icon110.png"

# ---- title card ----
magick "$WORK/bg.png" \
  "$WORK/icon220.png" -gravity North -geometry +0+250 -composite \
  -font "$FB" -pointsize 132 -fill white -gravity North -annotate +0+520 "Wegwiesel" \
  -font "$FR" -pointsize 52 -fill '#cfe6da' -gravity North -annotate +0+700 "Fahrrad-Navigation, die mitdenkt." \
  "$WORK/title.png"

# ---- end card ----
magick "$WORK/bg.png" \
  "$WORK/icon220.png" -gravity North -geometry +0+250 -composite \
  -font "$FB" -pointsize 88 -fill white -gravity North -annotate +0+540 "Plane. Fahre. Ankommen." \
  -font "$FR" -pointsize 46 -fill '#cfe6da' -gravity North -annotate +0+680 "Jetzt bei Google Play" \
  "$WORK/end.png"

# ---- per-scene background cards (frame + caption), video overlaid later ----
titles=("Tourenrad" "Gravel" "Mountainbike" "Rennrad")
sub1=("Komfortabel ans Ziel," "Abseits der Straße," "Rauf in die Berge," "Schnelle Routen,")
sub2=("auf ruhigen Wegen." "mitten in die Natur." "jeden Trail im Blick." "immer die beste Linie.")
names=("1-trekking" "2-gravel" "3-mtb" "4-road")

TX=770  # right text column
for i in 0 1 2 3; do
  magick "$WORK/bg.png" \
    -fill '#ffffff' -draw "roundrectangle $((PX-18)),$((PY-18)) $((PX+PW+18)),$((PY+PH+18)) 40,40" \
    "$WORK/icon110.png" -gravity NorthEast -geometry +70+70 -composite \
    -font "$FB" -pointsize 104 -fill white   -gravity NorthWest -annotate +${TX}+250 "${titles[$i]}" \
    -font "$FR" -pointsize 54  -fill '#dcefe5' -gravity NorthWest -annotate +${TX}+400 "${sub1[$i]}" \
    -font "$FR" -pointsize 54  -fill '#dcefe5' -gravity NorthWest -annotate +${TX}+470 "${sub2[$i]}" \
    -font "$FR" -pointsize 34  -fill '#9fc3b1' -gravity SouthEast -annotate +70+70 "wegwiesel.app" \
    "$WORK/scene-bg-$i.png"
done

if [ "${CARDS_ONLY:-0}" = "1" ]; then echo "cards rendered to $WORK"; exit 0; fi

# ---- encode each segment to a normalised 1920x1080/30fps h264 mp4 ----
enc() { # $1 png  $2 dur  $3 fadeout-start  $4 out
  ffmpeg -y -loglevel error -loop 1 -t "$2" -i "$1" \
    -vf "fade=t=in:st=0:d=0.5,fade=t=out:st=$3:d=0.5,format=yuv420p" \
    -r 30 -c:v libx264 -pix_fmt yuv420p -preset medium "$4"
}
enc "$WORK/title.png" 2.8 2.3 "$WORK/00-title.mp4"
enc "$WORK/end.png"   3.2 2.7 "$WORK/99-end.mp4"

SDUR=5.0
for i in 0 1 2 3; do
  ffmpeg -y -loglevel error -loop 1 -t "$SDUR" -i "$WORK/scene-bg-$i.png" \
    -ss 1.5 -t "$SDUR" -i "$RAW/${names[$i]}.webm" \
    -filter_complex \
      "[1:v]scale=${PW}:${PH}:force_original_aspect_ratio=increase,crop=${PW}:${PH},setpts=PTS-STARTPTS[v]; \
       [0:v][v]overlay=${PX}:${PY}:shortest=1[c]; \
       [c]fade=t=in:st=0:d=0.4,fade=t=out:st=4.5:d=0.4,format=yuv420p[o]" \
    -map "[o]" -r 30 -t "$SDUR" -c:v libx264 -pix_fmt yuv420p -preset medium "$WORK/scene-$i.mp4"
done

# ---- concat ----
: > "$WORK/list.txt"
for f in 00-title scene-0 scene-1 scene-2 scene-3 99-end; do
  echo "file '$f.mp4'" >> "$WORK/list.txt"
done
ffmpeg -y -loglevel error -f concat -safe 0 -i "$WORK/list.txt" \
  -f lavfi -i anullsrc=r=44100:cl=stereo -shortest \
  -c:v copy -c:a aac -b:a 96k "$OUT/promo.mp4"

echo "=== done ==="
ffprobe -v error -show_entries format=duration,size:stream=width,height,codec_name "$OUT/promo.mp4"
