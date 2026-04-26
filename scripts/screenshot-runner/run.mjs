import { chromium } from 'playwright';

const out = '/home/thomas/projekte/bikerouter/store_assets/android/screenshots';
const baseUrl = 'https://wegwiesel.app';

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
    wait: 14000,
  },
  {
    file: '05-mtb-alps.png',
    desc: 'Short MTB route in the alps',
    url: `${baseUrl}/?r=${encode({ w: [[47.480, 11.090], [47.460, 11.110]], p: 'mtb-zossebart' })}`,
    wait: 8000,
  },
];

const browser = await chromium.launch({ headless: true });
const ctx = await browser.newContext({ viewport: { width: 1080, height: 1920 } });
const page = await ctx.newPage();
page.setDefaultTimeout(120000);

for (const s of shots) {
  console.log(`→ ${s.file} (${s.desc})`);
  try {
    await page.goto(s.url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  } catch (e) {
    console.log(`  goto warn: ${e.message.split('\n')[0]}`);
  }
  await page.waitForTimeout(s.wait);
  try {
    await page.screenshot({ path: `${out}/${s.file}`, fullPage: false, timeout: 60000 });
    console.log(`  saved ${s.file}`);
  } catch (e) {
    console.log(`  screenshot failed: ${e.message.split('\n')[0]}`);
  }
}

await browser.close();
console.log('done');
