# Google Play Store Assets

## App Icon (high-res)
`icon-512.png` — 512×512 PNG. Upload as **App icon** in Play Console → Store presence → Main store listing.

## Feature Graphic
`feature-graphic-1024x500.png` — 1024×500 PNG. Upload as **Feature graphic** in the same listing form.

## Phone Screenshots
`screenshots/*.png` — 1080×1920 portrait (16:9). Minimum two are required; up to eight allowed.

Captured headlessly from the deployed web build at https://wegwiesel.app via `scripts/screenshot-runner/run.mjs`. Re-run with:
```
cd scripts/screenshot-runner
PLAYWRIGHT_BROWSERS_PATH=/home/thomas/.cache/ms-playwright node run.mjs
```

## Description / Listing Copy
- `../description_de.md` — German app store description (Apple-flavoured, applicable to Play with minor edits).
- `../whats_new.md` — historical release notes; current 1.4.1 notes are in the chat history.

## Reproducing the icon at higher resolutions
The 1024×1024 source lives at `app/assets/icon/icon.png`. Resize via:
```
magick app/assets/icon/icon.png -resize 512x512 store_assets/android/icon-512.png
```
