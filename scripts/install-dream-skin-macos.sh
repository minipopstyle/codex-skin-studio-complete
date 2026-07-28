#!/bin/bash

set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd -P)/common-macos.sh"

PORT=9341
CREATE_LAUNCHERS="true"
LAUNCH_AFTER_INSTALL="true"
IN_PLACE="false"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --port) PORT="${2:-}"; shift 2 ;;
    --no-launchers) CREATE_LAUNCHERS="false"; shift ;;
    --no-launch) LAUNCH_AFTER_INSTALL="false"; shift ;;
    --in-place) IN_PLACE="true"; shift ;;
    *) fail "Unknown installer argument: $1" ;;
  esac
done
case "$PORT" in ''|*[!0-9]*) fail "Invalid port: $PORT" ;; esac
[ "$PORT" -ge 1024 ] && [ "$PORT" -le 65535 ] || fail "Port must be between 1024 and 65535."

deploy_project() {
  local temporary="$INSTALL_ROOT.installing.$$"
  local previous="$INSTALL_ROOT.previous.$$"
  /bin/rm -rf "$temporary"
  /bin/mkdir -p "$temporary"
  /usr/bin/rsync -a \
    --exclude '.git/' \
    --exclude '.DS_Store' \
    --exclude 'release/' \
    --exclude 'runtime/' \
    "$PROJECT_ROOT/" "$temporary/"
  /bin/chmod 700 "$temporary"/*.command "$temporary"/scripts/*.sh 2>/dev/null || true
  if [ -e "$INSTALL_ROOT" ]; then /bin/mv "$INSTALL_ROOT" "$previous"; fi
  if ! /bin/mv "$temporary" "$INSTALL_ROOT"; then
    [ -e "$previous" ] && /bin/mv "$previous" "$INSTALL_ROOT"
    fail "Could not install the project at $INSTALL_ROOT"
  fi
  /bin/rm -rf "$previous"
}

if [ "$IN_PLACE" = "false" ] && [ "$PROJECT_ROOT" != "$INSTALL_ROOT" ]; then
  /bin/mkdir -p "$(dirname "$INSTALL_ROOT")"
  deploy_project
  install_args=(--in-place --port "$PORT")
  [ "$CREATE_LAUNCHERS" = "true" ] || install_args+=(--no-launchers)
  [ "$LAUNCH_AFTER_INSTALL" = "true" ] || install_args+=(--no-launch)
  exec "$INSTALL_ROOT/scripts/install-dream-skin-macos.sh" "${install_args[@]}"
fi

discover_codex_app
require_macos_runtime
ensure_state_root
codex_is_running && fail "Close Codex before installation so config.toml cannot be rewritten while the app is saving it."
if [ ! -f "$THEME_DIR/theme.json" ]; then
  /bin/mkdir -p "$THEME_DIR"
  /bin/chmod 700 "$THEME_DIR"
  /bin/cp "$PROJECT_ROOT/assets/theme.json" "$THEME_DIR/theme.json"
  /bin/cp "$PROJECT_ROOT/assets/portal-hero.png" "$THEME_DIR/portal-hero.png"
  /bin/chmod 600 "$THEME_DIR/theme.json" "$THEME_DIR/portal-hero.png"
fi
[ -f "$CONFIG_PATH" ] || fail "Codex config not found: $CONFIG_PATH. Launch Codex once, close it, and rerun the installer."
"$NODE" "$INJECTOR" --check-payload --theme-dir "$THEME_DIR" >/dev/null
"$NODE" "$SCRIPT_DIR/theme-config.mjs" install "$CONFIG_PATH" "$THEME_BACKUP_PATH"

VIDEO_SKILL_SOURCE="$PROJECT_ROOT/skills/codex-video-skin"
VIDEO_SKILL_TARGET="$HOME/.codex/skills/codex-video-skin"
[ -f "$VIDEO_SKILL_SOURCE/SKILL.md" ] || fail "Bundled codex-video-skin Skill is missing."
/bin/mkdir -p "$VIDEO_SKILL_TARGET"
/usr/bin/rsync -a --delete "$VIDEO_SKILL_SOURCE/" "$VIDEO_SKILL_TARGET/"
/bin/chmod 700 "$VIDEO_SKILL_TARGET/scripts/"*.sh

WEB_SKILL_SOURCE="$PROJECT_ROOT/skills/codex-web-skin-builder"
WEB_SKILL_TARGET="$HOME/.codex/skills/codex-web-skin-builder"
[ -f "$WEB_SKILL_SOURCE/SKILL.md" ] || fail "Bundled codex-web-skin-builder Skill is missing."
/bin/mkdir -p "$WEB_SKILL_TARGET"
/usr/bin/rsync -a --delete "$WEB_SKILL_SOURCE/" "$WEB_SKILL_TARGET/"
/bin/chmod 700 "$WEB_SKILL_TARGET/scripts/"*.py

shell_quote() {
  "$NODE" -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1"
}

write_launcher() {
  local target="$1"
  local command="$2"
  if [ -e "$target" ] && ! /usr/bin/grep -q '^# CodexDreamSkinStudio launcher$' "$target" 2>/dev/null; then
    fail "Refusing to overwrite an unrelated Desktop file: $target"
  fi
  /usr/bin/printf '%s\n' \
    '#!/bin/bash' \
    '# CodexDreamSkinStudio launcher' \
    'set -e' \
    "$command" > "$target"
  /bin/chmod 700 "$target"
}

if [ "$CREATE_LAUNCHERS" = "true" ]; then
  /bin/mkdir -p "$HOME/Desktop"
  start_script="$(shell_quote "$SCRIPT_DIR/start-dream-skin-macos.sh")"
  customize_script="$(shell_quote "$SCRIPT_DIR/customize-theme-macos.sh")"
  verify_script="$(shell_quote "$SCRIPT_DIR/verify-dream-skin-macos.sh")"
  restore_script="$(shell_quote "$SCRIPT_DIR/restore-dream-skin-macos.sh")"
  screenshot="$(shell_quote "$HOME/Desktop/Codex Skin Studio Verification.png")"
  write_launcher "$HOME/Desktop/Codex Skin Studio.command" "exec $start_script --port $PORT --prompt-restart"
  write_launcher "$HOME/Desktop/Codex Skin Studio - Customize.command" "exec $customize_script"
  write_launcher "$HOME/Desktop/Codex Skin Studio - Verify.command" "$verify_script --screenshot $screenshot && /usr/bin/open $screenshot"
  write_launcher "$HOME/Desktop/Codex Skin Studio - Restore.command" "exec $restore_script --restore-base-theme --restart-codex"
fi

printf 'Codex Skin Studio %s installed at %s for Codex %s using its signed Node.js %s.\n' \
  "$SKIN_VERSION" "$PROJECT_ROOT" "$CODEX_VERSION" "$NODE_VERSION"
printf 'Use the Desktop launchers to customize, start, verify, or restore the official appearance.\n'
printf 'Bundled skin packages are available under %s/skins.\n' "$PROJECT_ROOT"
printf 'Video Skill installed at %s. Upload a video and ask Codex to apply it as a video skin.\n' "$VIDEO_SKILL_TARGET"
printf 'Web Skin Builder installed at %s.\n' "$WEB_SKILL_TARGET"

if [ "$LAUNCH_AFTER_INSTALL" = "true" ]; then
  "$SCRIPT_DIR/start-dream-skin-macos.sh" --port "$PORT" --prompt-restart
fi
