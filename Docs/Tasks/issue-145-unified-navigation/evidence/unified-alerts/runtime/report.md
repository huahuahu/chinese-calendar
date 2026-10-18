# Simulator 交互验证限制

- 日期：2026-10-14；代码对应上一层 source-manifest.json。
- 工程／Scheme：当前 worktree 的 ChineseCalendar-iOS。
- Simulator：chinesedate iPhone 18 Pro Max (885f)，16A9CAA7-45CE-46D5-8915-F61531FC617C。
- 最终版本通过原生 `RunProject(attachDebugger: false)` 构建并启动，PID 32102，launch session 758bee0d80。

## 实际观察

原生交互可以捕获 App，但后续点击多次返回 `Session not found`。备用 XcodeBuildMCP 的设置 Tab 和月份按钮点击返回成功，刷新后的截图与 hierarchy 仍停留在相同日历页面；因此不能确认点击实际到达 App。检查未发现活动 debugger，也未修改用户断点。

随后使用 CUA 绑定实际承载 Simulator 的 Device Hub，AX 与截图读取成功，两次点击均返回 `-10005: noWindowsAvailable`。三条交互路径都未能进入设置调试入口，已停止重复尝试。

[最后一次成功截图](final-calendar-screenshot.png)及[对应 hierarchy](final-calendar-hierarchy.txt)只证明最终版本启动并显示日历；没有取得 alert 截图。成功构建、启动和无效点击，都不能证明 alert 行为正确或存在缺陷。

## 未验证

普通业务 alert、连续两个 alert、alert 按钮导航、alert 期间外部跳转、sheet／full screen 上的业务提示和后续离开确认，以及设置清理确认的点击流程，全部保留为未验证。没有执行清理下载数据。

三个已知原生会话 `Unified Alerts Verification`、`Unified Alerts Runtime`、`Unified Alerts Final Runtime` 均已调用 EndSession，均返回 `Session doesn't exist anymore`；没有继续运行的交互任务。最终 App 未主动停止。
