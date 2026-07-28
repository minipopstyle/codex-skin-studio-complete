#!/bin/bash
set -euo pipefail

ENGINE="$HOME/.codex/codex-dream-skin-studio/scripts/restore-dream-skin-macos.sh"
[ -x "$ENGINE" ] || { echo "未找到 Skin Studio 引擎：$ENGINE" >&2; exit 1; }
exec "$ENGINE" "$@"
