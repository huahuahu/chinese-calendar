# Issue #151 独立 Simulator 交互验证

> 本文保留 2026-10-19 的历史结果。用户要求再次尝试后的新证据见 [2026-10-20 重试报告](../runtime-retry-2026-10-20/report.md)。

日期：2026-10-19（Asia/Shanghai）。执行者：使用 `device-interaction` 技能的独立验证 subagent。验证范围仅限真实 UI；未修改产品源码，未重跑单元测试，未执行下载或数据清理。

## 结论

本次完成当前代码的安装运行和日历 → 设置的真实界面切换。随后原生设备会话失效；XcodeBuildMCP fallback 的点击虽返回成功，但 fresh snapshot 与截图未发生目标变化。未进入导航调试页，因此所有目标 alert 场景均保持**未验证**，不判定为通过或产品失败。

| 场景 | 状态 | 证据或原因 |
| --- | --- | --- |
| 当前代码安装并启动 | 已验证 | `DeviceInteractionInstallAndRun` 返回 `Application installed and running`；`01-native-calendar.*` 显示日历，应用状态 `Running`，PID 86213 |
| 日历 → 设置 | 已验证 | 根据层级 `hitPoint {306.0, 904.0}` 点击，`02-native-settings.*` 显示设置选中、调试操作入口可见 |
| 连续两个 alert 依次关闭 | 未验证 | 工具受阻，未进入导航调试页 |
| alert 按钮关闭后导航 | 未验证 | 同上 |
| sheet 上 alert 期间外部历史跳转，取消离开确认保留原页 | 未验证 | 同上 |
| sheet 上 alert 期间外部历史跳转，批准离开确认后关闭并跳转 | 未验证 | 同上 |
| full-screen 上的对应取消 / 批准流程 | 未验证 | 同上 |
| 真实 UIKit 动画与异步 action 完成时序 | 未验证 | 没有相应交互证据；单元测试不替代此结论 |

## 执行上下文

- 工作区：`/Users/tigerguo/.codex/worktrees/bd46/Chinese-date/ChineseCalendar.xcodeproj`。
- 原生 workspace：`workspace-VRZ9q1ZnTH`；scheme：`ChineseCalendar-iOS`。
- Simulator：`chinesedate iPhone 18 Pro Max (885f)`，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`。
- 已读取 `.xcodebuildmcp/config.yaml` 和 `Docs/agent-workflows.md`；`XcodeOpenWorkspace` 回读的 scheme 与 destination 均匹配。Fallback 的 `session_show_defaults` 同样匹配；仅以 `persist:false` 补充已安装应用的 bundle ID `com.tiger.suzhou.ChineseCalendar` 用于重新启动。

## 有界恢复过程

1. 接手的 `Verify Issue 151 Alert Lifecycle` 会话在首次 InstallAndRun 时返回 `Session with that key doesn't exist. To recover, start a new session by calling DeviceInteractionStartWorkspaceSession`。
2. 创建独占的 `Verify Issue 151 Alert Lifecycle Subagent` 会话，InstallAndRun 成功。原生 capture 显示日历；按其 hitPoint 点击设置后，capture 显示设置页（21:53–21:54）。
3. 下一次点击调试操作时会话失效；只读重捕获确认 `Session not found. It may have already been closed, or the identifier is wrong`。未持续重建原生会话。
4. Fallback 初次 fresh snapshot 显示 Simulator 主屏。按最新 elementRef 点击 Chinese Calendar 图标并重试一次仍是主屏。通过 `launch_app_sim` 成功重新启动已安装应用（PID 89983），capture 确认日历页（`03-fallback-calendar-before.*`）。原生会话丢失与主屏出现的原因未确定；现有日志不足以归因为应用 crash。
5. 根据最新 fallback snapshot 点击设置 `e194`，工具返回成功，目标坐标 `{306, 885}`，但新 snapshot 仍为日历 `selected=1` / 设置 `selected=0`。刷新后按新 ref `e193` 重试一次仍未变化；两次结果的 `screenHash` 均为 `00ruibx`，见 `04`–`06` JSON 与 `06-fallback-after-retry.jpg`。因此停止扩大排障。
6. 已调用 `DeviceInteractionEndSession` 清理新建会话，返回 `Session doesn't exist anymore`。

## 界面与日志观察

已显示的日历和设置页中未观察到本任务相关的文本重叠或布局异常。原生设置页切换日志有一条 `Update NavigationRequestObserver tried to update multiple times per frame.`（21:54:25.874）；当时设置页面仍正常显示。该警告未作因果诊断，不能据此判断与 Issue #151 生命周期改动有关。原生日志保存在 `02-native-settings-logs.txt`。

本报告只陈述本次运行证据；不将其他自动化检查或旧 Issue #145 记录计为本次交互通过。
