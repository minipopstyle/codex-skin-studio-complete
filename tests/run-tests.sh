#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
NODE="${NODE:-/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node}"
if [ ! -x "$NODE" ]; then NODE="$(command -v node || true)"; fi
[ -x "$NODE" ] || { printf 'Node.js 20+ was not found.\n' >&2; exit 1; }

while IFS= read -r file; do /bin/bash -n "$file"; done < <(
  /usr/bin/find "$ROOT" -type f \( -name '*.sh' -o -name '*.command' \) \
    ! -path '*/release/*' -print
)
while IFS= read -r file; do "$NODE" --check "$file" >/dev/null; done < <(
  /usr/bin/find "$ROOT/scripts" "$ROOT/assets" -type f \( -name '*.mjs' -o -name '*.js' \) -print
)

if /usr/bin/grep -R -n -I -E --exclude='package-lock.json' --exclude='run-tests.sh' --exclude-dir='release' \
  '(/Users/[^/]+/(Desktop|Documents|Downloads)|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|sk-[A-Za-z0-9_-]{20,})' "$ROOT" >/dev/null 2>&1; then
  printf 'A personal path, private key, or token-like value remains in the public package.\n' >&2
  exit 1
fi
if /usr/bin/grep -R -n -I -E --exclude='package-lock.json' \
  '(cloudfront|onlinewebfonts|d8j0ntl)' "$ROOT/skins" >/dev/null 2>&1; then
  printf 'A skin preview still depends on a remote video or font host.\n' >&2
  exit 1
fi
if /usr/bin/grep -R -n -E '(writeFile|rename|copyFile|rm).*app\.asar' "$ROOT/scripts" >/dev/null; then
  printf 'A runtime script appears to mutate app.asar.\n' >&2
  exit 1
fi
/usr/bin/grep -F -q 'verified_cdp_endpoint "$PORT"' \
  "$ROOT/skills/codex-video-skin/scripts/apply_video_skin.sh"
/usr/bin/grep -F -q '/usr/bin/codesign --verify --deep --strict "$CODEX_BUNDLE"' \
  "$ROOT/scripts/common-macos.sh"

"$NODE" "$ROOT/scripts/injector.mjs" --check-payload >/dev/null
"$NODE" "$ROOT/tests/image-metadata.test.mjs"
"$NODE" "$ROOT/tests/injector-bootstrap.test.mjs"
"$NODE" "$ROOT/tests/renderer-inject.test.mjs"
"$NODE" "$ROOT/tests/theme-stage.test.mjs"

skin_count=0
for skin in "$ROOT"/skins/video/* "$ROOT"/skins/web/*; do
  [ -d "$skin" ] || continue
  "$NODE" "$ROOT/scripts/injector.mjs" --check-payload --theme-dir "$skin/theme" >/dev/null
  skin_count=$((skin_count + 1))
done
[ "$skin_count" -eq 6 ] || {
  printf 'Expected 6 bundled skins, found %s.\n' "$skin_count" >&2
  exit 1
}

printf 'PASS: clean macOS engine, two Skills, six skins, runtime guards, and renderer tests.\n'
