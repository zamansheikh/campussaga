// HTML building blocks for the store graphics: fonts, the brand background,
// a phone mockup and caption blocks. Rendered by Chrome (render.mjs), so
// Bangla is shaped properly.
import { pathToFileURL } from 'node:url';
import path from 'node:path';

const here = path.dirname(new URL(import.meta.url).pathname);
const root = path.resolve(here, '../..');
const url = (p) => pathToFileURL(p).href;
export const fontsDir = path.join(here, '.cache/fonts');
export const iconUrl = url(path.join(root, 'assets/icon/varsitykotha-icon.svg'));

export const C = {
  tealLight: '#2DD4BF',
  teal: '#0F9488',
  tealDark: '#0B5E57',
  tealDeep: '#073F3B',
  light: '#F8FAFC',
  dark: '#0B1220',
};

export const css = `
@font-face { font-family: Inter; src: url('${url(path.join(fontsDir, 'Inter[opsz,wght].ttf'))}'); font-weight: 100 900; }
@font-face { font-family: Baloo; src: url('${url(path.join(fontsDir, 'BalooDa2[wght].ttf'))}'); font-weight: 400 800; }
@font-face { font-family: Hind; src: url('${url(path.join(fontsDir, 'HindSiliguri-Medium.ttf'))}'); font-weight: 500; }
@font-face { font-family: Hind; src: url('${url(path.join(fontsDir, 'HindSiliguri-SemiBold.ttf'))}'); font-weight: 600; }
@font-face { font-family: Hind; src: url('${url(path.join(fontsDir, 'HindSiliguri-Bold.ttf'))}'); font-weight: 700; }
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { width: 100%; height: 100%; overflow: hidden; }
body { -webkit-font-smoothing: antialiased; text-rendering: geometricPrecision; color: #fff; }
.bg {
  position: absolute; inset: 0; overflow: hidden;
  background:
    radial-gradient(120% 60% at 12% -5%, rgba(45,212,191,.55) 0%, rgba(45,212,191,0) 60%),
    radial-gradient(90% 50% at 110% 105%, rgba(7,63,59,.9) 0%, rgba(7,63,59,0) 70%),
    linear-gradient(165deg, ${C.teal} 0%, ${C.tealDark} 58%, ${C.tealDeep} 100%);
}
.bg::before {
  content: ''; position: absolute; inset: 0; opacity: .07;
  background-image: radial-gradient(#fff 1.4px, transparent 1.6px);
  background-size: 34px 34px;
  mask-image: linear-gradient(180deg, #000 0%, transparent 70%);
}
.bg .ring { position: absolute; border-radius: 50%; border: 2px solid rgba(255,255,255,.07); }
.en .title { font-family: Inter; font-weight: 800; letter-spacing: -0.025em; line-height: 1.04; }
.en .body, .en .chip { font-family: Inter; }
.bn .title { font-family: Baloo; font-weight: 800; line-height: 1.22; letter-spacing: 0; }
.bn .body, .bn .chip { font-family: Hind; }
.chip {
  display: inline-flex; align-items: center; gap: 14px;
  padding: 12px 26px 12px 18px; border-radius: 999px;
  background: rgba(255,255,255,.13); border: 1.5px solid rgba(255,255,255,.22);
  font-weight: 600; color: #fff; backdrop-filter: blur(6px);
}
.chip i { width: 14px; height: 14px; border-radius: 50%; background: ${C.tealLight}; box-shadow: 0 0 0 6px rgba(45,212,191,.25); }
.title { white-space: pre-line; color: #fff; text-shadow: 0 2px 30px rgba(4,47,44,.25); }
.body { color: rgba(255,255,255,.84); font-weight: 500; line-height: 1.42; }
.phone {
  position: absolute; background: #0A0F1A; padding: var(--bezel);
  border-radius: var(--r);
  box-shadow: 0 70px 120px -30px rgba(2,24,22,.75), 0 30px 60px -20px rgba(2,24,22,.5),
              inset 0 0 0 2px rgba(255,255,255,.10), inset 0 0 0 5px #05080F;
}
.phone .screen { position: relative; overflow: hidden; border-radius: calc(var(--r) - var(--bezel)); }
.phone .screen img.shot { display: block; width: 100%; }
.phone .status {
  height: var(--sb); display: flex; align-items: center; justify-content: space-between;
  padding: 0 calc(var(--sb) * .9); font-family: Inter; font-weight: 600; font-size: calc(var(--sb) * .5);
}
.phone .punch {
  position: absolute; top: calc(var(--sb) * .26); left: 50%; transform: translateX(-50%);
  width: calc(var(--sb) * .48); height: calc(var(--sb) * .48); border-radius: 50%;
  background: #05080F; box-shadow: inset 0 0 0 2px #1B2233;
}
.phone .icons { display: flex; gap: calc(var(--sb) * .22); align-items: center; }
.phone .icons svg { height: calc(var(--sb) * .44); width: auto; }
`;

/** Status bar icons (signal, Wi-Fi, battery) in [color]. */
function statusIcons(color) {
  return `<span class="icons">
  <svg viewBox="0 0 20 16"><path fill="${color}" d="M1 15h3v-4H1zM6 15h3V8H6zM11 15h3V4h-3zM16 15h3V0h-3z"/></svg>
  <svg viewBox="0 0 22 16"><path fill="${color}" d="M11 16 22 4.6A15.6 15.6 0 0 0 11 0 15.6 15.6 0 0 0 0 4.6z"/></svg>
  <svg viewBox="0 0 30 16"><rect x="1" y="1" width="24" height="14" rx="3.5" fill="none" stroke="${color}" stroke-width="2"/><rect x="4" y="4" width="16" height="8" rx="1.5" fill="${color}"/><rect x="26.5" y="5" width="2.5" height="6" rx="1" fill="${color}"/></svg>
</span>`;
}

/**
 * A phone showing [shotUrl]. [w] is the outer width in px; the screenshot is
 * a 390 x 844 phone, with a status bar added above it.
 */
export function phone({ shotUrl, w, x, y, rotate = 0, dark = false, style = '', cls = '' }) {
  const bezel = Math.round(w * 0.024);
  const r = Math.round(w * 0.13);
  const sb = Math.round((w - 2 * bezel) * 24 / 390);
  const bg = dark ? C.dark : C.light;
  const fg = dark ? '#E5E7EB' : '#0F172A';
  return `<div class="phone ${cls}" style="--bezel:${bezel}px;--r:${r}px;--sb:${sb}px;width:${w}px;left:${x}px;top:${y}px;transform:rotate(${rotate}deg);${style}">
  <div class="screen" style="background:${bg}">
    <div class="status" style="color:${fg}"><span>10:05</span>${statusIcons(fg)}</div>
    <div class="punch"></div>
    <img class="shot" src="${shotUrl}">
  </div>
</div>`;
}

export function rings(list) {
  return list.map(([x, y, d]) => `<div class="ring" style="left:${x - d / 2}px;top:${y - d / 2}px;width:${d}px;height:${d}px"></div>`).join('');
}

export const doc = (lang, w, h, body) => `<!doctype html><html lang="${lang}"><head><meta charset="utf-8">
<style>${css} body{width:${w}px;height:${h}px}</style></head>
<body class="${lang}">${body}</body></html>`;
