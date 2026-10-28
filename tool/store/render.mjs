// Renders the Google Play graphics with headless Chrome:
//   store/google-play/<locale>/phone-NN.png   1080 x 1920 screenshots
//   store/google-play/<locale>/feature-graphic.png   1024 x 500
//   store/google-play/icon-512.png
// Raw app screens come from apps/mobile/tool/screenshots/store_test.dart
// (path in RAW, default tool/store/.cache/raw). Run tool/store/build.sh.
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import puppeteer from 'puppeteer-core';
import { languages } from './content.mjs';
import { doc, phone, rings, iconUrl } from './page.mjs';

const here = path.dirname(new URL(import.meta.url).pathname);
const root = path.resolve(here, '../..');
const RAW = process.env.RAW ?? path.join(here, '.cache/raw');
const OUT = path.join(root, 'store/google-play');
const CHROME = process.env.CHROME ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const tmp = path.join(here, '.cache/html');
fs.mkdirSync(tmp, { recursive: true });

const shot = (lang, name) => pathToFileURL(path.join(RAW, `${lang}-${name}.png`)).href;

async function render(browser, html, w, h, out, type = 'png') {
  const file = path.join(tmp, path.basename(out) + '.html');
  fs.writeFileSync(file, html);
  const page = await browser.newPage();
  await page.setViewport({ width: w, height: h, deviceScaleFactor: 1 });
  await page.goto(pathToFileURL(file).href, { waitUntil: 'load' });
  await page.evaluate(() => document.fonts.ready);
  fs.mkdirSync(path.dirname(out), { recursive: true });
  await page.screenshot({ path: out, type, ...(type === 'jpeg' ? { quality: 95 } : {}) });
  await page.close();
}

function screenshotHtml(lang, s) {
  const bn = lang === 'bn';
  const text = `
  <div style="position:absolute;left:0;right:0;top:${bn ? 104 : 118}px;text-align:center;padding:0 90px">
    <div class="chip" style="font-size:${bn ? 34 : 31}px"><i></i>${s.chip}</div>
    <div class="title" style="font-size:${bn ? 84 : 92}px;margin-top:${bn ? 30 : 40}px">${s.title}</div>
    <div class="body" style="font-size:${bn ? 39 : 37}px;margin:${bn ? 22 : 30}px auto 0;max-width:860px">${s.body}</div>
  </div>`;
  const phones = s.screens.length === 1
    ? phone({ shotUrl: shot(lang, s.screens[0]), w: 800, x: 140, y: 700 })
    : phone({ shotUrl: shot(lang, s.screens[0]), w: 590, x: 36, y: 760, rotate: -5 })
      + phone({ shotUrl: shot(lang, s.screens[1]), w: 590, x: 456, y: 810, rotate: 5 });
  return doc(lang, 1080, 1920, `<div class="bg">${rings([[540, 1500, 1500], [540, 1500, 1100]])}</div>${text}${phones}`);
}

function featureHtml(lang, L) {
  const bn = lang === 'bn';
  return doc(lang, 1024, 500, `<div class="bg">${rings([[820, 520, 900], [820, 520, 620]])}</div>
  <div style="position:absolute;left:64px;top:0;bottom:0;display:flex;flex-direction:column;justify-content:center;width:520px">
    <div style="display:flex;align-items:center;gap:26px">
      <img src="${iconUrl}" style="width:118px;height:118px;border-radius:27px;box-shadow:0 18px 40px -12px rgba(2,24,22,.7),0 0 0 2px rgba(255,255,255,.18)">
      <div>
        <div style="font-family:Baloo;font-weight:800;font-size:64px;line-height:1;letter-spacing:-.01em">VarsityKotha</div>
        <div style="font-family:Hind;font-weight:600;font-size:31px;line-height:1.2;margin-top:6px;opacity:.88">ভার্সিটি কথা</div>
      </div>
    </div>
    <div class="${bn ? 'bn' : 'en'}" style="margin-top:30px">
      <div class="title" style="font-size:${bn ? 34 : 36}px;line-height:1.22;max-width:470px;font-weight:${bn ? 800 : 700};letter-spacing:${bn ? 0 : '-.01em'}">${L.tagline}</div>
      <div class="body" style="font-size:${bn ? 22 : 21}px;margin-top:10px">${L.subTagline}</div>
    </div>
  </div>
  ${phone({ shotUrl: shot(lang, '05-voice'), w: 236, x: 640, y: 120, rotate: -7 })}
  ${phone({ shotUrl: shot(lang, '01-today'), w: 256, x: 790, y: 64, rotate: 6 })}`);
}

const browser = await puppeteer.launch({ executablePath: CHROME, headless: true, args: ['--allow-file-access-from-files', '--font-render-hinting=none'] });
try {
  for (const [lang, L] of Object.entries(languages)) {
    const dir = path.join(OUT, L.playLocale);
    for (const [i, s] of L.shots.entries()) {
      const out = path.join(dir, `phone-${String(i + 1).padStart(2, '0')}.png`);
      await render(browser, screenshotHtml(lang, s), 1080, 1920, out);
      console.log(path.relative(root, out));
    }
    const fg = path.join(dir, 'feature-graphic.png');
    await render(browser, featureHtml(lang, L), 1024, 500, fg);
    console.log(path.relative(root, fg));
  }
  const icon = path.join(OUT, 'icon-512.png');
  await render(browser, `<!doctype html><style>*{margin:0}body{width:512px;height:512px}</style><img src="${iconUrl}" width="512" height="512">`, 512, 512, icon);
  console.log(path.relative(root, icon));
} finally {
  await browser.close();
}
