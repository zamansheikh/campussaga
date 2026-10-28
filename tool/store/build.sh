#!/usr/bin/env bash
# Rebuilds every Google Play asset in store/google-play/ (docs/PLAY_STORE.md):
#   1. app screens, rendered by Flutter with demo data (EN + BN)
#   2. framed screenshots, feature graphics and the 512 px icon (Chrome)
#   3. promo videos (Chrome frames + ffmpeg), with ElevenLabs narration and music
#      from tool/store/audio/. Changed narration lines are generated again only
#      when ELEVENLABS_KEY_FILE points at the API key file.
#
#   tool/store/build.sh            # everything
#   tool/store/build.sh --no-video # skip the videos (about a minute each)
# Needs Flutter, Node 20+, Google Chrome and ffmpeg.
set -euo pipefail
cd "$(dirname "$0")"
here="$PWD"
video=y
[ "${1:-}" = "--no-video" ] && video=n

# Fonts (SIL Open Font License) from the Google Fonts repository.
mkdir -p .cache/fonts
for f in "balooda2/BalooDa2[wght].ttf" "inter/Inter[opsz,wght].ttf" \
         hindsiliguri/HindSiliguri-Medium.ttf hindsiliguri/HindSiliguri-SemiBold.ttf \
         hindsiliguri/HindSiliguri-Bold.ttf; do
  name="$(basename "$f")"
  [ -s ".cache/fonts/$name" ] && continue
  url="https://github.com/google/fonts/raw/main/ofl/$(echo "$f" | sed 's/\[/%5B/;s/\]/%5D/')"
  curl -sfL -o ".cache/fonts/$name" "$url"
done

[ -d node_modules ] || npm install --no-fund --no-audit

rm -rf .cache/raw
(cd ../../apps/mobile && flutter test tool/screenshots/store_test.dart \
  --dart-define=SHOTS_DIR="$here/.cache/raw")

node render.mjs
if [ "$video" = y ]; then
  [ -n "${ELEVENLABS_KEY_FILE:-}" ] && node voice.mjs
  node video.mjs
fi
echo "Done: store/google-play/"
