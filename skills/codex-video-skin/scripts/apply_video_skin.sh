#!/bin/bash

set -euo pipefail

fail() {
  printf 'Codex Video Skin: %s\n' "$*" >&2
  exit 1
}

STATE_ROOT="${CODEX_VIDEO_SKIN_STATE_ROOT:-$HOME/Library/Application Support/CodexDreamSkinStudio}"
THEME_DIR="$STATE_ROOT/theme"
STUDIO_DIR="${CODEX_VIDEO_SKIN_STUDIO_DIR:-$HOME/.codex/codex-dream-skin-studio}"
INJECTOR="$STUDIO_DIR/scripts/injector.mjs"
COMMON="$STUDIO_DIR/scripts/common-macos.sh"
PORT="${CODEX_VIDEO_SKIN_PORT:-9341}"
FOCUS_X="${CODEX_VIDEO_FOCUS_X:-0.5}"
FOCUS_Y="${CODEX_VIDEO_FOCUS_Y:-0.4}"
VIDEO_FPS="${CODEX_VIDEO_FPS:-30}"
FFMPEG="$(command -v ffmpeg || true)"
FFPROBE="$(command -v ffprobe || true)"

find_runtime() {
  local app identifier node
  for app in "/Applications/ChatGPT.app" "$HOME/Applications/ChatGPT.app" "/Applications/Codex.app" "$HOME/Applications/Codex.app"; do
    [ -f "$app/Contents/Info.plist" ] || continue
    identifier="$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "$app/Contents/Info.plist" 2>/dev/null || true)"
    [ "$identifier" = "com.openai.codex" ] || continue
    node="$app/Contents/Resources/cua_node/bin/node"
    [ -x "$node" ] || fail "Codex bundled Node.js runtime is missing."
    printf '%s\n' "$node"
    return
  done
  fail "Official Codex Desktop app was not found."
}

preflight() {
  case "$VIDEO_FPS" in ''|*[!0-9]*) fail "CODEX_VIDEO_FPS must be an integer between 1 and 120." ;; esac
  [ "$VIDEO_FPS" -ge 1 ] && [ "$VIDEO_FPS" -le 120 ] || fail "CODEX_VIDEO_FPS must be an integer between 1 and 120."
  [ -n "$FFMPEG" ] || fail "ffmpeg is required."
  [ -n "$FFPROBE" ] || fail "ffprobe is required."
  [ -f "$THEME_DIR/theme.json" ] || fail "Active Skin Studio theme.json is missing."
  [ -f "$INJECTOR" ] || fail "Installed Skin Studio injector is missing."
  [ -f "$STUDIO_DIR/assets/renderer-inject.js" ] || fail "Installed renderer injection asset is missing."
  /usr/bin/grep -q 'pauseVideo' "$STUDIO_DIR/assets/renderer-inject.js" || fail "Installed Skin Studio engine does not include pause/resume video support."
  /usr/bin/grep -q 'SCHEDULE_DELAY_MS = 240' "$STUDIO_DIR/assets/renderer-inject.js" || fail "Installed Skin Studio renderer lacks the CPU debounce fix."
  [ -f "$COMMON" ] || fail "Installed Skin Studio runtime guard is missing."
  # Reuse the engine's signed-app and process-owned CDP checks instead of
  # trusting any arbitrary loopback listener. Preserve custom test state roots.
  custom_state_root="$STATE_ROOT"
  . "$COMMON"
  [ -n "${CODEX_VIDEO_SKIN_STATE_ROOT:-}" ] && STATE_ROOT="$custom_state_root" && THEME_DIR="$STATE_ROOT/theme"
  discover_codex_app
  require_macos_runtime
  NODE="$RUNTIME_NODE"
}

preflight

if [ "${1:-}" = "--check" ]; then
  printf 'Codex Video Skin preflight: pass\n'
  printf 'Theme: %s\nStudio: %s\nPort: %s\n' "$THEME_DIR" "$STUDIO_DIR" "$PORT"
  exit 0
fi

VIDEO_PATH="${1:-}"
THEME_NAME="${2:-}"
[ -n "$VIDEO_PATH" ] || fail "Usage: apply_video_skin.sh /absolute/path/video [optional theme name]"
[ -f "$VIDEO_PATH" ] || fail "Video file not found: $VIDEO_PATH"

TMP_ROOT="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/codex-video-skin.XXXXXX")"
trap '/bin/rm -rf "$TMP_ROOT"' EXIT
PREPARED="$TMP_ROOT/theme"
/bin/mkdir -p "$PREPARED"
/bin/cp -p "$THEME_DIR/theme.json" "$PREPARED/theme.json"

DURATION="$($FFPROBE -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_PATH")"
TARGET_KBPS="$(/usr/bin/python3 -c 'import sys; d=float(sys.argv[1]); assert d > 0; print(max(700, min(8000, int(20*8*1024/d))))' "$DURATION")" || fail "Could not read a valid video duration."

"$FFMPEG" -hide_banner -loglevel error -y -i "$VIDEO_PATH" -map 0:v:0 \
  -vf "scale=w='min(1920,iw)':h='min(1080,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2,fps=${VIDEO_FPS}" \
  -c:v libx264 -preset veryfast -b:v "${TARGET_KBPS}k" -maxrate "${TARGET_KBPS}k" -bufsize "$((TARGET_KBPS * 2))k" \
  -pix_fmt yuv420p -movflags +faststart -an "$PREPARED/background.mp4"

"$FFMPEG" -hide_banner -loglevel error -y -i "$PREPARED/background.mp4" -frames:v 1 -q:v 2 "$PREPARED/poster.jpg"

VIDEO_BYTES="$(/usr/bin/stat -f %z "$PREPARED/background.mp4")"
[ "$VIDEO_BYTES" -le 25165824 ] || fail "Processed video exceeds the engine's 24 MB limit."

VIDEO_SKIN_NAME="$THEME_NAME" VIDEO_SKIN_FOCUS_X="$FOCUS_X" VIDEO_SKIN_FOCUS_Y="$FOCUS_Y" \
  /usr/bin/python3 - "$PREPARED/theme.json" <<'PY'
import json, os, pathlib, sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
x = float(os.environ["VIDEO_SKIN_FOCUS_X"])
y = float(os.environ["VIDEO_SKIN_FOCUS_Y"])
if not 0 <= x <= 1 or not 0 <= y <= 1:
    raise SystemExit("focus values must be between 0 and 1")
if os.environ.get("VIDEO_SKIN_NAME"):
    data["name"] = os.environ["VIDEO_SKIN_NAME"]
data["image"] = "poster.jpg"
data["video"] = "background.mp4"
art = data.setdefault("art", {})
art.update({"safeArea": "center", "taskMode": "ambient", "focusX": x, "focusY": y})
path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
PY

"$NODE" "$INJECTOR" --check-payload --theme-dir "$PREPARED" >/dev/null
verified_cdp_endpoint "$PORT" \
  || fail "The port is not a verified Codex loopback CDP endpoint; restart authorization is required."

/bin/cp -p "$PREPARED/background.mp4" "$THEME_DIR/background.mp4"
/bin/cp -p "$PREPARED/poster.jpg" "$THEME_DIR/poster.jpg"
/bin/cp -p "$PREPARED/theme.json" "$THEME_DIR/theme.json"

"$NODE" "$INJECTOR" --once --port "$PORT" --theme-dir "$THEME_DIR" --timeout-ms 20000
printf 'Codex Video Skin applied: %s bytes, focus %s %s\n' "$VIDEO_BYTES" "$FOCUS_X" "$FOCUS_Y"
