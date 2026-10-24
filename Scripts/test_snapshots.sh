#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$REPO_ROOT"

SCHEME="ChineseCalendarSnapshots"
MODE="compare"
case "${1:-}" in
    "") ;;
    --record)
        SCHEME="ChineseCalendarSnapshots-Record"
        MODE="record"
        ;;
    --help | -h)
        echo "用法：./Scripts/test_snapshots.sh [--record]"
        echo "默认比较已有基准；--record 显式重录基准。"
        exit 0
        ;;
    *)
        echo "未知参数：$1" >&2
        exit 2
        ;;
esac
if [[ $# -gt 1 ]]; then
    echo "只接受一个可选参数：--record。" >&2
    exit 2
fi
if [[ "${CI:-}" == "true" && "$MODE" == "record" ]]; then
    echo "CI 只允许比较基准；请在本地显式录制并审查图片。" >&2
    exit 2
fi

OUTPUT_DIR="${REPO_ROOT}/.output/snapshots/$(date '+%Y%m%d-%H%M%S')-$$"
mkdir -p "$OUTPUT_DIR"
echo "截图测试输出：$OUTPUT_DIR"

fail() {
    echo "$*" | tee "$OUTPUT_DIR/environment-error.txt" >&2
    exit 1
}

# 字体和系统控件的像素结果依赖工具链、运行时和架构，不能自动降级。
[[ "$(uname -m)" == "arm64" ]] || fail "截图基准要求 arm64 Mac；当前架构为 $(uname -m)。"
xcodebuild -version > "$OUTPUT_DIR/xcode-version.txt"
[[ "$(head -n 1 "$OUTPUT_DIR/xcode-version.txt")" == "Xcode 27.1" ]] \
    || fail "截图基准要求 Xcode 27.1，请检查 xcode-select / DEVELOPER_DIR。"
xcodebuild -sdk iphonesimulator -version SDKVersion > "$OUTPUT_DIR/sdk-version.txt"
[[ "$(cat "$OUTPUT_DIR/sdk-version.txt")" == "27.1" ]] \
    || fail "截图基准要求 iPhoneSimulator SDK 27.1。"
# 显式指定设备时沿用调用者选择；其余本地运行先分配，再读取最新设备清单。
if [[ "${CI:-}" != "true" && "${GITHUB_ACTIONS:-}" != "true" && -z "${SNAPSHOT_SIMULATOR_ID:-}" ]]; then
    SNAPSHOT_SIMULATOR_ID="$(python3 "$SCRIPT_DIR/ensure_worktree_simulator.py" --worktree "$REPO_ROOT")" \
        || fail "无法分配工作区专属 Simulator。"
    export SNAPSHOT_SIMULATOR_ID
fi
xcrun simctl list --json > "$OUTPUT_DIR/simulators.json"

# CI 使用 runner 自身的设备；本地优先使用共享上下文中的 Simulator。
SIMULATOR_ID="$(python3 - "$OUTPUT_DIR/simulators.json" <<'PY'
import json
import os
from pathlib import Path
import subprocess
import sys

inventory = json.loads(Path(sys.argv[1]).read_text())
runtime = next((item for item in inventory["runtimes"]
                if item.get("isAvailable")
                and item.get("version") == "27.0"
                and item["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS-")), None)
if runtime is None:
    sys.exit("截图基准要求可用的 iOS 27.0 Simulator runtime；请先在 Xcode 安装。")

device_type = next((item for item in inventory["devicetypes"]
                   if item["name"] == "iPhone 18 Pro Max"), None)
if device_type is None:
    sys.exit("当前 Xcode 缺少 iPhone 18 Pro Max Simulator device type。")

devices = inventory["devices"].get(runtime["identifier"], [])

def matches(device):
    return (device.get("isAvailable")
            and device.get("deviceTypeIdentifier") == device_type["identifier"])

def validate(identifier, source):
    device = next((item for item in devices if item["udid"] == identifier), None)
    if device is None or not matches(device):
        sys.exit(f"{source} 的 {identifier} 不符合基准：需要可用的 iPhone 18 Pro Max / iOS 27.0。")
    return device["udid"]

identifier = os.environ.get("SNAPSHOT_SIMULATOR_ID")
if identifier:
    print(validate(identifier, "SNAPSHOT_SIMULATOR_ID"))
    sys.exit(0)

device = next((item for item in devices if matches(item)), None)
if device:
    print(device["udid"])
else:
    print(subprocess.check_output([
        "xcrun", "simctl", "create", "ChineseCalendar Snapshots iPhone 18 Pro Max",
        device_type["identifier"], runtime["identifier"]
    ], text=True).strip())
PY
)" || fail "无法选择截图测试的 Simulator；详见上方环境诊断。"

printf 'scheme=%s\nsimulatorId=%s\nruntime=iOS 27.0\narchitecture=arm64\nmode=%s\n' \
    "$SCHEME" "$SIMULATOR_ID" "$MODE" > "$OUTPUT_DIR/environment.txt"
cat "$OUTPUT_DIR/environment.txt"

if [[ ! -d "ChineseCalendar.xcodeproj" ]]; then
    ./Scripts/generate_xcodeproj.sh
fi

# 防止调用者遗留的环境变量把默认比较变成录制；录制 scheme 也显式声明此变量。
unset SNAPSHOT_RECORD
if [[ "$MODE" == "record" ]]; then
    export SNAPSHOT_RECORD=1
fi

# 使用独立的串行测试进程，避免不同场景竞争窗口和全局显示设置。
if xcodebuild \
    -project ChineseCalendar.xcodeproj \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID,arch=arm64" \
    -parallel-testing-enabled NO \
    -maximum-concurrent-test-simulator-destinations 1 \
    -resultBundlePath "$OUTPUT_DIR/$MODE.xcresult" \
    ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=YES \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGNING_ALLOWED=YES \
    CODE_SIGNING_REQUIRED=YES \
    test 2>&1 | tee "$OUTPUT_DIR/xcodebuild.log"; then
    echo "截图测试完成：$OUTPUT_DIR/$MODE.xcresult"
else
    TEST_STATUS=$?
    # xcresult 保留完整诊断；导出附件让 CI 中的差异图可直接下载。
    if [[ -d "$OUTPUT_DIR/$MODE.xcresult" ]]; then
        xcrun xcresulttool export attachments \
            --path "$OUTPUT_DIR/$MODE.xcresult" \
            --output-path "$OUTPUT_DIR/attachments" \
            > "$OUTPUT_DIR/export-attachments.log" 2>&1 || true
    fi
    echo "截图测试失败，诊断位于：$OUTPUT_DIR" >&2
    exit "$TEST_STATUS"
fi
