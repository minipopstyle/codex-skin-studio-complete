# Web Skin Architecture

## Two runtimes

The standalone preview and the Codex injection are related but not interchangeable:

```text
user brief
  ├─ src/        React/Vite preview and iteration
  ├─ engine/    injected DOM/CSS/JS used by Codex
  └─ theme/     poster, video, theme.json
```

`src/` can use React state and Tailwind. `engine/` runs inside the Codex renderer and should stay dependency-free: DOM APIs, CSS, and small local helpers only. Keep the two layers synchronized, but do not ship a Vite dev server as the active Codex runtime.

## Asset-only versus custom webpage

### Asset-only video skin

Reuse the installed renderer. Package `background.mp4`, `poster.jpg`, and `theme.json`; do not patch the engine. This is the safest and smallest path.

### Custom webpage skin

Add a named `homepageStyle` accepted by the installed injector, then add a matching renderer branch and CSS selectors. The branch should:

- create and remove its own DOM root;
- be idempotent across route and mutation reconciliation;
- clean up event listeners, timers, object URLs, and video elements;
- preserve native Codex controls outside the custom visual layer;
- degrade to the native route if the homepage is not present.

## Mouse-scrub contract

For a brief that specifies horizontal mouse scrub:

1. Create the video with `muted`, `playsInline`, `preload="auto"`, and `autoplay=false`.
2. Set `src` before the first mouse event so metadata can load without playback.
3. On `window.mousemove`, store `prevX`, compute the horizontal delta, and add the normalized time offset.
4. Clamp the target to `0..duration`.
5. If no seek is active, assign `currentTime`; otherwise keep only the newest target.
6. On `seeked`, seek again only when the target has moved.
7. Remove generic double-click playback when the brief says scrub-only.

Do not use `requestAnimationFrame` reconciliation for the whole document; the Skin Studio engine relies on a 240ms timer debounce to avoid a per-frame mutation loop.

## Interaction boundaries

The custom overlay should normally be transparent to pointer events:

```css
.custom-skin-root { pointer-events: none; }
.custom-skin-root button,
.custom-skin-root a,
.custom-skin-root [data-interactive] { pointer-events: auto; }
```

If a custom UI occupies the same region as the native sidebar or header, move it inside the main surface or remove it. Do not “fix” overlap by disabling native navigation globally.

## Color boundaries

`colors.background`, `colors.panel`, and related theme variables can style native Codex surfaces. Use neutral light/dark values when the desired color belongs only to the wallpaper. A vivid accent should not make the composer or conversation panel unusable unless that is explicitly requested.
