---
name: codex-skin-studio-complete
description: Install, operate, verify, or restore the complete macOS Codex skin engine and its bundled video and webpage skin Skills.
compatibility: macOS, official Codex Desktop, signed bundled Node.js 20+
---

# Codex Skin Studio Complete

Use this project when the user wants to install the shared macOS skin engine, apply one of the bundled skins, or use the bundled Skills to create a new video or webpage skin.

## Workflow

1. Read `使用说明.md`.
2. Install with `scripts/install-dream-skin-macos.sh --no-launch`.
3. For video work, read `skills/codex-video-skin/SKILL.md`.
4. For webpage work, read `skills/codex-web-skin-builder/SKILL.md`.
5. Apply through the installed shared engine.
6. Run `scripts/doctor-macos.sh --require-live` and `scripts/verify-dream-skin-macos.sh`.
7. Restore with `scripts/restore-dream-skin-macos.sh --restore-base-theme --restart-codex`.

## Guardrails

- Never modify the official `.app`, `app.asar`, signatures, API keys, or provider configuration.
- Only use the signed Node.js bundled with official Codex Desktop.
- Keep CDP on loopback and require verified Codex process ownership.
- Preserve native navigation, task content, composer controls, and keyboard focus.
- Do not claim success without live verification.
