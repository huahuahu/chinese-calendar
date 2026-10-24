# Simulator 交互验证

> 历史证据：对应仍支持自定义启动参数的初版快照。用户后续要求统一为系统 `.onOpenURL`，现已删除 `--deep-link` 通道；本记录不代表最终快照重跑结果。

- 日期：2026-10-24，Asia/Shanghai。
- 范围：Issue #174 的启动参数、用户随后导航、系统 URL 和模态确认。
- 代码：基线 `dc76f6b5a531ff93fa90a23e7598c1440b318de0` 加 7 个 Swift 文件的未提交修改；源码快照 SHA256 为 `2cd21ca8c0dbfa9241ec8bce0826f6405ccda2575a23210fbd9eeab2782e7f62`，算法见 [自动验证](automated-validation.md)。
- 工程：`ChineseCalendar.xcodeproj`；scheme：`ChineseCalendar-iOS`；原生 workspace：`workspace-PFSn89tibK`。
- 设备：`chinesedate iPhone 18 Pro Max (885f)`，iOS 27.0，UDID `16A9CAA7-45CE-46D5-8915-F61531FC617C`。
- 工具：按共享配置调用 `XcodeOpenWorkspace`，返回的工程、scheme、目标均匹配；原生 `DeviceInteractionInstallAndRun` 和 `DeviceInteractionSynthesize`。原生会话失效后，核对 `session_show_defaults` 并使用 XcodeBuildMCP 的 `snapshot_ui`/`screenshot` 读取现场。
- 数据：仅安装内置基础数据，未下载完整日期数据库。

## 已完成的真实交互

| 时间／进程 | 操作 | 观察与边界 |
| --- | --- | --- |
| 19:58，PID 17567 | 原生临时启动参数 `--deep-link chinesecalendar://year/2025`，未编辑 scheme | 日历 Tab 被选中，出现带返回按钮的日历详情。进程表也读回相同 argv；导航日志为 `submit applied` 到 years 栈。基础数据页面显示“需要完整日期数据”，因此无法从内容确认具体 2025 年日历。见 [启动截图](01-year-launch-base-data.png)。 |
| 19:59，同一 PID | 读取 hierarchy 后点击返回按钮 hitPoint `(42,84)` | 返回按钮消失，仍在日历根页，没有重新 push。见 [返回后截图](02-manual-back-base-data.png)。 |
| 20:00–20:02，同一 PID | 点击设置 Tab；按 Home；重新激活 App | 进入设置，后台状态为 `RunningInBackground`；恢复前台后仍选中设置 Tab，未被启动参数覆盖。见 [恢复前台截图](03-settings-after-foreground.png)。这证明本轮操作后的可见状态；没有强制令同一 owner 的 `.task` 再执行，重复消费、首次 nil/无效输入等由自动测试覆盖。 |

交互前后均读取截图和 hierarchy；触控使用 hierarchy 的 hitPoint。关键日志与层级摘要见 [interaction-log.txt](interaction-log.txt)。上述稳定过程未观察到新增的重叠、裁剪或不可读文案。

## 退出、工具与并发阻碍

1. 最初继承的 `Issue 174 External Navigation` session 已失效，原生安装返回 `Session with that key doesn't exist`。创建 `Issue 174 External Navigation Verification` 后安装成功。第一轮 PID 15994 曾在没有本 agent 触控时由设置变为朝代；其归因未确定，不计入通过证据。
2. 为补足可见内容证据，20:02:49 带 `--deep-link chinesecalendar://dynasty/orthodox_sequence_qin_han_to_prc_tang` 启动 PID 22877。该 ID 来自 `Data/Processed/swiftdata_import/orthodox_periods.jsonl`，是完整的合法 orthodoxPeriodID。原生报告安装运行成功，日志显示 `submit applied` 到 history 栈；20:04:02 捕获却返回 `applicationState=Crashed`，画面是 SpringBoard，`GetConsoleOutput` 显示进程 `expired`。见 [退出后的截图](04-unexpected-exit.png) 和 [原生日志](native-unexpected-exit.log)。
3. 日志没有异常类型或业务调用栈；在 macOS DiagnosticReports 和该 Simulator CrashReporter 中未找到当日 Chinese Calendar/Jetsam 报告。只可确认该进程退出，不能据此认定产品崩溃、根因或本次改动的关联。
4. 仅恢复一次后，原生 capture 返回 `Session not found`。第三方 snapshot 仍是 SpringBoard，进程表已没有该 App。
5. 20:10 进程检查发现另一个工作树正在使用同一 UDID：PID `28631`、父进程 `28599`，命令为 `xcodebuild ... -workspace ChineseCalendar.xcodeproj/project.xcworkspace -scheme ChineseCalendar-iOS -destination platform=iOS Simulator,id=16A9CAA7-45CE-46D5-8915-F61531FC617C ... build-for-testing`，result bundle 和 DerivedData 均位于 `/Users/tigerguo/.codex/worktrees/1a3c/Chinese-date/.output/`。这是并发使用同一设备的证据，尚不能证明它导致了之前退出。没有终止其他任务的进程。

## 独立设备补验

为继续验收，创建 `Chinese-date Issue 174 Verification 3a9f`，UUID `33F6A450-E1BC-410E-A5FE-F6C7190D19E4`，同样为 iOS 27.0 / iPhone 18 Pro Max。没有 clone 共享设备。两 MCP 均缺少创建／删除 Simulator 和系统 open URL 操作，因此这些操作使用指定 UUID 的 `xcrun simctl`；未修改其他设备。

临时设备已同步到本工作区配置、原生 Xcode destination 和第三方 session defaults。原生独立 session 的首次安装运行返回 `Session initialization timed out`，直接改用第三方安装已有构建并启动。构建来源为：

```text
/Users/tigerguo/Library/Developer/Xcode/DerivedData/ChineseCalendar-diyedphburyudjhdfjnrwjjzoyxw/Build/Products/Debug-iphonesimulator/Chinese Calendar.app
```

该 DerivedData 的 `info.plist` 读回 `WorkspacePath=/Users/tigerguo/.codex/worktrees/3a9f/Chinese-date/ChineseCalendar.xcodeproj`；`Chinese Calendar.debug.dylib` SHA256 为 `66e96c1e48fac9274696aa56cf30befe698a215b6541550ba7984b1b607d49ad`。

| 场景 | 结果与证据 |
| --- | --- |
| 合法启动参数 | `launch_app_sim` 传入 `--deep-link chinesecalendar://dynasty/orthodox_sequence_qin_han_to_prc_tang`。PID `47693` 的进程表也读回相同参数。实际显示“唐”、21 帝王、63 年号、618—907。见 [独立设备启动截图](05-isolated-launch-tang.jpg)。 |
| 合法系统 URL | `xcrun simctl openurl 33F6A450-E1BC-410E-A5FE-F6C7190D19E4 chinesecalendar://dynasty/orthodox_sequence_qin_han_to_prc_qin`。系统先显示 `Open in Chinese Calendar`；第三方两次 tap 返回成功但画面未变。原生 synth 又返回 `Session not found`。最终 CUA 在 Device Hub 中核对窗口标题、Info Inspector 的完整 UUID 后点击真实 AX `Open`，实际变为“秦”、3 帝王、0 年号、前221—前206。PID 仍为 `47693`；20:40:28 日志记录 history 栈 `submit applied` 和 `setPath applied`，见 [日志摘录](isolated-interaction-log.txt)。 |
| 不支持的系统 URL | 同一 UUID 投递 `chinesecalendar://unsupported/2026`，随后读取真实 AX 与截图，仍停在“秦”，返回按钮、3/0 和起讫信息不变。直到清理前 PID `47693` 仍存活。见 [不支持 URL 后截图](06-isolated-qin-after-unsupported.jpg)。 |

两次 MCP tap 无效果属于本轮工具交互失败，不能记为 App 控件缺陷。CUA 可成功点击系统 AX 按钮，但 Device Hub 会被其他活动切回共享窗口；每次操作前都重新核对窗口名称，未对共享设备画面点击。App Tab 栏在 CUA 层级中只有无子项的容器，截图坐标点击及一次校正重试均返回 `windowNotFoundAtPosition`，因此没有进入设置中的 DEBUG 模态，不再扩展工具修复。独立设备上上述已成功流程没有观察到产品退出或布局异常。

## 仍未验证

- 真实模态中外部链接的取消保留和批准关闭后跳转：尚未执行。基础数据状态没有年份选择器，可在独占设备后使用 App 中现成的 DEBUG 页面模态。
- `year/2025` 的具体年月内容、完整数据下的年份选择器、真机：未验证。
- 同一 owner 的真实 `.task` 被重新执行：本轮没有直接强制触发；启动入口的一次消费合同由自动测试覆盖。

## 清理确认

- 临时设备已 shutdown 并 delete，设备目录不存在；没有终止其他工作树进程。
- 原生两个交互 session 的结束调用都返回 `Session doesn't exist anymore`。
- `.xcodebuildmcp/config.yaml` 已与备份逐字比较一致；恢复前后 SHA256 均为 `b722b0c529a80d1725f38fd43571e15b846ba9e5c5d45642c8a0eef34082112b`。
- 第三方 defaults 已恢复原工程、scheme、原设备名/UUID，清除临时增加的 bundleId；原生 Xcode destination 也已读回 `chinesedate iPhone 18 Pro Max (885f)`。
- 再次计算生产／测试修改的源码快照 SHA256，仍为开头的 `2cd21ca8c0dbfa9241ec8bce0826f6405ccda2575a23210fbd9eeab2782e7f62`。本验证只新增交互证据，未改生产／测试代码、scheme 或结果主文档。
