# Issue #146：App 原生分栏与详情栈组合结果

> 2026-10-22 后续决策：[Issue #159／#158](../issue-159-navigation-runtime/000-plan.md) 删除完整导航树快照与恢复，正常初始化独立校验，并将 Context 缓存集中到每个 Router 的内部 Store。本文中的恢复设计与验证保留为当时记录；运行时 path、Tab 和模态状态保留的契约继续适用。

- 方案：[000-plan.md](000-plan.md)；需求：[Issue #146](https://github.com/huahuahu/chinese-calendar/issues/146) 的 2026-10-20 简化方向
- 记录日期：2026-10-20；合并适配说明更新于 2026-10-21
- 合并前验证快照：以 `765fc18b2fb29b6e3f477d4822d73c55fd8eed7f` 为基线的实现；当时验证过的源文件摘要见 [source-manifest.json](evidence/source-manifest.json)。该摘要与 255 项测试保留为旧快照证据，不覆盖合并 #156 后的改动。
- 关联：[PR #157](https://github.com/huahuahu/chinese-calendar/pull/157)。
- 状态：2026-10-21 主干适配、三项修复与最终自动验证完成；已取得部分 Simulator 交互证据，全部分栏交互验收尚未完成。

## 实际实现

设置 → DEBUG → 调试操作 → 导航测试中增加普通栈、两栏、三栏和混合 Tab 入口。两栏／三栏可选择 sheet 或 full-screen；详情内可再次打开这些入口，用于嵌套验证。示例只使用两组、四个固定对象，不依赖完整日期数据下载或历史查询。

- [CalendarDebugSplitView](../../../Sources/ChineseCalendarUI/Debug/CalendarDebugSplitView.swift) 在 App UI 模块声明原生 `NavigationSplitView`。前栏只有 selection，detail 使用已有 `NavigationScopeView`；整页不重复包栈、不另挂 presentation host。
- [CalendarDebugSplitState](../../../Sources/ChineseCalendarUI/Debug/CalendarDebugSplitState.swift) 持有分类、对象、保留详情策略及原生布局 Binding。所有选择写入集中处理：不同对象清 path，重复对象保 path，分类变化按策略清空／保留，清选择同时清 path。重复选择被保留的旧对象不会把当前分类切回去。
- [CalendarHomeCoordinator](../../../Sources/ChineseCalendarUI/Home/CalendarHomeCoordinator.swift) 按实际详情导航 Context 的对象身份缓存 DEBUG 分栏状态，数据 identity 改变导致页面重建时保留 selection、布局与已有 path 的一致性。缓存于模态关闭完成后清理，不注册无效 Context，也不按层 ID 复活旧选择。
- [CalendarDebugSplitDetailView](../../../Sources/ChineseCalendarUI/Debug/CalendarDebugSplitDetailView.swift) 的子详情走统一 Destination builder，并与根内容共享 detail Context。控制区展示路径深度和系统布局 Binding，提供深 push、程序显示详情／前栏及原有 alert、Deep Link 动作。
- [CalendarDebugNavigationTabsView](../../../Sources/ChineseCalendarUI/Debug/CalendarDebugNavigationTabsView.swift) 组合普通栈、两栏、三栏；普通栈使用明确根 Destination，各分栏拥有独立 App 状态和 SDK 栈。关闭与再次打开遵循现有层身份失效规则。DEBUG 会话全部拒绝持久恢复。
- [NavigationContext.setPath](../../../Sources/NavigationCore/Routing/NavigationContext.swift) 返回是否接受整个路径。App 只有在返回 true 后才同步修改 selection，避免确认、alert 或关闭等待期间先换根。原 path setter 委托同一检查。原实现只移除 `.twoColumn`／`.threeColumn` 预留并保留 `.stack`；合并 #156 时沿用主干对整个容器枚举和入口白名单的删除，`setPath` 保留 Context／事务检查，不恢复页面位置权限。

正式三个 Tab 的页面结构和业务导航未调整。SDK 快照仍只描述它管理的路由与栈；App selection 和布局不是 SDK 的可恢复状态。外部请求沿用原有确认／真实关闭协调，示例不会在提交或批准阶段抢先修改业务选择。

## 2026-10-21 主干适配与验证

main 的 [#156 同构导航层](../task-2026-10-20-homogeneous-navigation-layers/001-result.md) 已替代 #152 的入口白名单和 Core 容器种类模型。本次冲突解决按以下边界接入：

- 根层与递归模态复用 `NavigationLayer`、`NavigationLayerContent` 和 `NavigationLayerSnapshot`；普通层使用 `.primary`，主 Tab 页面使用 `.mainTabs`，请求按 StackID 寻址，层入口与栈根仍分开。
- 不恢复 `allowedNavigationEntries`、`NavigationDestinationEntry` 或 `NavigationContainerKind`。Destination 只说明容器归属；App 分栏、混合 Tab 和已有主 Tab 都从实际所在层取得上下文，继续遵守一层同一栈一个宿主。
- 保留 Issue #146 的 App selection／布局与 SDK detail path 分工、`setPath(_:) -> Bool`、同层唯一呈现宿主、确认取消保原状态及真实关闭后应用请求的时序。
- 快照遵循主干的 `rootDestination + layer` 结构和容器归属切换失效规则；仍不加入分栏 selection 或布局恢复。

本轮整合基线为 `3d57050b9fbcc30619e78d552760f68b6d043650`（#156），合入的功能提交为 `e6d13c22b5cb2e9967995ce4cb7896a2f0d1b7dc`。最终 [源文件快照](evidence/integration-source-manifest.json) 与 [验证结果](evidence/integration-validation.json) 已覆盖冲突解决、分栏 push Context 注入及 App 缓存生命周期及空态关闭入口修复；带工作区修复的版本不能仅由功能提交 HEAD 表示。

测试结果分三个阶段：2026-10-20 合并前为 255 项；整合 #156 后的中间版本为 343 项，包含 18 个 App 分栏展开用例；最终代码为 347 项，包含 22 个 App 分栏展开用例。原 255 项及 #156 自身的 325 项均是各自历史快照，不能替代最终代码的验证。

| 合并后检查 | 结果与边界 |
| --- | --- |
| iOS 完整测试 | 原生 Xcode MCP `RunAllTests`：347 passed，0 failed／skipped／not run；同一 scheme 和配置 Simulator，iOS 27.0。包含 App SplitView 的 22 个展开用例，验证记录另列 43 个相关测试结果 |
| iOS 构建、安装与启动 | 最终代码通过原生 `DeviceInteractionInstallAndRun`，返回 `Application installed and running`；实际分栏交互单独记录 |
| 核心回归 | `setPath` 的事务拒绝、primary 根请求、根容器归属切换、旧 Context、分栏／混合 Tab 隔离通过；Core 不再按 Destination 入口位置拒绝路径，DEBUG 路由仍由 App 拒绝持久恢复 |
| App 缓存生命周期 | 新增 4 个展开用例：两栏／三栏的数据替换保留选择、布局及路径；混合 Tab 各自状态保持独立；关闭完成释放缓存，无效 Context 不注册，同 ID 新层不复活旧状态 |
| 格式、lint 与文案 | `./Scripts/format.sh --check`：288 文件、0 需格式化；`./Scripts/lint.sh`：277 文件、0 违规；文案校验 333 项通过 |
| 版本与差异 | 最终快照记录 26 个相对 main 修改文件的 SHA-256，包含三项修复；冲突标记清除，`git diff --check` 通过 |

首次整合测试构建发现参数化测试的静态参数工厂继承了 Suite 的 `@MainActor` 隔离；把只构造枚举和 UUID 的工厂标为 `nonisolated` 后，完整测试通过，测试主体继续在主 actor 执行。构建前准备的设备会话曾失效，重建会话后构建安装成功；这不是产品交互失败的证据。

### 分栏 push 的运行时修复

整合后的第一次 Simulator 检查成功打开两栏 sheet 并选择“对象一”，但点击“查看下一层详情”后发生崩溃，日志明确报告缺少 `NavigationContext<CalendarTab, CalendarDestination>`。根详情正常且状态测试通过，不能据此证明 push 页环境正确。

修复位于 [NavigationScopeView](../../../Sources/NavigationCore/SwiftUI/NavigationScopeView.swift) 的 destination 构建边界：对配置构建的 push 页面显式注入本栈导航 Context 和同一呈现入口，栈上的原有注入继续保留。没有新增局部 path、业务页面包装栈或导航 Context。复现与修复后的交互证据见 [本轮运行记录](evidence/integration-runtime/README.md)。

该修复后的有限复验通过了两栏 sheet 的真实列表选择、连续 push 两层、系统返回一层、重复选择保留 path、切换对象清空 path 和关闭；三栏 full-screen 通过分类 → 对象 → 详情 → push，并从 push 页打开独立测试 sheet、关闭子层返回父层、关闭全屏返回设置。每次 capture 均为 `Running`，进程保持不变，未观察到新崩溃、明显文字重叠或不可读布局。

这批运行证据对应 `Issue 146 Context Fix` 会话，早于下述 App 缓存生命周期修复，不能作为最终代码的完整 smoke。日志仍出现 `Update NavigationRequestObserver tried to update multiple times per frame.`；已覆盖操作完成，未观察到对应功能失败，但该警告未被声明为已修复。

### App 分栏状态的生命周期修复

Copilot 指出的根内容／path 生命周期错位已修复：数据 identity 改变会重建依赖数据的页面，若 selection 与布局仅由重建的分栏 View 持有，App 根内容可能重置而 SDK detail path 仍保留。最终实现将这些 DEBUG 状态保存在 `CalendarHomeCoordinator`，以真实 `CalendarNavigationContext` 的 `ObjectIdentifier` 为键，使数据替换前后的同一详情栈复用原状态；不同混合 Tab 仍使用各自状态。

关闭动画期间，旧页面继续读取原状态；呈现宿主完成 dismiss 后，`releaseDismissedContexts()` 才移除失效缓存。未缓存的无效 Context 只得到临时状态，不重新注册；即使 Core 恢复相同层 ID，新 Context 也不会取得旧缓存。[CalendarDebugSplitStateTests](../../../Sources/ChineseCalendarUI/Tests/CalendarDebugSplitStateTests.swift) 的新增 4 个展开用例覆盖上述边界，并包含在最终 347 项测试中。该缓存属于 App 当前会话，不改变 DEBUG 路由禁止持久恢复的规则。

最终缓存补丁版本重新构建安装后，通过 `Issue 146 Final Smoke` 会话验证混合 Tab：两栏真实选择对象一并 push 一层；三栏真实选择分类一、对象一并 push 一层；双向切回后两栈均保留各自对象一与 Push 1。全过程 PID `37470` 保持 `Running`，未观察到新失败。最终源码摘要、四组截图与层级及日志摘录见 [最终运行记录](evidence/integration-runtime/README.md)。数据 identity 替换与关闭释放的边界由上述自动测试覆盖，未将此次切 Tab 交互当成实际数据替换验证。

### 空态全屏的关闭入口

后续自动 review 指出：关闭 toolbar 挂在整个 SplitView 外，紧凑布局的前栏和空详情未显示关闭按钮，full-screen 在未选择对象时不能直接退出。修复将同一个 `presentation.dismiss()` 关闭入口放到分类、对象列表、未选分类空态及详情实际栈根内容内，不新增栈或呈现宿主。修复后完整 347 项测试再次通过，原生构建安装成功。`Issue 146 Empty Dismiss` 最终会话分别验证两栏 full-screen 未选对象、三栏 full-screen 未选分类：导航栏均显示“关闭”，点击后直接回到根设置页；全过程 PID `48741` 保持 `Running`，未观察到新失败。四组截图、层级与最终 View 摘要见 [运行记录](evidence/integration-runtime/README.md)。

## 合并前验证环境与结果（2026-10-20）

共享配置为本工作区 `ChineseCalendar.xcodeproj`、scheme `ChineseCalendar-iOS`、Simulator `chinesedate iPhone 18 Pro Max (885f)`（`16A9CAA7-45CE-46D5-8915-F61531FC617C`，iOS 27.0）。原生 Xcode MCP 无法通过工具审批后，按项目工作流回退到 XcodeBuildMCP，并核对了 session defaults。

| 检查 | 结果与边界 |
| --- | --- |
| iOS 构建与启动 | 两次 `build_run_sim` 成功，日历首页可见；不是分栏交互通过的证据 |
| 合并前快照的 iOS 测试 | `test_sim`，`CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`；255 项通过、0 失败、0 跳过。包含 Core 测试和新增 App 分栏状态测试；见 [测试摘录](evidence/validation.txt)。不适用于 #156 合并后的代码 |
| App 定向测试 | 9 个测试声明、11 个参数化用例；覆盖选择／根路径联动、分类保留、Tab／嵌套模态隔离、旧 Context、外部确认取消及真实关闭前状态、alert 拒绝修改和恢复边界 |
| Core 定向测试 | 扩展既有测试，覆盖 `setPath` 成功／非法整体拒绝、待确认、关闭等待、alert 各阶段、旧 Context 与静态 nil root 栈 |
| 格式 | `./Scripts/format.sh --check`：286 个文件，0 个需格式化；缓存目录不可写的提示不影响检查结果 |
| 严格 lint | `./Scripts/lint.sh` 检出 0 违规，但因缓存写入权限退出；使用 `swiftlint --strict --no-cache --quiet` 复核成功 |
| 文案 | `python3 Scripts/validate_localized_copy.py` 通过，331 项资源；新增 DEBUG 文案与 catalog 同步 |
| 差异与链接 | `git diff --check` 和本地文档链接检查通过 |
| Preview／真机 | 未运行，不据构建与测试推断 |

首次测试遇到 HEAD 原有的 [NavigationAlertSessionTests](../../../Sources/NavigationCoreTests/NavigationAlertSessionTests.swift) 编译问题：测试 Route 未遵循 `NavigationDestination`，4 处 Router 初始化缺少必填根 Destination。只修复该测试声明及初始化，随后完整测试通过。保留的三条编译 warning 分别来自原有 weak 局部变量、Void 返回值忽略和旧 SF Symbol 名称，本轮未扩大修改范围。

## 验收对应与证据阶段

下表结合最终自动验证与分阶段运行证据：Context 注入修复版覆盖两栏／三栏和嵌套模态，缓存修复版本补充混合 Tab 的选择、push 和双向切换保留，最终关闭入口版本补充两栏／三栏 full-screen 无选择时直接退出。未补充直接证据的交互缺口继续有效，不因源码或测试通过而关闭。

| 验收项 | 状态 | 证据与剩余范围 |
| --- | --- | --- |
| MC-01 组合边界 | 已验证（源码、构建） | App 原生 SplitView；前栏无独立 push 栈；detail 唯一 SDK 宿主；Core 不含栏目模型 |
| MC-02 选择与根路径 | 已验证（自动测试）；交互部分验证 | 早期复验覆盖真实列表选择、重复选择保 path、切换对象清 path；清空选择及分类保留／清理策略的实际交互仍待验证 |
| MC-03 Context 隔离 | 已验证（源码、自动测试）；交互部分验证 | 最终测试覆盖数据替换、不同 Tab／模态独立、关闭清理与旧 Context；早期复验覆盖子 sheet 独立 path 和返回父层；最终版本验证混合 Tab 两栈选择／push 和双向切回保留 |
| MC-04 宽窄与系统返回 | 部分验证 | 早期竖屏复验覆盖两次 push 后系统返回一层；程序换栏、布局 Binding 写回、旋转及宽窄切换仍待验证 |
| MC-05 模态和嵌套 | 已验证（源码、自动测试）；交互部分验证 | 早期复验覆盖两栏 sheet、三栏 full-screen、push 页打开子 sheet 和父子关闭；最终版本验证两栏／三栏 full-screen 无选择时关闭；全部递归容器组合仍待验证 |
| MC-06 外部请求与 alert | 已验证（自动测试）；交互未验证 | 取消保留、批准后真实关闭通知前不应用根目标、alert 期间不改 selection；未点击实际系统提示 |
| MC-07 既有业务回归 | 已验证（自动测试）；交互未验证 | 完整测试涵盖现有 Tab、年份选择、下载演示与 Deep Link 状态行为；实际打开／关闭链路待复验 |
| MC-08 工具验证 | 部分已验证 | 最终 iOS 构建／347 项测试、格式、lint、文案通过；早期 Simulator 复验与混合 Tab smoke 与最终空态关闭 smoke 已记录，完整交互矩阵未完成 |
| MC-09 文档 | 已验证 | README、NAV-07 与本任务方案明确 App／SDK 分工及恢复边界 |

## 历史交互阻碍与剩余范围

2026-10-20 曾两次依据最新语义快照点击“设置”Tab，XcodeBuildMCP 均返回成功，但后续截图和层级仍停留日历首页，未进入分栏入口；原因未确定，不把这点归因为产品失败。工具摘录与截图见 [历史交互证据](evidence/runtime/entry-tool-evidence.txt)。当天原生 `DeviceInteractionStartSession` 因自动审批服务 `model_not_supported` 没有执行，后续 Computer Use 返回 `Computer Use was not approved to use Device Hub`。这些是当时的工具限制；2026-10-21 原生设备交互已可用，并完成上文有限复验。

剩余实际交互包括分类切换的保留／清理策略、程序换栏与宽窄／旋转、完整递归容器组合，以及业务 alert／外部 Deep Link 的协调矩阵；Preview 和真机仍未验证。最终缓存版本的混合 Tab smoke 已记录；实际数据源替换和关闭释放未单独进行 UI 复测，不以自动测试代替。交付与合并状态以对应 PR 为准，本记录仅关联 Issue #146，不表示全部验收通过或 Issue 已关闭。
