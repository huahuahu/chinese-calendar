#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/ios_simulator.sh"

node --test Scripts/BuildChineseCalendarSeedStore/Tests/*.test.mjs

if [[ ! -d "ChineseCalendar.xcodeproj" ]]; then
    ./Scripts/generate_xcodeproj.sh
fi

IOS_DESTINATION="$(resolve_ios_simulator_destination)"
IOS_SIMULATOR_ARCH="$(resolve_ios_simulator_architecture)"

xcodebuild \
    -project ChineseCalendar.xcodeproj \
    -scheme ChineseCalendar-iOS \
    -sdk iphonesimulator \
    -configuration Debug \
    -destination "$IOS_DESTINATION,arch=$IOS_SIMULATOR_ARCH" \
    ARCHS="$IOS_SIMULATOR_ARCH" \
    ONLY_ACTIVE_ARCH=YES \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    test
