#!/usr/bin/env bash

set -euo pipefail

if ! command -v swiftlint >/dev/null 2>&1; then
    echo "swiftlint is required. Install it with: brew install swiftlint"
    exit 1
fi

swiftlint --strict
