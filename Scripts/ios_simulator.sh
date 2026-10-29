#!/usr/bin/env bash

resolve_ios_simulator_destination() {
    local simulator_id repository_root
    # CI 和显式实验只使用本任务分配的 UUID，不能借用已有设备。
    if [[ -n "${CHINESE_CALENDAR_SIMULATOR_ID:-}" ]]; then
        echo "id=${CHINESE_CALENDAR_SIMULATOR_ID}"
        return 0
    fi
    if [[ "${CI:-}" != "true" && "${GITHUB_ACTIONS:-}" != "true" ]]; then
        repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
        if ! simulator_id="$(python3 "$repository_root/Scripts/ensure_worktree_simulator.py" --worktree "$repository_root")"; then
            return 1
        fi
        echo "id=${simulator_id}"
        return 0
    fi

    echo "CI requires CHINESE_CALENDAR_SIMULATOR_ID from ci_simulator.py start." >&2
    return 1
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
