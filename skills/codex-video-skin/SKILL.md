---
name: codex-video-skin
description: Turn a user-provided video into the active macOS Codex homepage skin using Codex Skin Studio, with CPU-safe rendering, optional 60fps playback, synchronized poster frames, and reusable skin switching. Use whenever the user uploads a video or skin folder and asks to replace, change, apply, preview, start, stop, or quickly switch the Codex video wallpaper or 视频皮肤, including “换成这个视频皮肤”, “启动这个皮肤”, “停止皮肤”, and “apply this video as my Codex skin”.
compatibility: macOS, ffmpeg and ffprobe, installed Codex Skin Studio with video support, official Codex Desktop app
---

# Codex Video Skin

Apply or switch a video-based Codex homepage skin with bounded rendering work, synchronized first-frame posters, lazy playback, and reversible start/stop controls. Reuse the installed Skin Studio engine and the bundled helper script; do not rebuild the workflow by hand.

## Scope and guardrails

- Change appearance files only under `~/Library/Application Support/CodexDreamSkinStudio/theme` and the installed Skin Studio engine.
- Never modify the official Codex or ChatGPT `.app`, `app.asar`, code signature, API keys, proxy settings, or relay configuration.
- Do not upload the video or use ProvDex. Do not install missing dependencies without user approval.
- Do not restart Codex unless the local CDP port is unavailable and the user explicitly authorizes a restart.
- Preserve native navigation, title, project picker, composer, and task UI. Keep suggestion cards hidden when the installed skin already hides them.

## Workflow

1. Resolve the uploaded video to an absolute local path. Preserve the current theme name unless the user supplies a new one.
2. Run the preflight check:

   ```bash
   scripts/apply_video_skin.sh --check
   ```

   Stop if the installed engine lacks video support, the CPU debounce fix, the signed bundled Codex runtime, or the active theme. Skin injection uses local CDP and does not modify the official app. If `ffmpeg` or `ffprobe` is missing, ask before installing the trusted Homebrew `ffmpeg` package.
3. If the user supplied an existing packaged skin folder, use its `安装物料.command` or `scripts/install-assets.sh`, then use `启动皮肤.command` to switch it. Use `停止皮肤.command` or `scripts/stop.sh` to stop the current injection. Do not copy files into the official app.
4. Inspect a representative video frame. Default to a centered focal point. If the main subject is off-center, set `CODEX_VIDEO_FOCUS_X` and `CODEX_VIDEO_FOCUS_Y` to decimal values from `0` to `1`.
5. Apply without restarting:

   ```bash
   scripts/apply_video_skin.sh "/absolute/path/video.mp4" "Optional theme name"
   ```

   The script transcodes to a bounded H.264 MP4, removes audio, extracts the encoded first frame as `poster.jpg`, updates `theme.json`, validates the payload, and hot-injects it through loopback CDP.
   Use `CODEX_VIDEO_FPS=60` for a smooth 60fps source; the default is 30fps.
   After a successful apply, package the active material for later switching:

   ```bash
   scripts/package_active_skin.sh "/absolute/output/Codex视频皮肤-名称" "名称"
   ```

   The package contains `theme/`, `安装物料.command`, `启动皮肤.command`, and `停止皮肤.command`.
6. If the script reports that port `9341` is unavailable, ask for restart authorization. After approval, use the installed Skin Studio start script, then rerun step 5.
7. Open a new-chat homepage and verify:
   - Sidebar, title, project picker, and composer text are clear.
   - The main subject remains centered while the title stays on the left.
   - The poster and first playing frame use the same crop and position.
   - Idle state has no video source loaded.
   - First background double-click starts playback.
   - Second double-click pauses on the current frame and keeps the source loaded.
   - Third double-click resumes from that same frame.
   - Leaving the homepage or hiding Codex releases the video resource.
8. Capture and inspect one homepage screenshot after the final change. If subject framing is wrong, adjust only the focus variables and rerun; do not change responsive sizing rules.

## Completion report

Report the source video, processed video size, actual output fps, focal point, live injection result, CPU-safe renderer preflight, and visual/playback verification. Explicitly confirm that no official app files, keys, or relay settings were changed.

## Gotchas

- A poster extracted from the original file can differ from the decoded MP4. Always use the script-generated poster from the transcoded output.
- The source video may be 60fps while the default output is 30fps. Set `CODEX_VIDEO_FPS=60` when motion smoothness matters, then verify the actual encoded frame rate with `ffprobe`.
- Pausing must keep `src` and the active video layer. Resource unloading belongs only to page-leave or visibility-hide behavior.
- Video playback is lazy: the homepage creates the video element without a source, the first background double-click starts it, the second pauses the current frame, and later double-clicks resume it.
- The renderer must use the 240ms timer debounce in `renderer-inject.js`; a full-document observer driven by `requestAnimationFrame` creates a per-frame reconciliation loop and high CPU temperature.
- `art.safeArea: center` controls video cropping. The installed CSS independently keeps homepage copy left-aligned.
