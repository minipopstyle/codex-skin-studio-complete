#!/usr/bin/env python3
"""Validate a Codex webpage-skin package without changing it."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def fail(message: str, errors: list[str]) -> None:
    errors.append(message)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate_web_skin.py /absolute/path/to/skin", file=sys.stderr)
        return 2

    root = Path(sys.argv[1]).expanduser().resolve()
    errors: list[str] = []
    if not root.is_dir():
        print(f"FAIL: missing package directory: {root}", file=sys.stderr)
        return 1

    theme_path = root / "theme" / "theme.json"
    if not theme_path.is_file():
        fail("theme/theme.json is missing", errors)
        theme = {}
    else:
        try:
            theme = json.loads(theme_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            fail(f"theme/theme.json is invalid: {exc}", errors)
            theme = {}

    for key in ("schemaVersion", "id", "name", "image", "video", "appearance", "art"):
        if key not in theme:
            fail(f"theme.json missing key: {key}", errors)

    for asset_key in ("image", "video"):
        asset = theme.get(asset_key)
        if isinstance(asset, str) and asset and not (root / "theme" / asset).is_file():
            fail(f"theme.{asset_key} points to missing file: theme/{asset}", errors)

    for path in ("scripts/install-assets.sh", "scripts/start.sh", "scripts/stop.sh"):
        file_path = root / path
        if not file_path.is_file():
            fail(f"missing script: {path}", errors)
        elif not os.access(file_path, os.X_OK):
            fail(f"script is not executable: {path}", errors)

    for path in ("安装物料.command", "启动皮肤.command", "停止皮肤.command"):
        file_path = root / path
        if not file_path.is_file():
            fail(f"missing launcher: {path}", errors)
        elif not os.access(file_path, os.X_OK):
            fail(f"launcher is not executable: {path}", errors)

    style = theme.get("homepageStyle", "default")
    if style not in {"default", "velorah", "mainframe"}:
        fail(f"unsupported homepageStyle: {style}", errors)

    for path in root.rglob("*"):
        if not path.is_file() or path.name in {"validate_web_skin.py", "package_web_skin.py"}:
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        lowered = text.lower()
        if any(part in {"node_modules", "dist", "build", ".git"} for part in path.parts):
            continue
        for marker in ("/applications/", "api_key", "proxy_settings", "relay_config"):
            if marker in lowered:
                fail(f"forbidden installation/security marker in {path.relative_to(root)}: {marker}", errors)
                break

    if errors:
        print("Web skin validation: FAIL")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Web skin validation: PASS")
    print(f"- package: {root}")
    print(f"- theme: {theme.get('name', theme.get('id', 'unknown'))}")
    print(f"- homepageStyle: {theme.get('homepageStyle', 'default')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
