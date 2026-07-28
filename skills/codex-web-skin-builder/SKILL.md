---
name: codex-web-skin-builder
description: Build, revise, validate, package, and optionally apply interactive Codex webpage skins from natural-language web briefs using the shared macOS Skin Studio renderer. Use when the user asks to make a Codex webpage skin, interactive homepage skin, React/Vite skin, or professional switchable skin bundle.
compatibility: macOS, Node.js 20+, npm, installed Codex Skin Studio; ffmpeg/ffprobe only when a local video asset must be processed.
---

# Codex Web Skin Builder

Turn a natural-language webpage brief into a reusable Codex homepage skin package. This skill combines Inversion, Generator, Pipeline, and Reviewer patterns.

## Scope

Build two coordinated layers when the skin needs custom UI:

- `src/`: standalone React/Vite preview and fast visual iteration.
- `theme/`: the theme data consumed by the shared renderer.

The shared macOS engine currently supports `homepageStyle=default`, `homepageStyle=velorah`, and `homepageStyle=mainframe`. Do not copy or overwrite the engine inside a skin package. Do not modify the official app bundle, `app.asar`, signatures, API keys, proxy settings, or relay configuration.

## Step 1 — Normalize the brief

Read `references/input_schema.md`. Extract the skin name, visual direction, copy, asset source, interaction model, native UI that must remain usable, and whether the user wants a package only or an active switch.

Ask only for missing information that changes implementation. Reasonable defaults:

- package only; do not activate unless the user says “启动/替换/应用”;
- preserve native sidebar, title, composer, project picker, and task controls;
- use the provided video as an ambient background with `muted`, `playsInline`, `preload="auto"`, and no autoplay;
- if the brief says mouse-scrub, listen on `window` and seek by horizontal delta; do not invent a special hotspot or double-click behavior;
- if the brief does not ask for custom UI, prefer an asset-only video skin.

## Step 2 — Inspect before writing

Look for an existing skin package, shared scripts, installed dependencies, and the current Skin Studio engine. Reuse existing files and patterns. Do not create a second renderer or a new package when the workspace already contains the target skin.

For custom webpage work, read `references/reproduction_playbook.md` after `references/input_schema.md`. It records the tested differences between asset-only/video skins and custom webpage skins, plus route, native UI, video, responsive, and CDP failure modes.

Choose the smallest architecture:

1. Asset-only: `theme/` plus existing video-skin scripts.
2. Supported webpage style: `src/` preview plus `theme.json` using `homepageStyle=velorah` or `homepageStyle=mainframe`.

Choose supported webpage mode when the brief matches Velorah or Mainframe behavior. If the brief requires a new renderer contract, stop and report that the shared engine must be extended before packaging it.

## Step 3 — Build the skin

Read `references/architecture.md` before touching the renderer. Keep the preview and injected version behaviorally aligned.

For custom UI:

1. Implement the visual layout in `src/` with the existing React/Vite/Tailwind setup when present.
2. Keep the injected behavior within the existing shared renderer contract; do not fork `renderer-inject.js` or `dream-skin.css` into the package.
3. Keep injected UI non-blocking by default: the root overlay uses `pointer-events: none`; only explicitly interactive descendants use `pointer-events: auto`.
4. Keep the native Codex shell readable and interactive unless the brief explicitly asks to replace it.
5. Load a scrub-controlled video source before listening for mouse movement. Seeking must work without first playing the video.
6. Use one queued seek path: update a target time on mouse movement, seek only when idle, and continue from `seeked` when the target moved.
7. Treat the homepage as a lifecycle, not a permanent overlay: detect a real visible homepage marker, remove custom DOM/video when leaving home, and reset/rebuild video and seek state when returning.
8. Add responsive ownership rules for native sidebar visibility, main-surface width, and composer clearance before tuning hero positions. Fixed hero and fixed composer layouts must be tested together.

For local video assets, use the installed `codex-video-skin` helper or the package's existing asset installer. Do not hand-roll a second ffmpeg pipeline unless the helper cannot support the requested format.

## Step 4 — Create the professional package

The finished package should contain:

```text
Codex网页皮肤-Name/
├── src/                         # optional standalone preview
├── theme/                       # theme.json, poster.jpg, background.mp4
├── scripts/
│   ├── install-assets.sh
│   ├── start.sh
│   └── stop.sh
├── 安装物料.command
├── 启动皮肤.command
├── 停止皮肤.command
├── package.json                 # required when src/ is present
└── README.md
```

Use `scripts/package_web_skin.py` to create a clean distributable copy. It excludes `node_modules`, build output, caches, and `.DS_Store`; it never deletes an existing destination.

## Step 5 — Validate before activation

Run:

```bash
python3 scripts/validate_web_skin.py /absolute/path/to/skin
```

Then run the smallest relevant checks:

```bash
npm run build                 # when package.json and src/ exist
```

Do not proceed if validation fails. Fix the package, rerun validation, and report the exact failed check if blocked.

## Step 6 — Install or apply

Package-only requests stop after validation and packaging. For an explicit apply request:

1. Run the package's `安装物料.command` or `scripts/install-assets.sh`.
2. Run `codex-video-skin/scripts/apply_video_skin.sh --check` when video support is involved.
3. Apply through the installed Skin Studio engine. If port `9341` is unavailable, ask for restart authorization before restarting Codex.
4. Never claim live success from a file copy alone; verify the CDP injection result.

## Step 7 — Acceptance review

Read `references/acceptance_checklist.md`. Verify the home route visually and test the requested interaction sequence. For mouse-scrub skins, verify:

- the video has a source and finite duration before the first seek;
- moving horizontally changes the target time in both directions;
- a seek in flight does not flood `currentTime` assignments;
- autoplay and unrequested double-click playback are absent;
- native sidebar, title, composer, project picker, and task controls remain usable;
- neutral theme colors do not tint native dialogs/composers unexpectedly.

## Output

Report:

1. package path;
2. generated files and asset source;
3. validation/build result;
4. whether the active Codex skin was changed;
5. live injection and visual verification status;
6. anything intentionally skipped and the condition for adding it.

## Gotchas

- A React/Vite preview is not automatically a Codex skin. The shared macOS renderer is the active runtime path.
- `theme.json` selects only the renderer styles supported by the installed engine.
- A scrub video must load `src` and metadata without autoplay; lazy-loading `src` only inside `play()` makes the first mouse interaction a no-op.
- Do not restrict a brief-defined `window` mouse interaction to a hardcoded “subject area”; that changes the requested interaction contract.
- Existing Skin Studio double-click playback is generic behavior. Disable it for a webpage skin when the brief specifies scrub-only interaction.
- Theme background/panel colors flow into native Codex surfaces. Use neutral values unless the brief intentionally themes those surfaces.
- A stale state file or running Codex without CDP is not proof that the renderer failed. Check port `9341`, injector logs, and the actual target before changing code.
- Do not use a persistent sidebar home icon as the homepage detector; it can remain present on settings and cause hero text/video leakage.
- A `body`-attached hero must be explicitly removed outside the homepage. Returning from settings requires video recreation and reset of `prevX`, target time, and seek state or mouse interaction can appear frozen.
- A narrow-window media query for custom content does not hide the native sidebar by itself. Add an explicit breakpoint rule and test the main surface at CSS-pixel width, not only screenshot width.
- Fixed bottom composer and fixed bottom hero content overlap on short windows. Reserve space while the composer is open, preferably with bounded `clamp()` clearance and a real screenshot check.
- Keep preview and injected runtime behaviorally aligned, but never treat a passing Vite preview as proof that the Codex renderer is fixed.
