#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
VERSION="$(/usr/bin/tr -d '[:space:]' < "$ROOT/VERSION")"
OUTPUT="${1:-$HOME/Desktop/Codex Skin Studio Complete.zip}"
TMP="$(/usr/bin/mktemp -d /tmp/codex-skin-client.XXXXXX)"
CLIENT_ROOT="$TMP/Codex Skin Studio Complete"
ENGINE="$CLIENT_ROOT/.codex-dream-skin-studio"
trap '/bin/rm -rf "$TMP"' EXIT

"$ROOT/tests/run-tests.sh"
/bin/mkdir -p "$ENGINE"
/usr/bin/rsync -a \
  --exclude '.git/' \
  --exclude '.DS_Store' \
  --exclude '._*' \
  --exclude 'node_modules/' \
  --exclude 'dist/' \
  --exclude 'build/' \
  --exclude 'release/' \
  --exclude 'runtime/' \
  "$ROOT/" "$ENGINE/"

/usr/bin/printf '%s\n' \
  '#!/bin/bash' \
  'set -euo pipefail' \
  'ROOT="$(cd "$(dirname "$0")" && pwd -P)"' \
  'exec "$ROOT/.codex-dream-skin-studio/scripts/install-dream-skin-macos.sh"' \
  > "$CLIENT_ROOT/安装 Codex Skin Studio.command"

/usr/bin/printf '%s\n' \
  "Codex Skin Studio Complete $VERSION" \
  '' \
  '推荐方式：把完整 ZIP、你的素材和“给 Codex 的部署提示词.md”一起发给 Codex。' \
  '' \
  '手动方式：双击“安装 Codex Skin Studio.command”。' \
  '' \
  '隐藏目录 .codex-dream-skin-studio 是完整引擎，不要删除或只复制其中的 CSS。' \
  > "$CLIENT_ROOT/使用说明.txt"

/bin/cp "$ROOT/使用说明.md" "$CLIENT_ROOT/完整使用说明.md"
/bin/cp "$ROOT/CLIENT_DEPLOY_PROMPT.md" "$CLIENT_ROOT/给 Codex 的部署提示词.md"
/bin/chmod 755 "$CLIENT_ROOT/安装 Codex Skin Studio.command"
/bin/chmod 755 "$ENGINE"/*.command "$ENGINE"/scripts/*.sh "$ENGINE"/tests/*.sh
/bin/chmod 755 "$ENGINE"/skills/codex-video-skin/scripts/*.sh
/bin/chmod 755 "$ENGINE"/skills/codex-web-skin-builder/scripts/*.py
/usr/bin/xattr -cr "$CLIENT_ROOT"
/usr/bin/find "$CLIENT_ROOT" -type f \( -name '.DS_Store' -o -name '._*' \) -delete
/bin/mkdir -p "$(dirname "$OUTPUT")"
/bin/rm -f "$OUTPUT"
COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --keepParent --norsrc --noextattr "$CLIENT_ROOT" "$OUTPUT"
SHA256="$(/usr/bin/shasum -a 256 "$OUTPUT" | /usr/bin/awk '{print $1}')"
if [ "$(cd "$(dirname "$OUTPUT")" && pwd -P)" = "$ROOT/release" ]; then
  {
    for archive in "$ROOT"/release/*.zip; do
      /usr/bin/shasum -a 256 "$archive" | /usr/bin/awk -v name="$(basename "$archive")" '{print $1 "  " name}'
    done
    for skill in "$ROOT"/release/skills/*.skill; do
      [ -f "$skill" ] || continue
      /usr/bin/shasum -a 256 "$skill" | /usr/bin/awk -v name="skills/$(basename "$skill")" '{print $1 "  " name}'
    done
  } > "$ROOT/release/SHA256SUMS.txt"
fi
/usr/bin/printf 'Created %s\nSHA-256 %s\n' "$OUTPUT" "$SHA256"
