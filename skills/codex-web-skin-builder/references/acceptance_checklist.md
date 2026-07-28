# Web Skin Acceptance Checklist

## Package

- [ ] Folder name and `theme.json.id` are stable and slug-safe.
- [ ] `theme/` contains the referenced poster/video files.
- [ ] `安装物料.command`, `启动皮肤.command`, and `停止皮肤.command` exist and are executable.
- [ ] `scripts/` validates paths and does not write to the official app bundle.
- [ ] `node --check macos/assets/renderer-inject.js` passes.
- [ ] `npm run build` passes when `src/` exists.

## Renderer

- [ ] Custom DOM is created once and removed on route change/cleanup.
- [ ] Reconciliation is idempotent; no duplicate overlay or event listener.
- [ ] Native sidebar, title, project picker, composer, and task UI remain usable.
- [ ] Custom overlays do not capture clicks outside their own controls.
- [ ] Theme colors do not accidentally tint native conversation/composer surfaces.
- [ ] Leaving the homepage removes the custom hero and homepage video from settings/other routes.
- [ ] Returning to the homepage recreates the hero/video and restores mouse scrub interaction.
- [ ] The homepage detector uses a real visible home marker, not only a persistent sidebar icon.

## Video interaction

- [ ] `video.src` is present before the first scrub event.
- [ ] `video.duration` becomes finite without calling `play()`.
- [ ] Horizontal movement seeks forward and backward.
- [ ] `currentTime` is clamped to the video duration.
- [ ] `seeked` drains the newest target without seek flooding.
- [ ] Autoplay is off.
- [ ] Double-click behavior exists only when explicitly requested.
- [ ] The staged hero sequence is verified: title, subtitle, then interactive control.

## Live apply

- [ ] Preflight passes.
- [ ] Port `9341` and the renderer target are verified.
- [ ] Injector reports `installed: true`.
- [ ] A screenshot or equivalent visual check was inspected.
- [ ] No official app files, keys, proxy settings, or relay settings changed.

## Responsive and route regression

- [ ] The intended narrow breakpoint hides or preserves the native sidebar deliberately.
- [ ] The main surface fills the viewport when the sidebar is hidden.
- [ ] Opening the native composer does not overlap the hero at narrow or short window sizes.
- [ ] A settings-page screenshot is clean; no homepage copy or video remains.
