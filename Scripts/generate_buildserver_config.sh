#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

if ! command -v xcode-build-server >/dev/null 2>&1; then
    echo "xcode-build-server is required. Install it with: brew install xcode-build-server"
    exit 1
fi

if [[ ! -d "ChineseCalendar.xcodeproj" ]]; then
    ./Scripts/generate_xcodeproj.sh
fi

BUILD_ROOT="$REPO_ROOT/.output/DerivedData"
mkdir -p "$(dirname "$BUILD_ROOT")"

GIT_CONFIG_COUNT=1 \
    GIT_CONFIG_KEY_0=safe.bareRepository \
    GIT_CONFIG_VALUE_0=all \
    xcode-build-server config \
    -workspace ChineseCalendar.xcodeproj/project.xcworkspace \
    -scheme ChineseCalendar-iOS \
    --build_root "$BUILD_ROOT"

if [[ ! -f "buildServer.json" ]]; then
    echo "xcode-build-server did not generate buildServer.json" >&2
    exit 1
fi

echo "Generated buildServer.json with build root $BUILD_ROOT."
