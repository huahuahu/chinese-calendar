#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Any
from urllib.parse import unquote, urlparse


def _file_uri_to_path(value: str) -> str | None:
    if not value.startswith("file://"):
        return None

    parsed = urlparse(value)
    if parsed.scheme != "file":
        return None

    return unquote(parsed.path)


def _to_relative_path(value: Any, start: Path) -> tuple[Any, bool]:
    if not isinstance(value, str):
        return value, False

    uri_path = _file_uri_to_path(value)
    if uri_path is not None:
        value = uri_path

    candidate = Path(value)
    if not candidate.is_absolute():
        return value, False

    relative = os.path.relpath(candidate, start=start)
    return relative, True


def normalize_buildserver_json(path: Path) -> bool:
    data = json.loads(path.read_text(encoding="utf-8"))
    json_dir = path.parent.resolve()

    changed = False
    for key in ("workspace", "build_root"):
        if key not in data:
            continue
        data[key], did_change = _to_relative_path(data[key], start=json_dir)
        changed = changed or did_change

    if not changed:
        return False

    path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    return True


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Normalize buildServer.json workspace/build_root to relative paths."
    )
    parser.add_argument(
        "path",
        nargs="?",
        default="buildServer.json",
        help="Path to buildServer.json (default: ./buildServer.json).",
    )
    args = parser.parse_args()

    path = Path(args.path)
    if not path.exists():
        raise SystemExit(f"buildServer.json not found at: {path}")

    normalize_buildserver_json(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

