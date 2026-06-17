import { chromium } from 'playwright';
import { mkdir, rename, readdir, rm } from 'node:fs/promises';
import { join } from 'node:path';

// Records ONE scene of the live web build (wegwiesel.app) and exits. Run one
// scene per process so a stalled headless renderer can be killed by an OS
// timeout (see run.sh) without taking the other scenes down with it. build.mjs
// then stitches the per-scene webm clips into the Play Store promo video.
//
//   argv[2]   — scene index (0-based)
//   VID_OUT   — where raw webm clips land (default ./raw)
//   VID_BASE  — site to record (default production)
const rawDir = process.env.VID_OUT || new URL('./raw', import.meta.url).pathname;
const baseUrl = process.env.VID_BASE || 'https://wegwiesel.app';
const viewport = { width: 1080, height: 1920 };

function encode(obj) {
  return Buffer.from(JSON.stringify(obj)).toString('base64url').replace(/=+$/, '');
}

// Reliable point-to-point routes across profiles for visual variety. We avoid
// the heavy roundtrip engine (rt:1) on purpose — its long compute intermittently
// wedged the headless renderer mid-recording.
const scenes = [
  { name: '1-trekking', w: [[48.137, 11.575], [48.165, 11.520]], p: 'trekking' },
  { name: '2-gravel',   w: [[47.860, 11.180], [47.815, 11.255]], p: 'quaelnix-gravel' },
  { name: '3-mtb',      w: [[47.480, 11.090], [47.455, 11.120]], p: 'mtb-zossebart' },
  { name: '4-road',     w: [[47.800, 12.060], [47.760, 12.140]], p: 'fastbike' },
];

const idx = Number(process.argv[2] || 0);
const s = scenes[idx];
if (!s) { console.error(`no scene ${idx}`); process.exit(2); }
const url = `${baseUrl}/?r=${encode({ w: s.w, p: s.p })}`;

await mkdir(rawDir, { recursive: true });

const cx = viewport.width / 2;
const cy = viewport.height / 2;

async function gentleZoom(page) {
  // a slow zoom-in over map center so the clip breathes; no drag (a pan during
  // a busy renderer was what wedged the roundtrip scene).
  await page.mouse.move(cx, cy);
  for (let i = 0; i < 5; i++) {
    await page.mouse.wheel(0, -110);
    await page.waitForTimeout(450);
  }
  await page.waitForTimeout(1200);
}

const browser = await chromium.launch({ headless: true });
const ctx = await browser.newContext({ viewport, recordVideo: { dir: rawDir, size: viewport } });
const page = await ctx.newPage();
page.setDefaultTimeout(60000);
try {
  try {
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  } catch (e) {
    console.log(`  goto warn: ${e.message.split('\n')[0]}`);
  }
  await page.waitForTimeout(8000); // tiles load + route compute/draw
  await gentleZoom(page);
} finally {
  await page.close().catch(() => {});
  await ctx.close().catch(() => {}); // finalizes the webm
}

// Playwright names videos by an internal id; rename to the scene name.
const files = (await readdir(rawDir)).filter((f) => f.startsWith('page@') || /^[0-9a-f]{32}\.webm$/.test(f));
if (files.length) {
  await rm(join(rawDir, `${s.name}.webm`), { force: true });
  await rename(join(rawDir, files[0]), join(rawDir, `${s.name}.webm`));
  console.log(`saved ${s.name}.webm`);
} else {
  console.error('no webm produced');
  process.exit(1);
}
await browser.close();
