#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SRCROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

INPUT_DIR="$REPO_ROOT/Data/Processed/swiftdata_import"
OUTPUT_DIR="$REPO_ROOT/Apps/Shared/Resources/ChineseCalendarSeedStore.bundle"
SEED_STORE="$OUTPUT_DIR/ChineseCalendar.sqlite"
SEED_MANIFEST="$OUTPUT_DIR/manifest.json"
REQUIRED_SEED_STORE_CONTENT_LEVEL="base"

if [[ "${CHINESE_CALENDAR_SKIP_SEED_STORE_BUILD:-}" == "1" ]]; then
    echo "Skipping SwiftData seed store generation because CHINESE_CALENDAR_SKIP_SEED_STORE_BUILD=1."
    exit 0
fi

if [[ -f "$SEED_STORE" && -f "$SEED_MANIFEST" ]]; then
    if node "$SCRIPT_DIR/seed_store_identity.mjs" \
        --input "$INPUT_DIR" \
        --content-level "$REQUIRED_SEED_STORE_CONTENT_LEVEL" \
        --check-manifest "$SEED_MANIFEST" >/dev/null 2>&1; then
        echo "SwiftData seed store already matches the current artifact identity."
        exit 0
    fi
fi

IDENTITY_DIRECTORY="$(mktemp -d)"
trap 'rm -rf "$IDENTITY_DIRECTORY"' EXIT
IDENTITY_FILE="$IDENTITY_DIRECTORY/identity.json"

node "$SCRIPT_DIR/seed_store_identity.mjs" \
    --input "$INPUT_DIR" \
    --content-level "$REQUIRED_SEED_STORE_CONTENT_LEVEL" \
    --output "$IDENTITY_FILE"

env -u SDKROOT -u TOOLCHAINS swift run -c release --package-path "$REPO_ROOT/Scripts/BuildChineseCalendarSeedStore" ChineseCalendarSeedStoreBuilder \
    --input "$INPUT_DIR" \
    --output "$OUTPUT_DIR" \
    --content-level "$REQUIRED_SEED_STORE_CONTENT_LEVEL" \
    --identity-file "$IDENTITY_FILE" \
    --keep-output \
    --save-interval 5000
