import { chromium } from 'playwright';
import { mkdir } from 'node:fs/promises';

// Output dir, target site and viewport are env-configurable so the same runner
// produces both Android (1080×1920) and iPhone 6.9" (1290×2796) store shots.
// Defaults keep the original local Android behaviour.
//   SHOT_OUT          — where PNGs land (created if missing)
//   SHOT_BASE         — site to screenshot (defaults to production)
//   SHOT_W / SHOT_H   — viewport in px (defaults 1080×1920)
const out = process.env.SHOT_OUT
  || '/home/thomas/projekte/bikerouter/store_assets/android/screenshots';
const baseUrl = process.env.SHOT_BASE || 'https://wegwiesel.app';
const viewport = {
  width: Number(process.env.SHOT_W) || 1080,
  height: Number(process.env.SHOT_H) || 1920,
};

await mkdir(out, { recursive: true });

function encode(obj) {
  return Buffer.from(JSON.stringify(obj)).toString('base64url').replace(/=+$/, '');
}

const shots = [
  {
    file: '02-short-trekking.png',
    desc: 'Short trekking route in Munich center',
    url: `${baseUrl}/?r=${encode({ w: [[48.137, 11.575], [48.165, 11.520]], p: 'trekking' })}`,
    wait: 8000,
  },
  {
    file: '03-gravel-bavaria.png',
    desc: 'Short gravel route in Bavarian foothills',
    url: `${baseUrl}/?r=${encode({ w: [[47.860, 11.180], [47.830, 11.250]], p: 'quaelnix-gravel' })}`,
    wait: 8000,
  },
  {
    file: '04-roundtrip-20km.png',
    desc: '20 km roundtrip from Munich, fastbike',
    url: `${baseUrl}/?r=${encode({ w: [[48.137, 11.575]], p: 'fastbike', rt: 1, d: 20, dir: 90 })}`,
    wait: 22000,
  },
  {
    file: '05-mtb-alps.png',
    desc: 'Short MTB route in the alps',
    url: `${baseUrl}/?r=${encode({ w: [[47.480, 11.090], [47.460, 11.110]], p: 'mtb-zossebart' })}`,
    wait: 8000,
  },
];

const browser = await chromium.launch({ headless: true });
const ctx = await browser.newContext({ viewport });

// Each shot runs on a fresh page so a hung/detached page can't cascade into
// the following shots — important for unattended CI runs.
let saved = 0;
for (const s of shots) {
  console.log(`→ ${s.file} (${s.desc})`);
  const page = await ctx.newPage();
  page.setDefaultTimeout(120000);
  try {
    try {
      await page.goto(s.url, { waitUntil: 'domcontentloaded', timeout: 60000 });
    } catch (e) {
      console.log(`  goto warn: ${e.message.split('\n')[0]}`);
    }
    await page.waitForTimeout(s.wait);
    try {
      await page.screenshot({ path: `${out}/${s.file}`, fullPage: false, timeout: 60000 });
      console.log(`  saved ${s.file}`);
      saved++;
    } catch (e) {
      // A busy renderer (e.g. roundtrip still calculating) can make the first
      // screenshot time out; give it one more breather and retry once.
      console.log(`  screenshot retry after: ${e.message.split('\n')[0]}`);
      await page.waitForTimeout(8000);
      try {
        await page.screenshot({ path: `${out}/${s.file}`, fullPage: false, timeout: 60000 });
        console.log(`  saved ${s.file} (retry)`);
        saved++;
      } catch (e2) {
        console.log(`  screenshot failed: ${e2.message.split('\n')[0]}`);
      }
    }
  } finally {
    await page.close().catch(() => {});
  }
}

await browser.close();
console.log(`done — ${saved}/${shots.length} screenshots saved to ${out}`);
// Non-zero exit if nothing was produced, so CI surfaces a total failure.
if (saved === 0) process.exit(1);
