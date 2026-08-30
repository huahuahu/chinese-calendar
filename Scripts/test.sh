#!/usr/bin/env bash

set -euo pipefail

node --test Scripts/BuildChineseCalendarSeedStore/Tests/*.test.mjs
swift test --package-path Sources
