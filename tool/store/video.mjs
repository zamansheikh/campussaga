// Renders the Google Play promo video (1920 x 1080, 30 fps) for
// each language: store/google-play/<locale>/promo-video.mp4. Play takes a
// YouTube link, so upload the file to YouTube (unlisted is fine).
// Frames are drawn by Chrome with a scripted timeline, then encoded by ffmpeg.
// Narration (voice.mjs) and the music bed (audio/music-bed.mp3, made with
// ElevenLabs Music on a paid plan, so cleared for commercial use) are mixed in
// when present; scenes are timed to the narration.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import puppeteer from 'puppeteer-core';
import { languages } from './content.mjs';
import { doc, phone, rings, iconUrl } from './page.mjs';

const here = path.dirname(new URL(import.meta.url).pathname);
const root = path.resolve(here, '../..');
const RAW = process.env.RAW ?? path.join(here, '.cache/raw');
const OUT = path.join(root, 'store/google-play');
const CHROME = process.env.CHROME ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const FPS = 30;
const INTRO = 3.2, SCENE = 3.3, OUTRO = 3.6;
const only = process.argv[2]; // optional: en | bn

const shot = (lang, name) => pathToFileURL(path.join(RAW, `${lang}-${name}.png`)).href;

function html(lang, L) {
  const bn = lang === 'bn';
  const scenes = L.shots.map((s, i) => {
    const phones = s.screens.length === 1
      ? phone({ shotUrl: shot(lang, s.screens[0]), w: 560, x: 1170, y: 110, cls: `a s${i} p0` })
      : phone({ shotUrl: shot(lang, s.screens[0]), w: 470, x: 1000, y: 150, rotate: -5, cls: `a s${i} p0` })
        + phone({ shotUrl: shot(lang, s.screens[1]), w: 470, x: 1330, y: 190, rotate: 5, cls: `a s${i} p1` });
    return `
    <div style="position:absolute;left:150px;top:0;bottom:0;width:820px;display:flex;flex-direction:column;justify-content:center">
      <div><div class="chip a s${i} t0" style="font-size:${bn ? 30 : 28}px"><i></i>${s.chip}</div></div>
      <div class="title a s${i} t1" style="font-size:${bn ? 78 : 86}px;margin-top:30px">${s.title}</div>
      <div class="body a s${i} t2" style="font-size:${bn ? 36 : 34}px;margin-top:26px;max-width:720px">${s.body}</div>
    </div>${phones}`;
  }).join('');
  const brand = (cls, top) => `
    <div class="a ${cls}" style="position:absolute;left:0;right:0;top:${top}px;display:flex;flex-direction:column;align-items:center">
      <img class="a ${cls}-logo" src="${iconUrl}" style="width:210px;height:210px;border-radius:48px;box-shadow:0 30px 70px -20px rgba(2,24,22,.8),0 0 0 3px rgba(255,255,255,.16)">
      <div class="a ${cls}-name" style="font-family:Baloo;font-weight:800;font-size:112px;line-height:1;margin-top:44px;letter-spacing:-.01em">VarsityKotha</div>
      <div class="a ${cls}-bn" style="font-family:Hind;font-weight:600;font-size:50px;margin-top:10px;opacity:.9">ভার্সিটি কথা</div>
      <div class="a ${cls}-tag ${bn ? 'bn' : 'en'}" style="margin-top:34px;text-align:center">
        <div class="body" style="font-size:${bn ? 40 : 38}px;color:#fff">${cls === 'intro' ? L.tagline : L.outro}</div>
        ${cls === 'outro' ? `<div class="body" style="font-family:Inter;font-size:30px;margin-top:12px;opacity:.8">varsitykotha.com</div>` : ''}
      </div>
    </div>`;
  return doc(lang, 1920, 1080, `<div class="bg">${rings([[1450, 560, 1300], [1450, 560, 900]])}</div>
    ${brand('intro', 170)}${scenes}${brand('outro', 170)}
    <style>.a{will-change:transform,opacity}</style>`);
}

// Timeline: returns [selector, opacity, transform] for time t (seconds).
const clamp = (x) => Math.max(0, Math.min(1, x));
const outCubic = (x) => 1 - Math.pow(1 - x, 3);
const inCubic = (x) => x * x * x;
const outBack = (x) => { const c = 1.5; return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2); };
const span = (t, a, b) => clamp((t - a) / (b - a));

function frameStyles(t, plan) {
  const n = plan.scenes.length;
  const st = [];
  const brandIn = (cls, t0) => {
    const k = (a, b) => outCubic(span(t, t0 + a, t0 + b));
    const logo = span(t, t0 + 0.1, t0 + 0.8);
    st.push([`.${cls}-logo`, clamp(logo * 2), `scale(${0.55 + 0.45 * outBack(logo)})`]);
    for (const [part, a, b] of [['name', 0.45, 1.05], ['bn', 0.65, 1.25], ['tag', 0.85, 1.45]]) {
      const v = k(a, b);
      st.push([`.${cls}-${part}`, v, `translateY(${(1 - v) * 40}px)`]);
    }
  };
  // Intro, then fade it out as scene 0 starts.
  brandIn('intro', 0);
  const introOut = inCubic(span(t, plan.intro - 0.45, plan.intro));
  st.push(['.intro', 1 - introOut, `translateY(${-introOut * 40}px)`]);
  for (let i = 0; i < n; i++) {
    const [t0, t1] = plan.scenes[i];
    const out = inCubic(span(t, t1 - 0.4, t1));
    const visible = t >= t0 - 0.01 && t <= t1 + 0.01;
    for (const [j, a] of [[0, 0.05], [1, 0.15], [2, 0.3]]) {
      const v = outCubic(span(t, t0 + a, t0 + a + 0.55));
      st.push([`.s${i}.t${j}`, visible ? v * (1 - out) : 0, `translateX(${(1 - v) * -50 - out * 30}px)`]);
    }
    for (const [j, a] of [[0, 0.0], [1, 0.12]]) {
      const v = outCubic(span(t, t0 + a, t0 + a + 0.7));
      const drift = -18 * span(t, t0, t1);
      st.push([`.s${i}.p${j}`, visible ? v * (1 - out) : 0, `translateY(${(1 - v) * 160 + drift - out * 40}px)`]);
    }
  }
  const o0 = plan.outro;
  if (t >= o0 - 0.01) {
    st.push(['.outro', 1, 'none']);
    brandIn('outro', o0);
  } else st.push(['.outro', 0, 'none']);
  return st;
}


// Scene times. With narration (voice.mjs), each part lasts as long as its
// line plus a breath; without, the fixed defaults.
function timeline(lang, n) {
  const file = path.join(here, 'audio/voice', lang, 'timing.json');
  const voice = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : null;
  if (voice) for (const v of Object.values(voice)) v.file = path.join(here, v.file);
  const len = (name, min, pad) => (voice ? Math.max(min, voice[name].seconds + pad) : min);
  const intro = len('intro', INTRO, 1.3);
  const scenes = [];
  const cues = voice ? [[voice.intro.file, 0.55]] : [];
  let t = intro;
  for (let i = 0; i < n; i++) {
    const d = len(`scene-${i + 1}`, SCENE, 0.95);
    scenes.push([t, t + d]);
    if (voice) cues.push([voice[`scene-${i + 1}`].file, t + 0.3]);
    t += d;
  }
  const outro = t;
  if (voice) cues.push([voice.outro.file, outro + 0.6]);
  const total = outro + len('outro', OUTRO, 1.8);
  return { intro, scenes, outro, total, cues };
}

// Narration over the music bed: the music ducks under the voice, fades in and
// out, and the mix is levelled to -16 LUFS (YouTube plays at about -14).
function mixAudio(lang, plan) {
  if (!plan.cues.length) return null;
  const music = path.join(here, 'audio/music-bed.mp3');
  const out = path.join(here, `.cache/audio-${lang}.m4a`);
  const inputs = plan.cues.flatMap(([f]) => ['-i', f]);
  const hasMusic = fs.existsSync(music);
  if (hasMusic) inputs.push('-i', music);
  const delays = plan.cues.map(([, at], i) => `[${i}:a]adelay=${Math.round(at * 1000)}:all=1[v${i}]`);
  const voices = `${plan.cues.map((_, i) => `[v${i}]`).join('')}amix=inputs=${plan.cues.length}:normalize=0,apad,atrim=0:${plan.total.toFixed(3)},asplit=2[vo][key]`;
  const m = plan.cues.length;
  const graph = hasMusic
    ? [...delays, voices,
      `[${m}:a]atrim=0:${plan.total.toFixed(3)},afade=t=in:d=0.8,afade=t=out:st=${(plan.total - 2.2).toFixed(3)}:d=2.2,volume=0.2[bed]`,
      `[bed][key]sidechaincompress=threshold=0.02:ratio=10:attack=15:release=400[duck]`,
      `[duck][vo]amix=inputs=2:normalize=0,loudnorm=I=-16:TP=-1.5:LRA=11[a]`]
    : [...delays, voices.replace(',asplit=2[vo][key]', '[vo]'), '[vo]loudnorm=I=-16:TP=-1.5:LRA=11[a]'];
  execFileSync('ffmpeg', ['-y', '-loglevel', 'error', ...inputs, '-filter_complex', graph.join(';'), '-map', '[a]',
    '-ar', '48000', '-c:a', 'aac', '-b:a', '192k', out]);
  return out;
}

const browser = await puppeteer.launch({ executablePath: CHROME, headless: true, args: ['--allow-file-access-from-files', '--font-render-hinting=none'] });
try {
  for (const [lang, L] of Object.entries(languages)) {
    if (only && only !== lang) continue;
    const n = L.shots.length;
    const plan = timeline(lang, n);
    const total = plan.total;
    const frames = path.join(here, '.cache/frames', lang);
    fs.rmSync(frames, { recursive: true, force: true });
    fs.mkdirSync(frames, { recursive: true });
    const file = path.join(here, `.cache/html/video-${lang}.html`);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, html(lang, L));
    const page = await browser.newPage();
    await page.setViewport({ width: 1920, height: 1080, deviceScaleFactor: 1 });
    await page.goto(pathToFileURL(file).href, { waitUntil: 'load' });
    await page.evaluate(() => document.fonts.ready);
    // Phones keep their own rotation: remember it once.
    await page.evaluate(() => document.querySelectorAll('.phone').forEach((p) => { p.dataset.base = p.style.transform; }));
    const count = Math.round(total * FPS);
    for (let f = 0; f < count; f++) {
      const styles = frameStyles(f / FPS, plan);
      await page.evaluate((styles) => {
        for (const [sel, op, tr] of styles) {
          for (const el of document.querySelectorAll(sel)) {
            el.style.opacity = op;
            el.style.transform = `${tr} ${el.dataset.base ?? ''}`;
          }
        }
      }, styles);
      await page.screenshot({ path: path.join(frames, `${String(f).padStart(5, '0')}.jpg`), type: 'jpeg', quality: 94 });
    }
    await page.close();
    const out = path.join(OUT, L.playLocale, 'promo-video.mp4');
    const audio = mixAudio(lang, plan);
    execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-framerate', String(FPS), '-i', path.join(frames, '%05d.jpg'),
      ...(audio ? ['-i', audio] : []),
      '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-pix_fmt', 'yuv420p',
      ...(audio ? ['-c:a', 'aac', '-b:a', '192k', '-shortest'] : []),
      '-movflags', '+faststart', out]);
    console.log(`${path.relative(root, out)} (${total.toFixed(1)} s, ${count} frames, ${audio ? 'voice + music' : 'no audio'})`);
  }
} finally {
  await browser.close();
}
