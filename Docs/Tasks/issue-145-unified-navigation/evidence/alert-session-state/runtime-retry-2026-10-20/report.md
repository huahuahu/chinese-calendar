# Issue #151 Simulator 交互复验

日期：2026-10-20（Asia/Shanghai）。本轮按用户“再试试”的要求，仅重试真实 Simulator UI 验证。未修改产品源码、重跑测试、下载或清理数据，也未提交或推送。

## 结论

六项目标流程均已完成实际点击与结果回读。连续业务提示按顺序显示；Alert 按钮导航成功；Sheet 和 Full-screen 中的外部导航请求均先保留业务提示，再显示离开确认；取消保留原页面身份，批准关闭模态并在朝代 Tab 新增一个 Push 页面。

| 场景 | 结果 | 关键证据 |
| --- | --- | --- |
| 连续两个 Alert | 通过：业务提示 1 → 好 → 业务提示 2 → 好 → 设置页 | [01](01-queue-first.png)、[03 settled](03-queue-second-settled.png)、[04](04-queue-dismissed.png)，各有同名 hierarchy |
| Alert 按钮导航 | 通过：确认“前往历史页面？”后，进入朝代 Tab，Push 为 1 | [05](05-button-navigation-alert.png)、[07 settled](07-button-navigation-settled.png)，各有同名 hierarchy |
| Sheet 外部导航取消 | 通过：业务提示关闭后出现离开确认；选择留在当前页面，仍为同一模态页面、Push 为 0 | [09](09-sheet-before.png)、[10](10-sheet-external-business-alert.png)、[12](12-sheet-leave-confirmation.png)、[14](14-sheet-cancelled-same-page.png)，各有同名 hierarchy |
| Sheet 外部导航批准 | 通过：再次触发同一流程，选择关闭并前往后退出 Sheet，朝代 Push 为 2 | [15](15-sheet-approve-business-alert.png)、[16](16-sheet-approve-confirmation.png)、[17](17-sheet-approved-result.png)，各有同名 hierarchy |
| Full-screen 外部导航取消 | 通过：离开确认选择留在当前页面后，仍为同一模态页面、Push 为 0 | [18](18-fullscreen-before.png)、[19](19-fullscreen-external-business-alert.png)、[20](20-fullscreen-leave-confirmation.png)、[21](21-fullscreen-cancelled-same-page.jpg)、[21 snapshot](21-fullscreen-cancelled-snapshot.json) |
| Full-screen 外部导航批准 | 通过：业务提示 → 好 → 离开确认 → 关闭并前往；全屏退出，朝代 Push 为 3 | [22](22-fullscreen-approve-business-alert.jpg)、[23](23-fullscreen-approve-confirmation.jpg)、[24](24-fullscreen-approved-result.jpg)，各有同名 snapshot JSON |

页面身份回读：

- Alert 按钮导航结果：`A7E40848-785D-4CB8-A5C1-A7CA33701C21`，朝代 Push 1。
- Sheet 取消前后：`85B03B39-C9B6-42D5-BF0C-ACA9E2136E69`，模态作用域 Push 0。
- Sheet 批准结果：`57F9460E-0A41-4BBE-B9DD-CF4D3EC6F370`，朝代 Push 2。
- Full-screen 取消前后：`1031610C-1CB0-44AF-9762-74748FFBFB90`，模态作用域 Push 0。
- Full-screen 批准结果：`599A8D29-2961-46DF-9027-0069051A9A83`，朝代 Push 3；最终 snapshot 仅有朝代页面和底部 Tab，无模态关闭控件或 Alert。

## 源码与运行上下文

- 基线 HEAD：`4f386d06d9a0e4b2b248ea83a3604dc08fc5ae1f`，验证对象为其上的本任务未提交源码。收尾重新核对 [source-sha256.txt](../source-sha256.txt)，7 个文件全部匹配。已有 [tests.txt](../tests.txt) 的 298 项测试结果由主任务保留，本轮未重跑，也未以测试结果替代 UI 结论。
- Project：`/Users/tigerguo/.codex/worktrees/bd46/Chinese-date/ChineseCalendar.xcodeproj`；原生 workspace：`workspace-VRZ9q1ZnTH`；scheme：`ChineseCalendar-iOS`。
- Simulator：`chinesedate iPhone 18 Pro Max (885f)`，iOS 27.0；UDID：`16A9CAA7-45CE-46D5-8915-F61531FC617C`；bundle ID：`com.tiger.suzhou.ChineseCalendar`。
- 已按 `.xcodebuildmcp/config.yaml` 与 `Docs/agent-workflows.md` 对齐原生 Xcode 上下文；XcodeBuildMCP fallback 使用前再次回读 defaults，project、scheme、Simulator 均匹配。
- 本轮原生会话：`Verify Issue 151 Retry October 20`。19:00 安装运行成功；原生捕获至 Full-screen 离开确认均为 `Running`。

## 工具恢复与清理

1. 原生 Xcode MCP 完成队列、按钮导航、Sheet 取消和批准，并进入 Full-screen 离开确认。尝试点击留在当前页面时出现 `Transport closed`；后续浏览器回读确认该点击尚未执行。
2. 按 `ios-simulator-browser` 工作流用本地缓存离线启动 scoped serve-sim。内置浏览器返回 `Browser is not available: iab`，因此仅新建一个 Chrome 镜像标签。live 镜像完成 Full-screen 取消；随后 XcodeBuildMCP screenshot 和 fresh snapshot 独立确认同一页面 UUID 与 Push 0。
3. 可选浏览器截图下载等待超时并重置 CUA，之后出现白屏和 `Debugger unattached`。停止该截图路径，转用本轮已可读取的 XcodeBuildMCP。最终关闭标签前，Chrome AX 已重新显示镜像为 live。
4. XcodeBuildMCP swipe 实际改变页面。首次点击“Alert 期间请求跳转历史”返回成功但 fresh snapshot 未变化；刷新后重试一次，业务提示真实出现。之后连续完成好、关闭并前往两次点击，均有 fresh snapshot 与 screenshot 回读；未沿用 2026-10-19 的输入失败结论。
5. 本轮 Chrome 标签 `1352341377` 及仅含该标签的 `🔎 Alert 151 验证` 组已关闭，AX 回读确认原有 GitHub 标签保留。serve-sim 终端 `18696` 经 Ctrl-C 与 scoped trap 正常退出（exit 0）；端口 3200 已无监听，没有剩余 serve-sim 进程。
6. 原生 `DeviceInteractionEndSession` 已尝试，但同样返回 `Transport closed`，未确认清理成功。未据此关闭 Simulator、停止其他工具进程或重置应用数据。

## 证据边界

本轮检查了以上普通点击路径的最终显示和页面身份。原生截图有时早于层级更新完成；例如 `02-queue-second.png` 是动画中的中间捕获，第二个提示以 `03-queue-second-settled.png` 为准。关键结果采用额外稳定捕获或后续 fresh snapshot；在这些稳定画面中未观察到 Alert 叠加或本任务相关的布局异常。

没有提供真实长耗时 async 业务 action 的调试场景，因此该完成时序、任意竞争时序、连续快速点击压力、真机和后台恢复仍未验证。六项通过不扩展为这些场景通过。2026-10-19 的工具受阻历史保留在 [旧报告](../runtime/report.md)，本报告记录本轮新增的交互证据。
