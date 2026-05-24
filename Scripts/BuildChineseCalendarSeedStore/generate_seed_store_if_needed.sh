#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SRCROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

INPUT_DIR="$REPO_ROOT/Data/Processed/swiftdata_import"
OUTPUT_DIR="$REPO_ROOT/Apps/Shared/Resources/ChineseCalendarSeedStore.bundle"
SEED_STORE="$OUTPUT_DIR/ChineseCalendar.sqlite"
SEED_MANIFEST="$OUTPUT_DIR/manifest.json"
REQUIRED_SEED_STORE_FORMAT_VERSION="2"

seed_store_format_version() {
    if [[ ! -f "$SEED_MANIFEST" ]]; then
        return 1
    fi

    plutil -extract seedStoreFormatVersion raw "$SEED_MANIFEST" 2>/dev/null
}

source_data_is_newer_than_seed_manifest() {
    [[ "$INPUT_DIR/manifest.json" -nt "$SEED_MANIFEST" ]] && return 0
    [[ "$INPUT_DIR/chinese_lunar_years.jsonl" -nt "$SEED_MANIFEST" ]] && return 0
    [[ "$INPUT_DIR/chinese_lunar_months.jsonl" -nt "$SEED_MANIFEST" ]] && return 0

    [[ -n "$(find "$INPUT_DIR/calendar_days" -name calendar_days.jsonl -newer "$SEED_MANIFEST" -print -quit)" ]]
}

if [[ -f "$SEED_STORE" && -f "$SEED_MANIFEST" ]]; then
    current_format_version="$(seed_store_format_version || true)"
    if [[ "$current_format_version" == "$REQUIRED_SEED_STORE_FORMAT_VERSION" ]] && ! source_data_is_newer_than_seed_manifest; then
        if [[ -f "$SEED_STORE-wal" || -f "$SEED_STORE-shm" ]]; then
            sqlite3 "$SEED_STORE" 'PRAGMA wal_checkpoint(TRUNCATE); PRAGMA journal_mode=DELETE;'
            rm -f "$SEED_STORE-shm" "$SEED_STORE-wal"
        fi

        exit 0
    fi
fi

env -u SDKROOT -u TOOLCHAINS swift run -c release --package-path "$REPO_ROOT/Scripts/BuildChineseCalendarSeedStore" ChineseCalendarSeedStoreBuilder \
    --input "$INPUT_DIR" \
    --output "$OUTPUT_DIR" \
    --keep-output \
    --save-interval 5000
