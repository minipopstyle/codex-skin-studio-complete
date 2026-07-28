# Web Skin Brief Schema

Use this as an extraction checklist, not a form the user must fill verbatim.

## Required fields

- `name`: human-facing skin name and filesystem slug.
- `goal`: what the homepage should feel like and what it should help the user do.
- `visual_direction`: palette, typography, density, motion, image/video treatment.
- `copy`: logo, navigation, hero copy, labels, email/contact text.
- `asset_source`: local file, attached file, remote URL, or asset-free.
- `interaction`: exact trigger and response, including whether playback, scrub, click, hover, keyboard, or touch is intended.
- `native_ui_boundary`: Codex elements that must remain visible and interactive.
- `delivery`: package only, preview, or apply to the active Codex skin.

## Defaults

When omitted, infer:

```yaml
delivery: package
native_ui_boundary: preserve sidebar, title, project picker, composer, and task controls
video: muted, playsInline, preload=auto, no autoplay
overlay_pointer_events: none except explicit controls
theme_appearance: auto
focus: center unless the subject is clearly off-center
```

## Interaction notation

Convert vague phrases into an explicit contract before coding:

```yaml
trigger: window mousemove
input: currentX - prevX
mapping: delta / window.innerWidth * sensitivity * video.duration
output: clamped video.currentTime
queueing: one in-flight seek; continue from seeked
playback: no autoplay; no double-click unless explicitly requested
```

If the user's wording conflicts with a previous default, the latest explicit wording wins. Do not invent a hotspot, gesture, or animation that is not requested.

## Minimal confirmation

Ask at most these questions when they materially change the build:

1. “Should I only create the switchable package, or also apply it to the active Codex skin?”
2. “What local/attached/remote asset should be used for the background?”
3. “Which native Codex UI must remain interactive?”
