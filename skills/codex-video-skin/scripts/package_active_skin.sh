#!/bin/bash
set -euo pipefail

fail() { printf 'Codex Video Skin: %s\n' "$*" >&2; exit 1; }
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
STATE_ROOT="${CODEX_VIDEO_SKIN_STATE_ROOT:-$HOME/Library/Application Support/CodexDreamSkinStudio}"
DEST="${1:-}"
NAME="${2:-}"
[ -n "$DEST" ] || fail "Usage: package_active_skin.sh /absolute/output/folder [display name]"
case "$DEST" in /*) ;; *) fail "Output folder must be absolute." ;; esac
[ ! -e "$DEST" ] || fail "Output folder already exists: $DEST"
for file in background.mp4 poster.jpg theme.json; do
  [ -f "$STATE_ROOT/theme/$file" ] || fail "Active theme is missing $file"
done
NAME="${NAME:-$(/usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8")).get("name", "Codex 视频皮肤"))' "$STATE_ROOT/theme/theme.json")}"
/bin/mkdir -p "$DEST"
/bin/cp -R "$ROOT/templates/package/." "$DEST/"
/bin/mv "$DEST/install.command" "$DEST/安装物料.command"
/bin/mv "$DEST/start.command" "$DEST/启动皮肤.command"
/bin/mv "$DEST/stop.command" "$DEST/停止皮肤.command"
/bin/cp -p "$STATE_ROOT/theme/background.mp4" "$STATE_ROOT/theme/poster.jpg" "$STATE_ROOT/theme/theme.json" "$DEST/theme/"
NAME="$NAME" /usr/bin/python3 -c 'import json,os,sys; p=sys.argv[1]; d=json.load(open(p,encoding="utf-8")); d["name"]=os.environ["NAME"]; open(p,"w",encoding="utf-8").write(json.dumps(d,ensure_ascii=False,indent=2)+"\n")' "$DEST/theme/theme.json"
NAME="$NAME" /usr/bin/python3 -c 'from pathlib import Path; import os,sys; p=Path(sys.argv[1]); p.write_text(p.read_text(encoding="utf-8").replace("@SKIN_NAME@",os.environ["NAME"]))' "$DEST/README.md"
/bin/chmod +x "$DEST"/*.command "$DEST"/scripts/*.sh
printf 'Codex Video Skin packaged: %s\n' "$DEST"
