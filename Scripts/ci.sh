#!/usr/bin/env bash

set -euo pipefail

TASK_ID="local-$(date '+%Y%m%d-%H%M%S')-$$"
export CHINESE_CALENDAR_CI_OUTPUT_DIR="${CHINESE_CALENDAR_CI_OUTPUT_DIR:-$HOME/Library/Logs/ChineseCalendar/ci/$TASK_ID}"
mkdir -p "$CHINESE_CALENDAR_CI_OUTPUT_DIR"
# 本地完整 CI 也是一次独立实验；显式传入任务设备时由外层负责收尾。
if [[ -z "${CHINESE_CALENDAR_SIMULATOR_ID:-}" ]]; then
    trap 'python3 Scripts/ci_simulator.py finish --state "$CHINESE_CALENDAR_CI_OUTPUT_DIR/simulator.json"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    CHINESE_CALENDAR_SIMULATOR_ID="$(python3 Scripts/ci_simulator.py start \
        --state "$CHINESE_CALENDAR_CI_OUTPUT_DIR/simulator.json" --task "$TASK_ID" \
        --device 'iPhone 18 Pro Max' --runtime 27.2)"
    export CHINESE_CALENDAR_SIMULATOR_ID
fi
export SNAPSHOT_SIMULATOR_ID="$CHINESE_CALENDAR_SIMULATOR_ID"

./Scripts/format.sh --check
./Scripts/lint.sh
python3 ./Scripts/validate_localized_copy.py
./Scripts/validate_data_schemas.sh
./Scripts/generate_xcodeproj.sh
./Scripts/test.sh 2>&1 | tee "$CHINESE_CALENDAR_CI_OUTPUT_DIR/tests.log"
./Scripts/test_snapshots.sh
./Scripts/build_apps.sh 2>&1 | tee "$CHINESE_CALENDAR_CI_OUTPUT_DIR/build.log"
