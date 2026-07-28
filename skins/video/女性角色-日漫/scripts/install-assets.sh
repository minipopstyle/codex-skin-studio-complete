#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
THEME_DIR="${CODEX_VIDEO_SKIN_STATE_ROOT:-$HOME/Library/Application Support/CodexDreamSkinStudio}/theme"

[ -f "$ROOT/theme/background.mp4" ] || { echo "缺少 background.mp4" >&2; exit 1; }
[ -f "$ROOT/theme/poster.jpg" ] || { echo "缺少 poster.jpg" >&2; exit 1; }
[ -f "$ROOT/theme/theme.json" ] || { echo "缺少 theme.json" >&2; exit 1; }

mkdir -p "$THEME_DIR"
chmod 700 "$THEME_DIR"
cp -p "$ROOT/theme/background.mp4" "$THEME_DIR/background.mp4"
cp -p "$ROOT/theme/poster.jpg" "$THEME_DIR/poster.jpg"
cp -p "$ROOT/theme/theme.json" "$THEME_DIR/theme.json"
chmod 600 "$THEME_DIR/background.mp4" "$THEME_DIR/poster.jpg" "$THEME_DIR/theme.json"
echo "已安装皮肤物料：$THEME_DIR"
