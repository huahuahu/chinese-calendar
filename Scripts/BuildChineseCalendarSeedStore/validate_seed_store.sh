#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SRCROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
INPUT_DIR="$REPO_ROOT/Data/Processed/swiftdata_import"
OUTPUT_DIR="$REPO_ROOT/Apps/Shared/Resources/ChineseCalendarSeedStore.bundle"
SEED_STORE="$OUTPUT_DIR/ChineseCalendar.sqlite"
SEED_MANIFEST="$OUTPUT_DIR/manifest.json"
STAMP_FILE="${1:-}"

if [[ "${CHINESE_CALENDAR_SKIP_SEED_STORE_BUILD:-}" == "1" ]]; then
    echo "Skipping SwiftData seed store validation because CHINESE_CALENDAR_SKIP_SEED_STORE_BUILD=1."
else
    if [[ ! -f "$SEED_STORE" ]]; then
        echo "Bundled seed store is missing: $SEED_STORE" >&2
        echo "Run 'make seed-store' from the repository root." >&2
        exit 1
    fi

    node "$SCRIPT_DIR/seed_store_identity.mjs" \
        --input "$INPUT_DIR" \
        --content-level base \
        --check-manifest "$SEED_MANIFEST"
fi

if [[ -n "$STAMP_FILE" ]]; then
    mkdir -p "$(dirname "$STAMP_FILE")"
    touch "$STAMP_FILE"
fi
