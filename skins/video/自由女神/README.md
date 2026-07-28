# Codex 视频皮肤：自由女神

这是可直接使用的 Codex Skin Studio 视频物料包。

## 内容

- `theme/background.mp4`：已处理、无音频的播放视频
- `theme/poster.jpg`：与视频第一帧同步的静态海报
- `theme/theme.json`：皮肤配置与人物构图参数
- `scripts/install-assets.sh`：将物料安装到当前用户的 Skin Studio 主题目录
- `scripts/start.sh`：启动并应用皮肤
- `scripts/stop.sh`：停止注入并移除当前页面皮肤

## 使用

也可以直接双击文件夹里的：

- `安装物料.command`
- `启动皮肤.command`
- `停止皮肤.command`

首次使用或换回此皮肤：

```bash
cd "/path/to/codex-skin-studio-complete/skins/video/自由女神"
./scripts/install-assets.sh
./scripts/start.sh
```

停止皮肤：

```bash
cd "/path/to/codex-skin-studio-complete/skins/video/自由女神"
./scripts/stop.sh
```

启动和停止依赖已安装的 `~/.codex/codex-dream-skin-studio` 引擎；本包不修改官方 ChatGPT/Codex `.app`，也不包含 API Key、中转或代理配置。

原始视频不在当前桌面路径中，因此这里保存的是实际用于皮肤的处理后视频。
