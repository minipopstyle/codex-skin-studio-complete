#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
OUTPUT_DIR="${1:-$ROOT/release/skills}"

/bin/mkdir -p "$OUTPUT_DIR"
for skill in codex-video-skin codex-web-skin-builder; do
  source="$ROOT/skills/$skill"
  [ -f "$source/SKILL.md" ] || { /usr/bin/printf 'Missing Skill: %s\n' "$source/SKILL.md" >&2; exit 1; }
  output="$OUTPUT_DIR/$skill.skill"
  /bin/rm -f "$output"
  COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --keepParent --norsrc --noextattr "$source" "$output"
done

/usr/bin/printf 'Created Skill packages in %s\n' "$OUTPUT_DIR"
