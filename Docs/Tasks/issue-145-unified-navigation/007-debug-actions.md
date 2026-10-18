# Debug 操作入口

- 日期：2026-10-11；续接 [006](006-scoped-router-plan.md)。
- 目标：通过 Debug 操作菜单直接执行导航与下载调试，App 继续作为 NavigationCore 的数据驱动示例。
- 实现前方案：提供仅 DEBUG 可见的菜单，分为导航测试与下载调试。用户确认入口位于设置页现有的 Debug 分区，替换该分区的两个独立下载按钮。新增携带 UUID 的导航测试 destination，同一测试页可以 push、sheet、full-screen，并继续嵌套。页面显示当前作用域与 path 深度；返回及关闭操作只作用于当前 context。跨 Tab 和模拟 Deep Link 经过根 Router 的确认协调。
- 下载动作复用既有进度模拟与布局预览；不添加清空数据等新动作。DEBUG 路由不参与跨启动恢复，不进入 Release 构建。核心框架无需为调试入口增加业务代码。
- 验收：入口可达、当前 Tab push、模态内 push/嵌套、返回/关闭、Deep Link 取消/批准、既有下载动作；Debug/Release 构建、相关 iOS 测试及静态检查。Simulator 验证按 device-interaction 技能交由专用 Agent。

## 结果

入口位于 **设置 → 调试 → 调试操作**，仅 Debug 构建可见。菜单和导航测试页复用 `CalendarDebugNavigationActions`，后续类别在 `CalendarDebugActionsMenu` 中扩展。

| 类别 | 操作与行为 |
| --- | --- |
| 当前层导航 | Push 新测试页、Sheet 打开测试页、全屏打开测试页；每次生成新的页面 UUID |
| 返回与关闭 | Pop 只影响当前 path；关闭只作用于当前模态；无可用目标时禁用对应按钮 |
| 跨 Tab 与外部链接 | 在历史 Tab Push 测试页；模拟今年的 Deep Link；有模态时走根 Router 的离开确认流程 |
| 下载调试 | 复用完整数据下载模拟与下载进度布局预览 |

导航页显示当前作用域、当前层 Push 页数和页面 ID，可从任意测试页继续导航。路由传递 `.debugNavigation(id:)`，由 `CalendarDestinationView` 构建页面；导航栈和模态仍使用已有通用宿主。本轮未修改 NavigationCore 的 Swift 实现。

调试 destination、页面和菜单均使用 `#if DEBUG`。`CalendarRouter` 拒绝把调试路由作为可恢复快照，新增测试验证 JSON 往返后仍拒绝恢复，且不修改目标 Router 原状态。模拟 Deep Link 调用 `CalendarHomeCoordinator.openDeepLink`，本轮不验证系统 URL 分发。

代码状态：`codex/issue-145-unified-navigation` 的未提交工作区，包含此前 #145 实现；本轮 [源码快照](evidence/debug-actions/source-sha256.txt) 记录 225 个 Swift 文件及 String Catalog，共 226 项。

## 验证

- Debug：原生 Xcode `BuildProject(buildForTesting: true)` 成功。
- Release：XcodeBuildMCP `build_sim` 成功，132.455 秒，无报告 warning/error。原生工具不提供 configuration 参数，因此使用后备工具；临时 defaults 已恢复。[构建记录](evidence/debug-actions/release-build.txt)。
- 静态检查：`./Scripts/format.sh --check`、`./Scripts/lint.sh`、`python3 Scripts/validate_localized_copy.py`、`git diff --check` 通过；strict lint 检查 225 个文件，文案校验覆盖 282 项资源。
- 最终测试：21:02 的原生 Xcode `RunAllTests` 覆盖本轮最终源码，245 passed，0 failed/skipped/not-run，包含新增的调试路由恢复边界测试。[测试摘录](evidence/debug-actions/tests.txt)。
- Simulator：最新 Debug 安装成功；设置入口、说明及一级菜单中的“导航测试／下载调试”已确认。原生 session 多次失效，XcodeBuildMCP 快照与点击未稳定同步，CUA 也遇到窗口不可用；后续 Push/Pop、嵌套模态、Deep Link 取消/批准及下载子菜单动作保持未验证，不能沿用上次 Core 验证替代本轮新增入口的交互验收。见[设备报告](evidence/debug-actions/runtime-report.md)。

运行环境：`ChineseCalendar.xcodeproj` / `ChineseCalendar-iOS`，Simulator `chinesedate iPhone 18 Pro Max (885f)`，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，iOS 27.0 / SDK 27.1。最终源码快照 226 项均匹配。真机、VoiceOver、其他设备与横屏未验证。验证创建的原生 session 均确认已不存在，MCP defaults 与仓库配置一致且无临时 Release 配置。本轮没有自动提交、推送或创建 PR。
