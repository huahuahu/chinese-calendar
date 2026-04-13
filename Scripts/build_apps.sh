#!/usr/bin/env bash

set -euo pipefail

if [[ ! -d "ChineseCalendar.xcodeproj" ]]; then
    ./Scripts/generate_xcodeproj.sh
fi

show_destinations() {
    local scheme="$1"

    echo "Available destinations for ${scheme}:"
    xcodebuild \
        -project ChineseCalendar.xcodeproj \
        -scheme "$scheme" \
        -showdestinations
}

resolve_ios_destination() {
    local destinations simulator_id device_id
    destinations="$(xcodebuild -project ChineseCalendar.xcodeproj -scheme ChineseCalendar-iOS -showdestinations 2>/dev/null)"

    simulator_id="$({ grep -E 'platform:iOS Simulator, id:[^,]+' <<<"$destinations" || true; } | sed -E 's/.*id:([^,]+),.*/\1/' | head -n 1)"
    if [[ -n "$simulator_id" && "$simulator_id" != dvtdevice-* ]]; then
        echo "id=${simulator_id}"
        return 0
    fi

    device_id="$({ grep -E 'platform:iOS, .*id:[^,]+' <<<"$destinations" || true; } | sed -E 's/.*id:([^,]+),.*/\1/' | head -n 1)"
    if [[ -n "$device_id" && "$device_id" != dvtdevice-* ]]; then
        echo "id=${device_id}"
        return 0
    fi

    if grep -Fq 'platform:iOS Simulator' <<<"$destinations"; then
        echo 'generic/platform=iOS Simulator'
        return 0
    fi

    if grep -Fq 'platform:iOS' <<<"$destinations"; then
        echo 'generic/platform=iOS'
        return 0
    fi

    return 1
}

show_destinations "ChineseCalendar-iOS"
show_destinations "ChineseCalendar-macOS"

IOS_DESTINATION="$(resolve_ios_destination)"
echo "Selected iOS destination: ${IOS_DESTINATION}"

xcodebuild \
    -project ChineseCalendar.xcodeproj \
    -scheme ChineseCalendar-iOS \
    -configuration Debug \
    -destination "$IOS_DESTINATION" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build

xcodebuild \
    -project ChineseCalendar.xcodeproj \
    -scheme ChineseCalendar-macOS \
    -configuration Debug \
    -destination 'platform=macOS' \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build
