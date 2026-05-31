#!/usr/bin/env bash

set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

workspace="$tmp_dir/workspace"
mkdir -p "$workspace/.buildserver"

cat >"$workspace/buildServer.json" <<JSON
{
  "name": "xcode-build-server",
  "argv": ["xcode-build-server", "serve"],
  "workspace": "$workspace",
  "build_root": "$workspace/.buildserver"
}
JSON

python3 ./Scripts/normalize_buildserver_json.py "$workspace/buildServer.json"

python3 - "$workspace/buildServer.json" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))

assert data["workspace"] == ".", data["workspace"]
assert data["build_root"] == ".buildserver", data["build_root"]
assert data["name"] == "xcode-build-server"
assert data["argv"] == ["xcode-build-server", "serve"]
PY

