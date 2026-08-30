#!/usr/bin/env bash

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

    if [[ -z "$simulator_id" ]]; then
        echo "No available iOS Simulator was found." >&2
        return 1
    fi

    echo "id=${simulator_id}"
}

resolve_ios_simulator_architecture() {
    case "$(uname -m)" in
        arm64 | x86_64)
            uname -m
            ;;
        *)
            echo "Unsupported iOS Simulator host architecture: $(uname -m)" >&2
            return 1
            ;;
    esac
}
