#!/usr/bin/env python3
"""Create a clean distributable copy of a webpage-skin package."""

from __future__ import annotations

import shutil
import sys
from pathlib import Path


EXCLUDED_DIRS = {"node_modules", "dist", "build", ".git", ".cache", ".DS_Store"}
EXCLUDED_FILES = {".DS_Store"}


def copy_tree(source: Path, destination: Path) -> None:
    for entry in source.iterdir():
        if entry.name in EXCLUDED_DIRS or entry.name in EXCLUDED_FILES:
            continue
        target = destination / entry.name
        if entry.is_dir():
            target.mkdir(parents=True, exist_ok=True)
            copy_tree(entry, target)
        elif entry.is_file():
            shutil.copy2(entry, target)


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: package_web_skin.py SOURCE OUTPUT", file=sys.stderr)
        return 2
    source = Path(sys.argv[1]).expanduser().resolve()
    output = Path(sys.argv[2]).expanduser().resolve()
    if not source.is_dir():
        print(f"source is not a directory: {source}", file=sys.stderr)
        return 1
    if output.exists():
        print(f"output already exists; refusing to overwrite: {output}", file=sys.stderr)
        return 1
    output.mkdir(parents=True)
    copy_tree(source, output)
    print(f"packaged: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
