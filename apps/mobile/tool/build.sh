#!/usr/bin/env bash
# Build the Campus Saga Android app, asking what to build:
#   - which server it talks to (beta, this Mac, the local network, or a URL)
#   - APK, App Bundle (Google Play) or smaller per-CPU APKs
#   - whether to raise the build number
#   - whether to install it on a connected phone
#
#   apps/mobile/tool/build.sh                 # asks everything
#   apps/mobile/tool/build.sh --server beta --type apk --install 25291FDF6001DW --yes
#
# Options (skip the matching question):
#   --server beta|local|lan|<https://…/api/v1>
#   --type   apk|aab|split
#   --bump   / --no-bump        raise the build number in pubspec.yaml
#   --install <serial>|none     adb device to install on
#   --yes                       don't ask for the final confirmation
#
# Plain-http servers (this Mac, the local network) need a debug build:
# release builds only talk HTTPS. Works with macOS's bash 3.2.
set -euo pipefail

cd "$(dirname "$0")/.."   # apps/mobile
BETA_URL="https://api-campus.silifton.com/api/v1"
PORT=8090

server="" type="" bump="" install="" yes=""
while [ $# -gt 0 ]; do
  case "$1" in
    --server) server="$2"; shift 2 ;;
    --type) type="$2"; shift 2 ;;
    --bump) bump=y; shift ;;
    --no-bump) bump=n; shift ;;
    --install) install="$2"; shift 2 ;;
    --yes|-y) yes=y; shift ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1 (see --help)"; exit 2 ;;
  esac
done

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
note() { printf '  \033[2m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m! %s\033[0m\n' "$*"; }
fail() { printf '\033[31m✗ %s\033[0m\n' "$*"; exit 1; }

# choose "Question" default "option 1" "option 2" ... → sets $choice (1-based)
choose() {
  local q="$1" def="$2"; shift 2
  bold "$q"
  local i=1
  for o in "$@"; do
    if [ "$i" = "$def" ]; then printf '  %d) %s  (default)\n' "$i" "$o"; else printf '  %d) %s\n' "$i" "$o"; fi
    i=$((i + 1))
  done
  while true; do
    printf '> '
    read -r choice || fail "No answer."
    choice="${choice:-$def}"
    if [ "$choice" -ge 1 ] 2>/dev/null && [ "$choice" -lt "$i" ]; then break; fi
    echo "  Type a number from 1 to $((i - 1))."
  done
  echo
}

command -v flutter >/dev/null || fail "flutter is not on PATH"

# ---- 1. server -----------------------------------------------------------------
lan_ip="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"
if [ -z "$server" ]; then
  choose "Which server should the app use?" 1 \
    "Beta server — $BETA_URL" \
    "This Mac over USB — http://localhost:$PORT (debug build, sets up adb reverse)" \
    "This Mac on Wi-Fi — http://${lan_ip:-<no Wi-Fi IP>}:$PORT (debug build, same network)" \
    "Another URL"
  case "$choice" in
    1) server=beta ;;
    2) server=local ;;
    3) server=lan ;;
    4) printf 'API URL, including /api/v1: '; read -r server ;;
  esac
fi
case "$server" in
  beta) api_url="$BETA_URL"; app_env=production; label=beta ;;
  local) api_url="http://localhost:$PORT/api/v1"; app_env=local; label=local ;;
  lan)
    [ -n "$lan_ip" ] || fail "No Wi-Fi IP found for this Mac"
    api_url="http://$lan_ip:$PORT/api/v1"; app_env=local; label=lan ;;
  http://*|https://*)
    api_url="${server%/}"; label=custom
    case "$api_url" in */api/v1) ;; *) warn "The URL usually ends with /api/v1" ;; esac
    case "$api_url" in https://*) app_env=production ;; *) app_env=local ;; esac ;;
  *) fail "Unknown server: $server" ;;
esac

# Plain http only works in debug builds (network_security_config in src/debug).
mode=release
case "$api_url" in http://*) mode=debug ;; esac

# ---- 2. what to build -----------------------------------------------------------
if [ -z "$type" ]; then
  if [ "$mode" = debug ]; then
    type=apk
  else
    choose "What should it build?" 1 \
      "APK — install on phones directly" \
      "App Bundle (.aab) — upload to Google Play" \
      "Smaller APKs, one per phone CPU (arm64 fits most phones)"
    case "$choice" in 1) type=apk ;; 2) type=aab ;; 3) type=split ;; esac
  fi
fi
case "$type" in apk|aab|split) ;; *) fail "Unknown type: $type" ;; esac
[ "$mode" = debug ] && [ "$type" != apk ] && fail "Plain-http servers need a debug APK (--type apk)"

# ---- 3. build number ------------------------------------------------------------
version="$(sed -n 's/^version: *//p' pubspec.yaml)"
name="${version%%+*}"
build="${version##*+}"
if [ -z "$bump" ]; then
  default_bump=2
  [ "$type" = aab ] && default_bump=1   # Play refuses a build number it has seen
  choose "Build number? (now $version)" "$default_bump" \
    "Raise it to $name+$((build + 1)) (needed for every Play upload)" \
    "Keep $version"
  [ "$choice" = 1 ] && bump=y || bump=n
fi
new_version="$version"
[ "$bump" = y ] && new_version="$name+$((build + 1))"

# ---- 4. signing -----------------------------------------------------------------
if [ "$mode" = release ] && [ ! -f android/key.properties ]; then
  warn "android/key.properties is missing: the build is signed with the debug key."
  warn "Fine for testing; Google Play won't accept it (see docs/BETA.md)."
fi

# ---- 5. install on a phone? -----------------------------------------------------
devices=""
if command -v adb >/dev/null && [ "$type" != aab ]; then
  all="$(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }')"
  # A phone on both USB and wireless debugging: list it once (USB).
  for d in $all; do
    case "$d" in
      adb-*._adb-tls-connect._tcp*)
        usb="${d#adb-}"; usb="${usb%%-*}"
        echo "$all" | grep -qx "$usb" && continue ;;
    esac
    devices="$devices $d"
  done
fi
if [ -z "$install" ]; then
  if [ -z "$devices" ]; then
    install=none
  else
    set -- $devices
    opts=()
    for d in "$@"; do
      model="$(adb -s "$d" shell getprop ro.product.model </dev/null 2>/dev/null | tr -d '\r')"
      opts+=("$model ($d)")
    done
    opts+=("Don't install")
    choose "Install it on a connected phone?" 1 "${opts[@]}"
    if [ "$choice" -le $# ]; then eval "install=\${$choice}"; else install=none; fi
  fi
fi

# ---- confirm --------------------------------------------------------------------
bold "Building"
note "Server:   $api_url"
note "Build:    $mode $type, version $new_version"
note "Install:  $install"
if [ -z "$yes" ]; then
  printf 'Go? [Y/n] '
  read -r ok || ok=n
  case "$ok" in ""|y|Y|yes) ;; *) echo "Cancelled."; exit 0 ;; esac
fi

if [ "$new_version" != "$version" ]; then
  sed -i '' "s/^version: .*/version: $new_version/" pubspec.yaml
  note "pubspec.yaml: version $new_version (commit it)"
fi

defines="build/env.$label.json"
mkdir -p build
printf '{\n  "APP_ENV": "%s",\n  "API_BASE_URL": "%s"\n}\n' "$app_env" "$api_url" > "$defines"

case "$type" in
  apk) flutter build apk "--$mode" --dart-define-from-file="$defines"
       src="build/app/outputs/flutter-apk/app-$mode.apk" ;;
  split) flutter build apk --release --split-per-abi --dart-define-from-file="$defines"
         src="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" ;;
  aab) flutter build appbundle --release --dart-define-from-file="$defines"
       src="build/app/outputs/bundle/release/app-release.aab" ;;
esac

mkdir -p build/out
ext="${src##*.}"
out="build/out/campussaga-${new_version/+/-}-$label-$mode.$ext"
cp "$src" "$out"
bold "✓ $(cd "$(dirname "$out")" && pwd)/$(basename "$out")"
[ "$type" = split ] && note "Other CPUs: build/app/outputs/flutter-apk/app-*-release.apk"

# ---- install --------------------------------------------------------------------
if [ "$install" != none ]; then
  [ "$server" = local ] && adb -s "$install" reverse tcp:$PORT tcp:$PORT </dev/null >/dev/null && note "adb reverse tcp:$PORT ready"
  if ! result="$(adb -s "$install" install -r "$out" </dev/null 2>&1)"; then
    if echo "$result" | grep -q INSTALL_FAILED_UPDATE_INCOMPATIBLE; then
      warn "The phone has a build signed with another key (debug vs release)."
      printf 'Uninstall it first? This signs out and clears the app'\''s data on the phone. [y/N] '
      read -r ok
      case "$ok" in y|Y|yes) adb -s "$install" uninstall com.silifton.campussaga </dev/null >/dev/null
                              adb -s "$install" install "$out" </dev/null >/dev/null ;;
                     *) fail "Not installed." ;; esac
    else
      echo "$result"; fail "Install failed."
    fi
  fi
  adb -s "$install" shell monkey -p com.silifton.campussaga -c android.intent.category.LAUNCHER 1 </dev/null >/dev/null 2>&1 || true
  bold "✓ Installed and opened on $install"
fi
