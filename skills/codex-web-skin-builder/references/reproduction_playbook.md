# Reproduction Playbook and Field Notes

This reference records the reusable lessons from the Mainframe webpage skin. Read it when a brief asks for a custom Codex homepage, mouse-scrub video, staged hero copy, native composer integration, or responsive behavior.

## 1. What this kind of skin actually is

There are two different products hiding behind the word “skin”:

### Asset-only video skin

- Reuses the installed Skin Studio renderer.
- Provides `theme.json`, `poster.jpg`, and `background.mp4`.
- Keeps the homepage layout and interactions supplied by the generic engine.
- Is the smallest and safest option when the user only wants a video/background treatment.

### Custom webpage skin

- Uses the same theme/assets pipeline but adds a named `homepageStyle` branch in the injected renderer.
- Has two synchronized implementations: `src/` for the React/Vite/TypeScript preview and `engine/` for the dependency-free injected DOM/CSS/JS runtime.
- Must reconcile its DOM on route changes and clean up its own timers, listeners, videos, and object URLs.

The React preview is not the active Codex UI. A preview can look correct while the installed `engine/` path is still wrong.

## 2. Mainframe technical stack

### Preview layer

- React 19, Vite 7, TypeScript 5.8, and Tailwind CSS 4.
- Native browser `<video>` with `muted`, `playsInline`, `preload="auto"`, and no autoplay.
- React state for staged typewriter copy, composer-open state, and preview-only controls.

### Runtime layer

- A dependency-free injected JavaScript IIFE in the shared macOS renderer.
- Scoped CSS in the shared `macos/assets/dream-skin.css` under `html.codex-dream-skin` and `data-dream-homepage-style="mainframe"`.
- Browser primitives only: DOM APIs, `MutationObserver`, `ResizeObserver`, `matchMedia`, timers, media events, CSS media queries, and CSS `:has()`.
- The Node ESM injector communicates with the Codex renderer through local CDP port `9341` and validates loopback targets before evaluation.
- `theme/theme.json` carries copy, palette, asset names, homepage style, art focus, and behavior metadata.
- `scripts/install-assets.sh` copies theme assets and runtime files into the Skin Studio state/engine directories.

### Visual and interaction layer

- Background video is scrubbed by horizontal `window.mousemove` delta.
- The seek loop has one in-flight seek: store the newest target, assign `currentTime` only when idle, and drain the newest target on `seeked`.
- Main title types first; subtitle types second; the composer button becomes visible only after both complete.
- The button toggles the native Codex composer instead of recreating send, attachment, voice, keyboard, or submission logic.
- The custom overlay defaults to `pointer-events: none`; only its button is interactive.
- The button uses liquid-glass CSS primitives: translucent gradient, `backdrop-filter`, inset highlights, border, shadow, hover lift, and active scale.
- At narrow widths the native sidebar is hidden and the main surface is widened. When the composer opens, the hero content receives responsive bottom clearance via `clamp()` so it cannot overlap the composer.

## 3. Reproduction flow

1. Normalize the brief into copy, visual direction, asset source, interaction contract, native UI boundary, and delivery mode.
2. Inspect the target skin, shared scripts, installed engine, and current theme state before editing.
3. Decide asset-only versus custom webpage. Choose custom webpage only when the brief needs custom copy, typewriter, controls, staged motion, or novel interaction.
4. Define the route contract before writing hero markup:
   - the homepage has a real visible marker such as `[data-feature="game-source"]`;
   - non-home pages must not contain custom hero DOM;
   - leaving home destroys the custom hero and video;
   - returning home recreates the video, resets mouse/seek state, and recreates the hero once.
5. Implement the preview in `src/`, then port only required behavior to `engine/`. Keep copy and sequencing aligned.
6. Load the video `src` before the first mouse event. Do not defer the source until `play()` for a scrub-only experience.
7. Reuse native Codex controls. Add a wrapper class to show/hide them, focus the real textarea/contenteditable element, and let Codex own submission.
8. Add responsive rules for sidebar visibility, main-surface width, hero safe area, and composer clearance before tuning hero positions.
9. Validate with `validate_web_skin.py`, `node --check`, and `npm run build`.
10. Install the package. If live application is requested, verify CDP port `9341`, injector result, and a screenshot; a file copy is not live proof.

## 4. What Mainframe added beyond the original/asset-only approach

- A stateful hero instead of a passive video wallpaper.
- A two-stage typewriter sequence with a delayed interactive control.
- A native-composer bridge: the skin supplies the reveal affordance while Codex keeps all composer behavior.
- Mouse-driven video scrubbing without playback or double-click conflict.
- Route-aware teardown/rebuild so settings and other pages are not polluted by homepage DOM.
- Responsive ownership rules for the sidebar, hero, and composer rather than letting fixed overlays compete for the same space.
- A preview/runtime parity model: React is for iteration, injected DOM/CSS/JS is the production path.

## 5. Codex homepage boundaries found during testing

### Route and lifecycle

- Do not detect the homepage from a sidebar “home” icon alone. That icon can exist while settings or another route is active.
- Detect a real visible homepage marker and verify its bounding box. The Mainframe failure mode was hero text leaking into settings because route detection treated a non-home route as home.
- A `body`-attached overlay survives route changes unless explicitly removed. Make non-home removal a first-class branch.
- Returning to home needs more than recreating markup: destroy/recreate the video and reset `prevX`, target time, and seek state. Otherwise the video can appear frozen after visiting settings.

### Native UI and layering

- Native sidebar, top bar, settings, project picker, and composer are owned by Codex. A custom overlay must not cover their hit areas.
- `z-index` does not solve pointer-event conflicts. Keep the root transparent to pointer input and opt in only the intended button.
- Never render a custom input box when the requested behavior can reveal the native composer.
- Neutral theme colors are important: vivid wallpaper colors can unintentionally tint native dialogs and composers.

### Video interaction

- A scrub-only video must have `src` before the first mouse move and must not depend on a prior double-click/play/pause cycle.
- Generic double-click playback conflicts with webpage-skin mouse interaction; disable it for `homepageStyle="mainframe"` unless explicitly requested.
- A `mousemove` handler without queued seeks can flood `currentTime` and make interaction stutter.
- Respect `prefers-reduced-motion`; remove or stop the video interaction when it is active.

### Responsive behavior

- A custom mobile media query does not automatically hide the native sidebar. Add an explicit narrow-width rule and widen the main surface.
- Fixed bottom composer plus fixed bottom hero content overlap on short/narrow windows. Reserve composer clearance while it is open; `clamp()` is a practical baseline, but verify against the actual composer height.
- Test CSS viewport width, not just physical screenshot width; Retina screenshots can be twice the CSS pixel width.
- CSS `:has()` is used for composer visibility and route-safe display. Confirm the embedded Chromium supports it before making it a critical gate.

### Runtime and activation

- CDP port `9341` can be unavailable even when a stale theme state file exists. Do not claim live success from copied files.
- Restart authorization is separate from package editing. If the port is unavailable, report the package/install result and request restart before forcing a process change.
- The installed injector is the source of truth for live behavior; reinstall the edited `engine/` files after changes.

## 6. Regression matrix

| Case | Expected result |
| --- | --- |
| Fresh homepage | Video has a source; hero appears once; title/subtitle sequence is staged. |
| Horizontal mouse movement | Video seeks forward and backward without autoplay or double-click. |
| Button before animation completes | Button is hidden/non-interactive. |
| Composer open/close | Native composer appears, receives focus, and hero clears it on narrow windows. |
| Resize across narrow breakpoint | Sidebar hides at the intended breakpoint; main surface fills the viewport. |
| Navigate to settings | Mainframe hero and homepage video disappear; settings is clean. |
| Return from settings | Hero and video recreate; mouse scrub works after metadata is available. |
| Reduced motion | Video/animation behavior degrades without forced motion. |
| Live apply | CDP target, injector result, and screenshot are verified separately. |
