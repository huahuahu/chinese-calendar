# 工作区模拟器分配：结果

- 方案：[000-plan.md](000-plan.md)
- 记录日期：2026-10-24
- 代码状态：原实现已通过 [PR #187](https://github.com/huahuahu/chinese-calendar/pull/187) 合并为 `0183c047feeb99ae7414e9a7d9b823bd2368d8f2`。固定型号补充基于该 main，脚本和测试内容与本地已验证的 `b44346fa51e1363cba02b6ae12fc9e98ae87dd24` 一致。

## 实际结果

- 当前实现为 `Scripts/ensure_worktree_simulator.py`，使用 Python 3.9+、PyYAML 和 `simctl`；原 Ruby 实现已移除。按用户要求统一项目与 CI 的脚本语言，具体调整见方案记录。
- 同仓库 worktree 的配置引用受 Git common directory 文件锁协调；同工作区重复调用复用已有分配。分配锁不覆盖后续 App 运行或 UI 操作。
- 冲突时新建同型号、同 runtime 设备。创建失败不改配置；写回前发现外部修改时保留修改，并删除本次尚未登记的新设备。
- 保留本地 `.xcodebuildmcp/config.yaml`，从索引移除并加入忽略规则。共享 `config.example.yaml` 不含本机 UUID。旧分支和其他工作区要采用本次变更后才会获得新忽略规则。
- 已接入工作区初始化、本地普通测试/构建、build index 和截图测试；更新 Agent 工作流。CI 仍使用 runner 自身的选择逻辑；截图测试的显式设备覆盖保持有效。
- `Scripts/requirements.txt` 固定 `PyYAML==6.0.3`。CI 的 Test job 使用 `actions/setup-python@v6` 选择 Python 3.12，安装同一依赖文件后再执行测试。测试不再依赖 Ruby，缺依赖会明确失败。

## 验收证据

| 验收项 | 状态 | 证据 |
| --- | --- | --- |
| AC-01 | 已验证 | Python 集成测试检查已有配置逐字节保留；本机 Python 预检查和两次正式运行返回原 UUID，配置 SHA-256 不变 |
| AC-02 | 已验证 | Python 集成测试验证冲突时同型号同 runtime 创建并保留其他设置。初版实际分配时创建了当前工作区专用的 iPhone 18 Pro Max / iOS 27.0；迁移后 Python 实测复用此设备，本轮未额外创建设备 |
| AC-03 | 已验证 | Python 集成测试覆盖创建失败、无效/不可用 UUID、无效配置、缺失 runtime、dry-run 和配置被并发编辑；本机 Python dry-run 前后配置散列相同 |
| AC-04 | 已验证 | Python 四进程同 worktree 仅创建一次；两个 worktree 并发获得不同 UUID，并重新读取引用以避免多建；本轮实测发现的全部 8 份工作区配置散列不变 |
| AC-05 | 已验证 | 模板初始化和保留额外字段的集成测试通过；`git ls-files -- .xcodebuildmcp/config.yaml` 为空，`git check-ignore` 命中规则，本机文件仍存在 |
| AC-06 | 已验证 | 修改的 Bash 脚本通过 `bash -n`；本地 `resolve_ios_simulator_destination` 实际返回新 UUID；CI 分支和显式 snapshot override 经源码检查 |
| AC-07 | 本地及原实现远程 CI 已验证 | 新建隔离虚拟环境按 requirements 安装后通过测试；缺 PyYAML 的 `-I -S` 测试确认明确报错、无 Traceback、配置不变且不调用 xcrun。PR #187 的 `90af830` 在 Python 3.12 的 Test job 通过；固定策略补充须单独验证 |
| AC-08 | 本地已验证，补充 PR 的 CI 待完成 | `b44346fa` 的 29 项隔离测试全部通过，验证错误型号和版本拒绝、按固定组合查找及缺少 27.0 时失败；专项审查无未解决问题 |

初次 Python 迁移的验证环境为本机 Python 3.14.7 / PyYAML 6.0.3。`python3 Scripts/tests/test_ensure_worktree_simulator.py -v`：当时的 23 个隔离集成测试全部通过；在新建的 `.output/python-ci-validation` 虚拟环境中安装依赖后再次运行，23 项通过。测试使用临时真实 Git 仓库及 fake `xcrun`。`git diff --check`、索引差异检查、Bash 语法和 Python 3.9 语法兼容检查通过。后续审查修复及固定策略将测试扩展为 29 项；原实现的 Python 3.12 验证已由 PR #187 的 CI 完成。

初版实际分配后曾通过 XcodeBuildMCP `list_sims` 回读：新设备可用且为 Shutdown，原共享设备仍为 Booted。此项记录为初版分配时的证据；本轮 Python 迁移实测仅查询库存并复用已有设备，不将旧设备状态当作本轮启动验证。

本轮本地操作记录位于已忽略的 `.output/worktree-simulator/python-validation.json` 和 `python-allocation.log`；初版记录仍为 `validation.json` 和 `allocation.log`。机器 UUID 不进入共享配置模板。

## 固定截图模拟器：2026-10-24 补充

- AC-08 已验证：分配器固定为 iPhone 18 Pro Max / iOS 27.0，与现有截图入口一致。显式 UUID 的型号或 runtime 不符时失败；新建和同名选择不随已安装的新版本改变。
- 针对固定设备约束，执行 `python3 -B Scripts/tests/test_ensure_worktree_simulator.py -v`，29 项隔离测试全部通过，包含新增的版本和型号约束，以及已有截图 shell 入口回归测试。测试使用临时 Git 仓库和 fake Xcode 工具，没有创建真实模拟器或运行真实截图对比。
- `bash -n Scripts/test_snapshots.sh Scripts/ios_simulator.sh`、Python 3.9 语法解析和 `git diff --check` 通过。该记录为本地验证；用户已确认交付本补充，远程 CI 需在补充 PR 的最新提交上重新通过。

## 合并前审查与交付

- 关联：[PR #187](https://github.com/huahuahu/chinese-calendar/pull/187)，基于更新后的 `main` 提交 `2633da5af1eab55560acd0fd8b75e6fb27bf1025`。
- 使用 `review-changes` 的 allocator 和 integration 专项完成审查；确认并修复两项 P2。`integration-001`：截图入口保留分配器返回的 UUID，避免合法带注释/flow YAML 被正则漏读后选错设备。`allocator-001`：fake 工具改用正确引用解释器路径的 shell launcher，支持虚拟环境路径含空格。
- PR 范围内的 26 项隔离集成测试通过，新增真实 shell 入口回归覆盖截图 UUID、显式覆盖和 CI 设备选择。SwiftFormat 359 个文件中 0 个需修改；严格 SwiftLint 346 个文件、0 违规。
- 用户已确认交付固定 iPhone 18 Pro Max / iOS 27.0 的改动。当前配置继续决定 UUID，分配器同时验证设备必须符合固定型号和系统要求；其他配置字段保留。最终隔离集成测试共 29 项，普通 Python 和路径含空格的虚拟环境均通过。固定策略专项审查绑定 `90af830` → `b44346fa`，无新的可操作问题，原两项修复保持关闭。
- 远端回读确认 PR #187 已于 2026-10-24 14:50:52 UTC 合并，head 为 `90af8304364998e827af0088b6c161de1a73371c`；[CI run 40103545304](https://github.com/huahuahu/chinese-calendar/actions/runs/40103545304) 的 Lint and Format、Test，以及 GitGuardian 均通过。固定策略补充当时尚未纳入，因此基于合并后的 main 单独交付并重新等待 CI。
- 本文件记录提交时的验证。补充 PR 的最终 CI 及合并结果以该 PR 最新提交的检查和状态为准；旧 head 的通过不能替代新提交验证。

## 验证边界

- 本次未修改 App/Swift 代码。本地隔离测试仅验证设备分配及脚本接入，没有执行完整 iOS 构建、App 测试、截图对比、Preview 或真机交互；PR #187 的远程 Test job 已执行项目测试、截图对比及 App 构建，补充 PR 仍需独立通过。
- 合并前专项审查和提交已进行；远程 CI、合并状态见关联 PR。未进行额外真机交互验证。
- 检测范围是同一 Git 仓库登记的 worktree 配置；独立 clone、其他仓库和绕过配置的手动设备使用不在检测范围内。
