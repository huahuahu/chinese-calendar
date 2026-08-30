#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/ios_simulator.sh"

if [[ ! -d "ChineseCalendar.xcodeproj" ]]; then
    ./Scripts/generate_xcodeproj.sh
fi

if [[ "${GITHUB_ACTIONS:-}" == "true" && -z "${CHINESE_CALENDAR_BUILD_SEED_STORE_IN_CI:-}" ]]; then
    export CHINESE_CALENDAR_SKIP_SEED_STORE_BUILD=1
fi

show_section() {
    local title="$1"

    echo
    echo "=== ${title} ==="
}

show_command() {
    local title="$1"
    shift

    show_section "$title"
    "$@"
}

show_destinations() {
    local scheme="$1"
    shift

    show_section "Available destinations for ${scheme}"
    xcodebuild \
        -project ChineseCalendar.xcodeproj \
        -scheme "$scheme" \
        "$@" \
        -showdestinations
}

show_ios_build_settings() {
    show_section "ChineseCalendar-iOS build settings"
    xcodebuild \
        -project ChineseCalendar.xcodeproj \
        -scheme ChineseCalendar-iOS \
        -sdk iphonesimulator \
        -showBuildSettings | \
        grep -E 'SUPPORTED_PLATFORMS|SDKROOT|TARGETED_DEVICE_FAMILY|IPHONEOS_DEPLOYMENT_TARGET|SUPPORTS_MACCATALYST|SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD|SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD|PLATFORM_NAME|EFFECTIVE_PLATFORM_NAME|TARGET_DEVICE_PLATFORM_NAME'
}

show_generated_ios_target_metadata() {
    show_section "Generated ChineseCalendar-iOS target metadata"
    sed -n '130,190p' ChineseCalendar.xcodeproj/project.pbxproj

    show_section "Generated ChineseCalendar-iOS build configuration excerpt"
    sed -n '245,290p' ChineseCalendar.xcodeproj/project.pbxproj
}

show_generated_ios_scheme() {
    show_section "Generated ChineseCalendar-iOS shared scheme"
    sed -n '1,220p' ChineseCalendar.xcodeproj/xcshareddata/xcschemes/ChineseCalendar-iOS.xcscheme
}

show_command "xcode-select" xcode-select -p
show_command "xcodebuild version" xcodebuild -version
show_command "simctl runtimes" xcrun simctl list runtimes
show_command "simctl devices available" xcrun simctl list devices available
show_ios_build_settings
show_generated_ios_target_metadata
show_generated_ios_scheme
show_destinations "ChineseCalendar-iOS" -sdk iphonesimulator

IOS_DESTINATION="$(resolve_ios_simulator_destination)"
IOS_SIMULATOR_ARCH="$(resolve_ios_simulator_architecture)"
show_section "Selected iOS simulator destination"
echo "$IOS_DESTINATION,arch=$IOS_SIMULATOR_ARCH"

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
    build
