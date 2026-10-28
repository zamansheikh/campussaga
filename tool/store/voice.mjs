// Generates the promo-video narration with ElevenLabs, one clip per line
// (intro, each screenshot scene, outro), and records each clip's length so
// video.mjs can time the scenes to the voice.
//
//   ELEVENLABS_KEY_FILE=/path/to/key.txt node voice.mjs [en|bn]
//
// Clips are kept in audio/voice/<lang>/ (in git) by text + voice + model, so
// only changed lines are generated again. The key is read from the file at run
// time and never written anywhere.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { languages } from './content.mjs';

const here = path.dirname(new URL(import.meta.url).pathname);
const MODEL = process.env.ELEVENLABS_MODEL ?? 'eleven_v4';
const keyFile = process.env.ELEVENLABS_KEY_FILE;
if (!keyFile) throw new Error('Set ELEVENLABS_KEY_FILE to the file holding the ElevenLabs API key');
const key = fs.readFileSync(keyFile, 'utf8').match(/sk_[A-Za-z0-9_]{20,}/)?.[0];
if (!key) throw new Error(`No ElevenLabs key found in ${keyFile}`);
const only = process.argv[2];

const duration = (file) =>
  parseFloat(execFileSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', file]).toString());

async function tts(text, voiceId, lang, out) {
  const res = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}?output_format=mp3_44100_128`, {
    method: 'POST',
    headers: { 'xi-api-key': key, 'Content-Type': 'application/json', Accept: 'audio/mpeg' },
    body: JSON.stringify({
      text,
      model_id: MODEL,
      language_code: lang,
      voice_settings: { stability: 0.5, similarity_boost: 0.8, style: 0.25, use_speaker_boost: true },
    }),
  });
  if (!res.ok) throw new Error(`ElevenLabs ${res.status}: ${(await res.text()).slice(0, 300)}`);
  fs.writeFileSync(out, Buffer.from(await res.arrayBuffer()));
}

for (const [lang, L] of Object.entries(languages)) {
  if (only && only !== lang) continue;
  const dir = path.join(here, 'audio/voice', lang);
  fs.mkdirSync(dir, { recursive: true });
  const lines = [['intro', L.voice.intro], ...L.shots.map((s, i) => [`scene-${i + 1}`, s.say]), ['outro', L.voice.outro]];
  const timing = {};
  for (const [name, text] of lines) {
    const hash = crypto.createHash('sha1').update(`${MODEL}|${L.voice.id}|${text}`).digest('hex').slice(0, 10);
    const file = path.join(dir, `${name}-${hash}.mp3`);
    if (!fs.existsSync(file)) {
      await tts(text, L.voice.id, lang, file);
      console.log(`generated ${lang}/${name}`);
    }
    timing[name] = { file: path.relative(here, file), seconds: +duration(file).toFixed(3), text };
  }
  fs.writeFileSync(path.join(dir, 'timing.json'), JSON.stringify(timing, null, 2));
  console.log(lang, Object.values(timing).map((t) => t.seconds.toFixed(1)).join(' '));
}
