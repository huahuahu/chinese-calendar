#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "xcodebuild is required to build ChineseCalendar." >&2
    exit 1
fi

if ! command -v xcode-build-server >/dev/null 2>&1; then
    echo "xcode-build-server is required to generate the compile cache." >&2
    exit 1
fi

if ! command -v plutil >/dev/null 2>&1; then
    echo "plutil is required to read buildServer.json." >&2
    exit 1
fi

if [[ ! -f "buildServer.json" ]]; then
    ./Scripts/generate_buildserver_config.sh
fi

read_build_server_value() {
    plutil -extract "$1" raw -o - "$REPO_ROOT/buildServer.json"
}

read_xcodebuildmcp_session_default() {
    if [[ ! -f "$REPO_ROOT/.xcodebuildmcp/config.yaml" ]]; then
        return 0
    fi

    awk -v key="$1:" '$1 == key { print $2; exit }' "$REPO_ROOT/.xcodebuildmcp/config.yaml"
}

hash_text() {
    if command -v md5 >/dev/null 2>&1; then
        printf '%s' "$1" | md5 -q
    elif command -v md5sum >/dev/null 2>&1; then
        printf '%s' "$1" | md5sum | awk '{ print $1 }'
    else
        echo "md5 or md5sum is required to compute xcode-build-server cache paths." >&2
        exit 1
    fi
}

build_server_compile_file_path() {
    local cache_root_key build_root_hash
    cache_root_key="$(printf '%s' "$REPO_ROOT" | sed 's#/#-#g')"
    build_root_hash="$(hash_text "$BUILD_ROOT")"
    echo "$HOME/Library/Caches/xcode-build-server/$cache_root_key/compile_file-$BUILD_SCHEME-$build_root_hash"
}

if ! BUILD_WORKSPACE="$(read_build_server_value workspace)"; then
    echo "buildServer.json is missing a workspace value." >&2
    exit 1
fi

if ! BUILD_SCHEME="$(read_build_server_value scheme)"; then
    echo "buildServer.json is missing a scheme value." >&2
    exit 1
fi

if ! BUILD_ROOT="$(read_build_server_value build_root)"; then
    echo "buildServer.json is missing a build_root value." >&2
    exit 1
fi

if [[ -z "$BUILD_WORKSPACE" || -z "$BUILD_SCHEME" || -z "$BUILD_ROOT" ]]; then
    echo "buildServer.json has empty workspace, scheme, or build_root values." >&2
    exit 1
fi

EXPECTED_BUILD_ROOT="$REPO_ROOT/.output/DerivedData"
if [[ "$BUILD_ROOT" != "$EXPECTED_BUILD_ROOT" ]]; then
    echo "refusing to clean unexpected build root: $BUILD_ROOT" >&2
    exit 1
fi

BUILD_DESTINATION="generic/platform=iOS Simulator"
if SIMULATOR_ID="$(read_xcodebuildmcp_session_default simulatorId)" && [[ -n "$SIMULATOR_ID" ]]; then
    BUILD_DESTINATION="platform=iOS Simulator,id=$SIMULATOR_ID"
fi

RESULT_BUNDLE_PATH="$REPO_ROOT/.output/BuildServer.xcresult"
COMPILE_FILE="$(build_server_compile_file_path)"

echo "Cleaning stale build index data at $BUILD_ROOT..."
rm -rf "$BUILD_ROOT" "$RESULT_BUNDLE_PATH"
mkdir -p "$(dirname "$COMPILE_FILE")"
rm -f "$COMPILE_FILE" "$COMPILE_FILE.lock"

echo "Building $BUILD_SCHEME for iOS Simulator to create the index store..."
env \
    GIT_CONFIG_COUNT=1 \
    GIT_CONFIG_KEY_0=safe.bareRepository \
    GIT_CONFIG_VALUE_0=all \
    CHINESE_CALENDAR_SKIP_SEED_STORE_BUILD=1 \
    xcodebuild \
    GCC_GENERATE_DEBUGGING_SYMBOLS=YES \
    ONLY_ACTIVE_ARCH=YES \
    COMPILER_INDEX_STORE_ENABLE=YES \
    -workspace "$BUILD_WORKSPACE" \
    -scheme "$BUILD_SCHEME" \
    -configuration Debug \
    -destination "$BUILD_DESTINATION" \
    -sdk iphonesimulator \
    -resultBundlePath "$RESULT_BUNDLE_PATH" \
    -derivedDataPath "$BUILD_ROOT" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build-for-testing

echo "Generating xcode-build-server compile cache..."
env \
    GIT_CONFIG_COUNT=1 \
    GIT_CONFIG_KEY_0=safe.bareRepository \
    GIT_CONFIG_VALUE_0=all \
    xcode-build-server parse -s "$BUILD_ROOT" -o "$COMPILE_FILE" --scheme "$BUILD_SCHEME"

if [[ ! -s "$COMPILE_FILE" ]]; then
    echo "xcode-build-server did not generate a compile cache." >&2
    exit 1
fi

echo "Generated xcode-build-server compile cache at $COMPILE_FILE"
