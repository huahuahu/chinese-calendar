# Issue #146：App 原生分栏与详情栈组合结果

- 方案：[000-plan.md](000-plan.md)；需求：[Issue #146](https://github.com/huahuahu/chinese-calendar/issues/146) 的 2026-10-20 简化方向
- 记录日期：2026-10-20
- 验证快照：以 `765fc18b2fb29b6e3f477d4822d73c55fd8eed7f` 为基线的本轮实现；实际验证过的源文件摘要见 [source-manifest.json](evidence/source-manifest.json)
- 状态：实现与自动验证完成；Simulator 分栏交互受工具权限／输入问题阻碍，尚未完成全部验收

## 实际实现

设置 → DEBUG → 调试操作 → 导航测试中增加普通栈、两栏、三栏和混合 Tab 入口。两栏／三栏可选择 sheet 或 full-screen；详情内可再次打开这些入口，用于嵌套验证。示例只使用两组、四个固定对象，不依赖完整日期数据下载或历史查询。

- [CalendarDebugSplitView](../../../Sources/ChineseCalendarUI/Debug/CalendarDebugSplitView.swift) 在 App UI 模块声明原生 `NavigationSplitView`。前栏只有 selection，detail 使用已有 `NavigationScopeView`；整页不重复包栈、不另挂 presentation host。
- [CalendarDebugSplitState](../../../Sources/ChineseCalendarUI/Debug/CalendarDebugSplitState.swift) 持有分类、对象、保留详情策略及原生布局 Binding。所有选择写入集中处理：不同对象清 path，重复对象保 path，分类变化按策略清空／保留，清选择同时清 path。重复选择被保留的旧对象不会把当前分类切回去。
- [CalendarDebugSplitDetailView](../../../Sources/ChineseCalendarUI/Debug/CalendarDebugSplitDetailView.swift) 的子详情走统一 Destination builder，并与根内容共享 detail Context。控制区展示路径深度和系统布局 Binding，提供深 push、程序显示详情／前栏及原有 alert、Deep Link 动作。
- [CalendarDebugNavigationTabsView](../../../Sources/ChineseCalendarUI/Debug/CalendarDebugNavigationTabsView.swift) 组合普通栈、两栏、三栏；普通栈使用明确根 Destination，各分栏拥有独立 App 状态和 SDK 栈。关闭与再次打开遵循现有层身份失效规则。DEBUG 会话全部拒绝持久恢复。
- [NavigationContext.setPath](../../../Sources/NavigationCore/Routing/NavigationContext.swift) 返回是否接受整个路径。App 只有在返回 true 后才同步修改 selection，避免确认、alert 或关闭等待期间先换根。原 path setter 委托同一检查。Core 删除未实现的 `.twoColumn`／`.threeColumn` 预留，只保留 `.stack`，没有新增列类型、容器 Context、跨栏事务或快照格式。

正式三个 Tab 的页面结构和业务导航未调整。SDK 快照仍只描述它管理的路由与栈；App selection 和布局不是 SDK 的可恢复状态。外部请求沿用原有确认／真实关闭协调，示例不会在提交或批准阶段抢先修改业务选择。

## 验证环境与结果

共享配置为本工作区 `ChineseCalendar.xcodeproj`、scheme `ChineseCalendar-iOS`、Simulator `chinesedate iPhone 18 Pro Max (885f)`（`16A9CAA7-45CE-46D5-8915-F61531FC617C`，iOS 27.0）。原生 Xcode MCP 无法通过工具审批后，按项目工作流回退到 XcodeBuildMCP，并核对了 session defaults。

| 检查 | 结果与边界 |
| --- | --- |
| iOS 构建与启动 | 两次 `build_run_sim` 成功，日历首页可见；不是分栏交互通过的证据 |
| 最终代码的 iOS 测试 | `test_sim`，`CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`；255 项通过、0 失败、0 跳过。包含 Core 测试和新增 App 分栏状态测试；见 [测试摘录](evidence/validation.txt) |
| App 定向测试 | 9 个测试声明、11 个参数化用例；覆盖选择／根路径联动、分类保留、Tab／嵌套模态隔离、旧 Context、外部确认取消及真实关闭前状态、alert 拒绝修改和恢复边界 |
| Core 定向测试 | 扩展既有测试，覆盖 `setPath` 成功／非法整体拒绝、待确认、关闭等待、alert 各阶段、旧 Context 与静态 nil root 栈 |
| 格式 | `./Scripts/format.sh --check`：286 个文件，0 个需格式化；缓存目录不可写的提示不影响检查结果 |
| 严格 lint | `./Scripts/lint.sh` 检出 0 违规，但因缓存写入权限退出；使用 `swiftlint --strict --no-cache --quiet` 复核成功 |
| 文案 | `python3 Scripts/validate_localized_copy.py` 通过，331 项资源；新增 DEBUG 文案与 catalog 同步 |
| 差异与链接 | `git diff --check` 和本地文档链接检查通过 |
| Preview／真机 | 未运行，不据构建与测试推断 |

首次测试遇到 HEAD 原有的 [NavigationAlertSessionTests](../../../Sources/NavigationCoreTests/NavigationAlertSessionTests.swift) 编译问题：测试 Route 未遵循 `NavigationDestination`，4 处 Router 初始化缺少必填根 Destination。只修复该测试声明及初始化，随后完整测试通过。保留的三条编译 warning 分别来自原有 weak 局部变量、Void 返回值忽略和旧 SF Symbol 名称，本轮未扩大修改范围。

## 验收对应

| 验收项 | 状态 | 证据与剩余范围 |
| --- | --- | --- |
| MC-01 组合边界 | 已验证（源码、构建） | App 原生 SplitView；前栏无独立 push 栈；detail 唯一 SDK 宿主；Core 不含栏目模型 |
| MC-02 选择与根路径 | 已验证（自动测试）；交互未验证 | 新 App 测试通过；尚须真实点击列表、换根、清空和重复选择 |
| MC-03 Context 隔离 | 已验证（源码、自动测试）；交互未验证 | Context 复用、不同 Tab／模态独立、旧 Context 拒绝修改均有测试；宿主交互仍待验证 |
| MC-04 宽窄与系统返回 | 未验证 | 原生布局 Binding 已接入并可观察；未能执行分栏深 path、程序换栏、系统返回、旋转／宽窄切换 |
| MC-05 模态和嵌套 | 已验证（源码、自动测试）；交互未验证 | 自带容器入口跳过默认栈，沿用唯一呈现宿主；sheet／full-screen 实际展示仍待验证 |
| MC-06 外部请求与 alert | 已验证（自动测试）；交互未验证 | 取消保留、批准后真实关闭通知前不应用根目标、alert 期间不改 selection；未点击实际系统提示 |
| MC-07 既有业务回归 | 已验证（自动测试）；交互未验证 | 完整测试涵盖现有 Tab、年份选择、下载演示与 Deep Link 状态行为；实际打开／关闭链路待复验 |
| MC-08 工具验证 | 部分已验证 | iOS 构建／测试、格式、lint、文案通过；Simulator 分栏交互未完成 |
| MC-09 文档 | 已验证 | README、NAV-07 与本任务方案明确 App／SDK 分工及恢复边界 |

## 交互阻碍与后续

两次依据最新语义快照点击“设置”Tab，XcodeBuildMCP 均返回成功，但后续截图和层级仍停留日历首页，未进入分栏入口；原因未确定，不把这点归因为产品失败。工具摘录与截图见 [交互证据](evidence/runtime/entry-tool-evidence.txt)。原生 `DeviceInteractionStartSession` 因自动审批服务 `model_not_supported` 没有执行；后续 Computer Use 返回 `Computer Use was not approved to use Device Hub`，因此未取得替代交互入口。

需要恢复可用的设备交互权限后，继续执行 MC-04 及其余标注的 Simulator 流程，再判定全部验收是否通过。本实现阶段未运行专项代码 review；交付与合并状态以对应 PR 为准，本记录不表示 Issue 已关闭。
