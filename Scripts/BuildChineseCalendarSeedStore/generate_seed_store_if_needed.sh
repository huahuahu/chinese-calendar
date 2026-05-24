#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SRCROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

INPUT_DIR="$REPO_ROOT/Data/Processed/swiftdata_import"
OUTPUT_DIR="$REPO_ROOT/Apps/Shared/Resources/ChineseCalendarSeedStore.bundle"
SEED_STORE="$OUTPUT_DIR/ChineseCalendar.sqlite"
SEED_MANIFEST="$OUTPUT_DIR/manifest.json"

if [[ -f "$SEED_STORE" && -f "$SEED_MANIFEST" ]]; then
    if [[ -f "$SEED_STORE-wal" || -f "$SEED_STORE-shm" ]]; then
        sqlite3 "$SEED_STORE" 'PRAGMA wal_checkpoint(TRUNCATE); PRAGMA journal_mode=DELETE;'
        rm -f "$SEED_STORE-shm" "$SEED_STORE-wal"
    fi

    exit 0
fi

env -u SDKROOT -u TOOLCHAINS swift run -c release --package-path "$REPO_ROOT/Scripts/BuildChineseCalendarSeedStore" ChineseCalendarSeedStoreBuilder \
    --input "$INPUT_DIR" \
    --output "$OUTPUT_DIR" \
    --keep-output \
    --save-interval 5000
