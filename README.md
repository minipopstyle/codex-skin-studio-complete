# Codex Skin Studio Complete

面向 macOS Codex Desktop 的完整换肤包，包含统一引擎、两个 Skill 和六个可直接使用的皮肤。

本项目是非官方界面定制工具，不修改官方 `.app`、`app.asar`、代码签名、API Key 或模型配置。运行时只通过本机回环 CDP 注入样式。

## 包含内容

- 统一 macOS 换肤引擎
- `codex-video-skin`：把本地视频处理成 Codex 视频皮肤
- `codex-web-skin-builder`：构建和验证支持的网页皮肤
- 视频皮肤：IMG6275、女性角色-日漫、自由女神、长视频演示
- 网页皮肤：Velorah、Mainframe
- 首页样式：`default`、`velorah`、`mainframe`

## 快速安装

首次使用前，请先启动一次官方 Codex Desktop，使 `~/.codex/config.toml` 存在，然后关闭 Codex。

可直接双击 `Install Codex Skin Studio.command`，或运行：

```bash
./scripts/install-dream-skin-macos.sh --no-launch
```

安装位置：

| 内容 | 路径 |
| --- | --- |
| 引擎 | `~/.codex/codex-dream-skin-studio` |
| 视频 Skill | `~/.codex/skills/codex-video-skin` |
| 网页 Skill | `~/.codex/skills/codex-web-skin-builder` |
| 主题和日志 | `~/Library/Application Support/CodexDreamSkinStudio` |

完整使用流程见 [使用说明](./使用说明.md)。

## 验证与恢复

```bash
./tests/run-tests.sh
~/.codex/codex-dream-skin-studio/scripts/doctor-macos.sh
~/.codex/codex-dream-skin-studio/scripts/verify-dream-skin-macos.sh
~/.codex/codex-dream-skin-studio/scripts/restore-dream-skin-macos.sh --restore-base-theme --restart-codex
```

CDP 调试端口只绑定 `127.0.0.1`，但仍属于本机敏感接口。启用皮肤时不要运行不可信的本地程序；使用完可以执行恢复脚本关闭注入。
