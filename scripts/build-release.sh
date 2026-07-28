#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
VERSION="$(/usr/bin/tr -d '[:space:]' < "$ROOT/VERSION")"
RELEASE_DIR="$ROOT/release"
ARCHIVE="$RELEASE_DIR/codex-skin-studio-complete-v$VERSION.zip"
TMP="$(/usr/bin/mktemp -d /tmp/codex-skin-studio-release.XXXXXX)"
trap '/bin/rm -rf "$TMP"' EXIT

if [ "${1:-}" != "--skip-tests" ]; then "$ROOT/tests/run-tests.sh"; fi

/bin/mkdir -p "$TMP/codex-skin-studio-complete" "$RELEASE_DIR"
/usr/bin/rsync -a \
  --exclude '.git/' \
  --exclude '.DS_Store' \
  --exclude '._*' \
  --exclude 'node_modules/' \
  --exclude 'dist/' \
  --exclude 'build/' \
  --exclude 'release/' \
  "$ROOT/" "$TMP/codex-skin-studio-complete/"

/usr/bin/find "$TMP/codex-skin-studio-complete" -type f \( -name '.DS_Store' -o -name '._*' \) -delete
/bin/chmod 755 "$TMP/codex-skin-studio-complete"/*.command
/bin/chmod 755 "$TMP/codex-skin-studio-complete"/scripts/*.sh "$TMP/codex-skin-studio-complete"/tests/*.sh
/bin/rm -f "$ARCHIVE"
COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --keepParent --norsrc --noextattr \
  "$TMP/codex-skin-studio-complete" "$ARCHIVE"
"$ROOT/scripts/build-skill-packages.sh" "$RELEASE_DIR/skills"
SHA256="$(/usr/bin/shasum -a 256 "$ARCHIVE" | /usr/bin/awk '{print $1}')"
{
  /usr/bin/printf '%s  %s\n' "$SHA256" "$(basename "$ARCHIVE")"
  for skill in "$RELEASE_DIR"/skills/*.skill; do
    /usr/bin/shasum -a 256 "$skill" | /usr/bin/awk -v name="skills/$(basename "$skill")" '{print $1 "  " name}'
  done
} > "$RELEASE_DIR/SHA256SUMS.txt"
/usr/bin/printf 'Created %s\nSHA-256 %s\n' "$ARCHIVE" "$SHA256"
