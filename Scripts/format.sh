#!/usr/bin/env bash

set -euo pipefail

if ! command -v swiftformat >/dev/null 2>&1; then
    echo "swiftformat is required. Install it with: brew install swiftformat"
    exit 1
fi

mode="format"
if [[ "${1:-}" == "--check" ]]; then
    mode="lint"
fi

if [[ "$mode" == "lint" ]]; then
    swiftformat --lint .
else
    swiftformat .
fi
