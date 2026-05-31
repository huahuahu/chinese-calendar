#!/usr/bin/env bash

set -euo pipefail

if ! command -v xcode-build-server >/dev/null 2>&1; then
    echo "xcode-build-server is required. Install it with: brew install xcode-build-server"
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to normalize buildServer.json paths."
    exit 1
fi

if [[ ! -d "ChineseCalendar.xcodeproj" ]]; then
    ./Scripts/generate_xcodeproj.sh
fi

xcode-build-server config -project ChineseCalendar.xcodeproj -scheme ChineseCalendar-macOS

python3 ./Scripts/normalize_buildserver_json.py buildServer.json
