# Scripts

Utility scripts for fetching, normalizing, generating app-ready data, and validating local/CI builds.

## Task Simulator Lifecycle

CI 每个设备 job 使用独立实验目录和 Simulator，同一 job 的测试、快照和构建复用实际 UUID，结束后删除设备实例。工具链统一为 Xcode / SDK **27.2**，允许当前安装的 RC；iPhone 18 Pro Max 和 iPad Pro 13-inch (M5) 使用 runtime **27.2**，iPhone Duo 使用 **27.1**。`ci_simulator.py` 在创建前检查 `supportedDeviceTypes`，也能区分只支持 Duo 的特殊 27.2 runtime，缺少兼容环境时明确失败。

本地独立实验也可使用同一入口，`TASK_DIR` 应是 checkout 外、带本次任务标识的专属目录。不同任务使用不同目录；同一个任务重复 `start` 会复用 UUID，已结束目录不能再次使用：

```bash
TASK_DIR="$HOME/Library/Logs/ChineseCalendar/experiments/my-task-20261028"
export CHINESE_CALENDAR_SIMULATOR_ID="$(python3 Scripts/ci_simulator.py start \
  --state "$TASK_DIR/simulator.json" --task my-task-20261028 \
  --device 'iPhone 18 Pro Max' --runtime 27.2)"
export SNAPSHOT_SIMULATOR_ID="$CHINESE_CALENDAR_SIMULATOR_ID"
export CHINESE_CALENDAR_CI_OUTPUT_DIR="$TASK_DIR"
trap 'python3 Scripts/ci_simulator.py finish --state "$TASK_DIR/simulator.json"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
# 在同一个 shell 中执行实验的构建／测试；MCP 另按共享配置选择实际 UUID。
```

普通测试通过 `CHINESE_CALENDAR_SIMULATOR_ID` 指定设备，关闭测试 Simulator 克隆并保留 `tests.xcresult`；快照显式 UUID 必须符合固定 iPhone / 27.2 基准。结束时 `finish` 先保存设备清单，设备已启动时尽力保存截图和最近五分钟日志，然后关闭并只删除归属记录中验证通过的 UUID，最后保存 `sha256.json`。应用测试结果和构建日志须在调用 `finish` 前写入实验目录，不能只在设备内保留证据。

CI 使用 `always()` 清理，并上传所有成功或失败证据，保留 14 天。目录为 `~/Library/Logs/ChineseCalendar/ci/<run>-<attempt>-<device>/`，不在 checkout 内；设备 UUID、runtime build、Xcode build、实际 Developer 路径和提交均可追溯。当前仍使用 GitHub 托管 `xcode-27` runner，宿主销毁后本地目录不会保留，长期证据以 Actions artifact 为准。自托管宿主可保留目录，runtime 和构建／SwiftPM 缓存不由清理脚本删除。

硬杀进程可能阻止正常收尾。按 `simulator.json` 的归属检查后显式恢复清理：

```bash
python3 Scripts/ci_simulator.py finish --state '/absolute/task/directory/simulator.json'
```

若创建中断发生在 UUID 写入前，脚本只按预先登记的唯一设备名称恢复 UUID，再验证型号与 runtime 后删除；名称不唯一或归属不匹配时拒绝操作。设备已删除时重复清理安全。禁止用全局 `delete unavailable`、名称前缀扫描或删除其他任务设备来代替归属核对。

运行 `python3 -B Scripts/tests/test_ci_simulator.py` 验证隔离和失败路径；测试不操作真实设备。

## Worktree Simulator Allocation

`ensure_worktree_simulator.py` requires Python 3.9+, the pinned PyYAML dependency in `Scripts/requirements.txt`, Git, and the selected Xcode's `simctl`. For a local environment, create and activate a virtual environment, then install the dependency through the configured local proxy:

```bash
python3 -m venv .output/python-venv
source .output/python-venv/bin/activate
HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 python3 -m pip install -r Scripts/requirements.txt
```

Use that environment for local setup/build/test scripts. If your selected Python already has the pinned dependency, no environment changes are needed. CI selects Python 3.12 with `actions/setup-python` and installs the same requirements before running tests. The tests fail when required dependencies are missing instead of silently skipping validation.

Run the allocator before choosing a Simulator in either MCP:

```bash
python3 Scripts/ensure_worktree_simulator.py --dry-run
python3 Scripts/ensure_worktree_simulator.py
python3 Scripts/ensure_worktree_simulator.py --worktree "/path/to/another worktree"
```

The source of truth is the selected worktree's `.xcodebuildmcp/config.yaml`. If another worktree registered by `git worktree list` references the same UUID, the script creates an empty device with the same device type and runtime and updates `sessionDefaults.simulatorId` and `simulatorName`. Other settings and other worktrees' files are preserved. It does not clone app data, start, stop, or erase existing devices. Without a conflict, repeated runs reuse the device. Logs go to stderr; successful allocation prints only the chosen UUID to stdout.

A missing local configuration is initialized from `.xcodebuildmcp/config.example.yaml`. Allocation is pinned to **iPhone 18 Pro Max / iOS 27.2**, matching the snapshot baseline. Name lookup only considers that combination; creation also requires it, even when newer compatible runtimes are installed. Ambiguous matching names, unavailable configured UUIDs, and UUIDs for a different model or runtime fail with a diagnostic. To recreate a deleted device or replace an incompatible selection, remove its UUID and set `simulatorName` to `iPhone 18 Pro Max`. A missing iOS 27.2 runtime must be installed in Xcode; the script does not fall back to another version.

The real configuration is ignored by Git. Change the template when sharing project defaults; machine-specific UUIDs belong only in the local file. Existing worktrees on older commits can still track their own configuration until they adopt this change. This migration preserves the current checkout's local file using `git rm --cached`; Git history is not rewritten.

The allocation transaction uses a file lock in the Git common directory and atomic configuration replacement. It serializes concurrent allocation calls from this repository, including multiple calls for the same worktree. It detects **configuration references**, not live device usage: separate clones/repositories, manual Xcode choices, and tasks that bypass this script are outside its scope. This lock ends when allocation finishes; it is not a lock around the later build/test/UI session.

`setup_worktree.sh`, local `ios_simulator.sh` consumers (test/build), `generate_build_index.sh`, and local snapshot tests run the allocator automatically. CI requires the UUID created by the task lifecycle below and never selects from existing runner devices. An explicit `SNAPSHOT_SIMULATOR_ID` continues to override the local snapshot allocation. After any allocation change, reconcile the MCP defaults and any browser mirror with the resulting configuration.

Run the isolated integration tests with `python3 Scripts/tests/test_ensure_worktree_simulator.py`. They use temporary Git worktrees and a fake `xcrun`, without touching real devices. `Scripts/test.sh` also runs them.

## Navigation API Validation

`validate_navigation_public_api.py` checks the public NavigationCore API against existing Simulator build products. It uses ordinary `import NavigationCore`: supported calls must compile, and each negative sample must fail with the expected access or missing-symbol diagnostic. Build the Debug Simulator modules first, then run:

```bash
python3 Scripts/validate_navigation_public_api.py \
  <Build/Products/Debug-iphonesimulator> \
  <iPhoneSimulator.sdk> \
  arm64-apple-ios26.0-simulator
```

Use the SDK and target that match the build. Reports and generated samples go to `.output/navigation-public-api/`; the script does not rebuild any target. Fixtures live in `Scripts/NavigationCoreAPI/`.

The former `validate_navigation_identity_types.py` was retired when Issue #165 made Core presentation identities internal and removed App session identities. Issue #166 evidence retains the historical verifier name; internal identity behavior remains covered by `NavigationIdentityTests.swift`.
