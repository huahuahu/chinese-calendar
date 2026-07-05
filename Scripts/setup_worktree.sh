#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_WORKSPACE_PATH="$(cd "$SCRIPT_DIR/.." && pwd)"
TRIGGER="${COPILOT_SCRIPT_TRIGGER:-manual}"
WORKSPACE_PATH_INPUT="${COPILOT_WORKSPACE_PATH:-$DEFAULT_WORKSPACE_PATH}"

if ! WORKSPACE_PATH="$(cd "$WORKSPACE_PATH_INPUT" 2>/dev/null && pwd -P)"; then
    echo "error: COPILOT_WORKSPACE_PATH does not exist: $WORKSPACE_PATH_INPUT" >&2
    exit 2
fi

OUTPUT_DIR="$WORKSPACE_PATH/.output"
LOG_FILE="$OUTPUT_DIR/setup_worktree.log"

mkdir -p "$OUTPUT_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo
date
echo "Writing setup log to $LOG_FILE"
echo "COPILOT_SCRIPT_TRIGGER=${TRIGGER}"

case "$TRIGGER" in
    session.create | manual)
        ;;
    *)
        echo "Skipping setup for COPILOT_SCRIPT_TRIGGER=${TRIGGER}"
        exit 0
        ;;
esac

cd "$WORKSPACE_PATH"

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen is required. Install it with: brew install xcodegen"
    exit 1
fi

if ! command -v xcode-build-server >/dev/null 2>&1; then
    echo "xcode-build-server is required. Install it with: brew install xcode-build-server"
    exit 1
fi

echo "Generating ChineseCalendar.xcodeproj with XcodeGen..."
xcodegen generate

echo "Generating buildServer.json with xcode-build-server..."
./Scripts/generate_buildserver_config.sh

if [[ ! -f "$WORKSPACE_PATH/buildServer.json" ]]; then
    echo "xcode-build-server did not generate buildServer.json" >&2
    exit 1
fi

echo "Generated buildServer.json at $WORKSPACE_PATH/buildServer.json"

echo "Generating build index for VS Code navigation..."
./Scripts/generate_build_index.sh
