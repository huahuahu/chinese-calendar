#!/usr/bin/env bash

set -euo pipefail

if [[ ! -d "ChineseCalendar.xcodeproj" ]]; then
    ./Scripts/generate_xcodeproj.sh
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

resolve_ios_simulator_destination() {
    local devices_output simulator_id
    devices_output="$(xcrun simctl list devices available)"

    simulator_id="$(awk '
        /^-- iOS 26\.4 --$/ { in_section=1; next }
        /^-- / { in_section=0 }
        in_section && match($0, /\(([0-9A-F-]+)\)/) { print substr($0, RSTART + 1, RLENGTH - 2); exit }
    ' <<<"$devices_output")"

    if [[ -z "$simulator_id" ]]; then
        simulator_id="$(awk '
            /^-- iOS / { in_ios=1; next }
            /^-- / { in_ios=0 }
            in_ios && match($0, /\(([0-9A-F-]+)\)/) { print substr($0, RSTART + 1, RLENGTH - 2); exit }
        ' <<<"$devices_output")"
    fi

    if [[ -n "$simulator_id" ]]; then
        echo "id=${simulator_id}"
        return 0
    fi

    return 1
}

show_command "xcode-select" xcode-select -p
show_command "xcodebuild version" xcodebuild -version
show_command "simctl runtimes" xcrun simctl list runtimes
show_command "simctl devices available" xcrun simctl list devices available
show_ios_build_settings
show_generated_ios_target_metadata
show_generated_ios_scheme
show_destinations "ChineseCalendar-iOS" -sdk iphonesimulator
show_destinations "ChineseCalendar-macOS"

IOS_DESTINATION="$(resolve_ios_simulator_destination)"
show_section "Selected iOS simulator destination"
echo "$IOS_DESTINATION"

xcodebuild \
    -project ChineseCalendar.xcodeproj \
    -scheme ChineseCalendar-iOS \
    -sdk iphonesimulator \
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
