# codex-web-skin-builder

把自然语言网页需求转成可切换的 Codex 网页皮肤：React/Vite 预览层、共享 Skin Studio 注入层、视频/海报资料包，以及安装、启动、停止和验证脚本。

当前 macOS 引擎支持 `default`、`velorah` 和 `mainframe` 三种首页样式。皮肤包不携带或覆盖引擎文件。

入口：`SKILL.md`

验证：

```bash
python3 scripts/validate_web_skin.py /absolute/path/to/skin
```
