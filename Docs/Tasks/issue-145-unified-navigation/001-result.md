# Issue #145：统一页面导航与模态呈现结果

> 2026-10-18 单栏交付与合并前检查见 [013](013-single-column-merge.md)：重新执行测试、三项独立审查，并修正请求顺序和 Preview 环境问题。下文保留各阶段记录，历史“未提交／未审查”等描述仅指当时状态。

> 当前业务 alert 与导航协调见 [011](011-unified-alerts.md)，承接 [010：独立栈状态与上下文依赖](010-independent-stack-state.md) 和 [009：栈导航与呈现环境分离](009-separate-context-apis.md)。

> 用户于 2026-10-18 决定先合并现有单栏实现，多栏／SplitView 方案暂缓，不属于本次交付。

- 原始方案：[000-plan.md](000-plan.md)；当前范围：[011：统一业务 alert 与导航协调](011-unified-alerts.md)
- 关联：[Issue #145](https://github.com/huahuahu/chinese-calendar/issues/145)、[参考博客](https://huahuahu.github.io/ios-demo-projects/swiftui-navigation-handling/)
- 记录日期：2026-10-07
- 2026-10-14 业务 alert 统一：业务提示与页面模态共用数据驱动入口；已有 alert 时等关闭和按钮动作完成，再处理提示及外部导航。278 项测试和静态检查通过，交互证据与边界见 [011](011-unified-alerts.md)。
- 2026-10-13 内部职责分离：`NavigationContext` 改为独立栈状态与窄访问约束，保留根上下文身份与当前快照格式；263 项测试、App 构建、全量格式及 lint 均通过，见 [010 的结果与验证边界](010-independent-stack-state.md#结果)。
- 2026-10-11 增量：设置页 Debug 操作入口见 [007-debug-actions.md](007-debug-actions.md)，使用独立的本轮证据与源码快照；下文主体交付的快照及测试记录仍对应 2026-10-07。
- 2026-10-11 结构增量：每层一个可选子模态和多个独立栈，见 [008-presentation-layers.md](008-presentation-layers.md)。当前 API 与归属以 Core README 和导航规范为准；下文“当前实现／本轮验收”保留为 006 阶段记录，不代表 008 的交互验证已通过。
- 2026-10-12 目录整理：22 个 Core 文件按职责移动到 `State`、`Routing`、`Restoration`、`SwiftUI`，见 [源码目录](../../../Sources/NavigationCore/README.md#源码目录)。[移动清单与 SHA-256](evidence/directory-layout/relocation.json)确认内容逐字节不变，日志文件、测试文件和 Package 配置保持原样；历史证据继续保留当时的路径。同一 scheme／Simulator 的原生 `RunAllTests` 构建并通过 255 项测试（0 failed/skipped/not-run），strict lint、Core 的 SwiftFormat 和 `git diff --check` 通过。全量格式检查仍报告两个本轮未修改的 Debug 文件（`CalendarDebugNavigationView.swift`、`CalendarDebugNavigationActions.swift`）的 `docComments` 问题。此次仅调整目录，没有重跑界面交互。
- 分支：`codex/issue-145-unified-navigation`；基线 `88e3b74ae7bab044389a9a471346e16f9880bd1c`；实现尚未提交。
- 最终源码快照：[source-sha256-final.txt](evidence/scoped-router/source-sha256-final.txt)。本轮证据只使用 `evidence/scoped-router/`；其中 `source-sha256.txt` 是修复前快照，下方 no-core 和 [005](005-reuse-core-host.md) 是历史实现的证据。

## 006 阶段实现（历史记录）

用户最新授权完善 NavigationCore，覆盖 004 的不改 Core 限制。所有 present 接收强类型 destination，builder 根据数据创建 View。根 Router 管理 Tab paths 和模态树；每个 Tab、模态及其 push 页面从环境获得同类型 `NavigationContext`，操作其所属路径和子模态，不复制另一套状态。失效 context 不能操作后续复用 ID 的节点。

`NavigationScopeView` 统一 Tab 栈；`navigationPresentations` 统一根及递归节点的 sheet/full-screen、模态栈、context 注入、确认提示与关闭完成。App 的 `CalendarPresentedDestinationView` 只提供业务页面和数据环境，旧 `CalendarPresentationNodeView` 与重复 destination 注册 helper 已删除。`NavigationPresentationNodeView` initializer 有迁移要求，详见 [Core README](../../../Sources/NavigationCore/README.md)。

Deep link 有模态时先确认。取消保持路径及模态；批准关闭根树，等根关闭完成后再应用请求。相同请求去重，新请求使用新 ID；旧按钮不能批准新目标。已批准关闭过程中到达的新请求仍需单独确认。Core 统一管理手动与请求关闭窗口，`CalendarRouter` 不再维护第二处待执行请求。

快照支持 Codable 树往返及恢复后继续导航，保留节点 ID、创建新节点实例。忙碌恢复、重复节点 ID 和同层双模态均拒绝且不部分修改状态。App 的恢复 API 拒绝年份选择、下载详情和演示临时会话；本轮不自动持久化或修改用户启动偏好。

真实示例入口：历史朝代行长按可选“在弹窗中打开”或“全屏打开”；资料卡使用局部 push，同一资料卡长按可继续呈现子模态。年份选择器仍回传到发起页，下载及演示继续共享 feature 状态。

## 006 阶段验收（历史记录）

| 验收项 | 状态 | 证据与边界 |
| --- | --- | --- |
| SCOPE-01 | 已验证 | Core 测试覆盖 Tab/模态 path 隔离、局部 API、后台 Tab 拒绝 present；App 测试及 Simulator 覆盖历史普通 push 与 sheet 内 push |
| SCOPE-02 | 已验证 | 状态测试覆盖多层模态、重复打开、等待完成与失效 context；Simulator 验证嵌套 sheet/fullScreen、关闭子层回父层、下滑父层后重开 |
| SCOPE-03 | 已验证 | 状态测试覆盖过期 ID、关闭中独立确认、模态自行消失及根/子完成时序；Simulator 验证取消、批准、连续链接替换和嵌套整树关闭 |
| SCOPE-04 | 已验证 | Codable 往返、相同 ID 新对象、恢复后导航、非法/忙碌拒绝、App 临时会话边界 |
| SCOPE-05 | 已完成并验证实际入口 | Core README 含独立于日历的完整双 Tab 示例；历史模态、年份选择器、下载演示和子详情已实测，归属见 [002](002-inventory.md) |
| SCOPE-06 | 已验证 | 最终源码 244 项 iOS 测试全部通过；Debug buildForTesting、Release 构建、format、strict lint、本地化 263 项和 diff check 通过；Simulator 结果见下文 |

自动化环境为 `ChineseCalendar.xcodeproj` / `ChineseCalendar-iOS`，Simulator `chinesedate iPhone 18 Pro Max (885f)`（iOS 27.0，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`）。[测试摘录](evidence/scoped-router/tests.txt)、[Release 构建记录](evidence/scoped-router/release-build.txt)。最终 22:31 的测试运行覆盖 alert 修复、失效 context 新断言与年份定位修复：244 passed、0 failed/skipped/not-run。Debug buildForTesting 成功（5.081 秒）；Release 成功（121.601 秒，无报告 warning/error）。Release 使用 XcodeBuildMCP，因为原生构建工具不提供 configuration 参数；临时 session defaults 已恢复。

Simulator 的完整场景、截图及版本边界见[设备验证报告](evidence/scoped-router/runtime-report.md)：历史 Tab push、模态内 push、嵌套 sheet/fullScreen、子层关闭、父层下滑与重开、Deep Link 取消/批准/替换及整树关闭、下载演示子详情均通过。最终 picker 修复后补验了首次 2026、重开、2024 深链后定位、2025 选择回传、公元前 1 年与公元 1 年定位。完整日期库保留，设备验证会话已结束。

交互验证修复了两类生命周期问题：确认提示改用具备身份替换语义的集中宿主，且由带 ID 的按钮动作消费请求，避免系统先写回 nil 误取消；年份选择器等待 List 首次有效滚动几何后定位，并观察选中年份，避免在列表尚未布局时消耗首次定位。没有添加固定延时或修改日期选择的业务真值。03/04、10/11、12 是修复前失败证据，13–19 是最终提示实现证据，20–26 是 picker 修复后的证据；仅修改 picker 后没有重复整套 alert 交互矩阵。

没有启动独立产品 review、没有提交、推送或创建 PR。真机、VoiceOver、本轮 Preview、其他设备/OS 与横屏未验证；跨启动自动恢复是明确未接入的产品行为。

## 历史阶段说明

先前 no-core 实现和 005 宿主复用的证据只代表当时源码。下面保留 no-core 结果供追溯，其中“本版／当前”均指当时快照；其不改 Core、业务层等待窗口和旧宿主的说明已被本轮实现替代。

## no-core 阶段实际结果与范围调整（历史）

用户在首版实现后要求不修改 NavigationCore package。本版已撤回 `Sources/NavigationCore`、`Sources/NavigationCoreTests` 的全部修改，包含 README；`Sources/Package.swift` 也保持不变。[差异检查](evidence/no-core/core-unchanged.txt)记录该边界。首版的 Core 扩展不再属于最终实现。

年份选择器、真实下载详情、设置的 DEBUG 下载演示及其子详情统一使用 `CalendarRouter.navigation` 的 presentation 树。页面通过 coordinator／`CalendarRouter.presentSheet`、`presentFullScreen` 发起展示，由原 Core API 创建节点；业务内容页面不再另设模态 Boolean。SwiftUI 的 `.sheet(item:)`、`.navigationFullScreenCover` 保留在 ChineseCalendarUI 的集中宿主，负责把 Router 节点显示出来。

本次必要适配位于业务层：

- `CalendarRouter` 递归读取原 Core 节点，按 ID 调用原有关闭能力，没有复制树。深链接主动关闭仍使用 Core 的 `submit`／延迟请求机制；仅在手动关闭已移除根节点、系统动画尚未完成且 Core 尚未接管时，业务适配器暂存最新请求，根 `onDismiss` 后交给 Core。同一请求只由其中一层等待。
- `CalendarNavigationHost` 绑定业务 router 的根节点属性，统一接收按钮、下滑、自动关闭的生命周期。根 owner 和宿主位于数据页面 `.id(storeIdentity)` 外；冷启动 deep link 标记也由稳定 owner 保存，避免重建后重放。
- `CalendarPresentationNodeView` 直接绑定原 Core 节点的 path 和子节点。普通模态提供一个 NavigationStack；下载演示保留两个有布局用途的 Tab 根栈，外层不重复包装。子 `onDismiss` 只释放业务会话，不能提前完成根树关闭协调。
- 年份会话关联发起页面的 selection、ModelContext 和原回调，destination 只带会话 ID；容器变化使旧会话失效。下载详情持续读取同一 store coordinator 的实时进度，nil 时只关闭对应节点。演示阶段及字号由演示 feature 保存并与子详情共享。

原 Core 通用 `NavigationPresentationNodeView` 及默认每节点一个 NavigationStack 的行为保持原样。公开 `CalendarHomeView` 保留独立业务宿主，根 App 直接复用 Tab 内容，避免重复宿主。完整调用链与允许保留的系统 API 见[入口盘点](002-inventory.md)。

建立 [Navigation.md](../../Conventions/Navigation.md) 作为 NAV-01–NAV-06 的唯一规范，接入 AGENTS、Docs 索引、SwiftUI convention 和中英文 review skill；按用户最新范围取消原计划中的 Core README 修改。代表性规则核对见[案例记录](003-convention-cases.md)。仅维护 skill，没有启动 `review-changes` 产品审查。

首轮交互还发现年份行与世纪分组共用 `Int` 滚动 ID，导致 BCE／CE 初始定位偏离。本次保留 `CalendarYearPickerScrollTarget.year(Int)` 类型隔离修复；不改纪年、查询、分组或年份过渡逻辑。年份及演示入口的重复触发保护保留迁移前的幂等语义。

## no-core 阶段版本与自动化证据（历史）

- 项目 `ChineseCalendar.xcodeproj`，scheme `ChineseCalendar-iOS`，native workspace `workspace-deC0lVsFJy`。
- Simulator `chinesedate iPhone 18 Pro Max (885f)`，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，iOS 27.0，Xcode 27.1 RC，竖屏。工具配置与 `.xcodebuildmcp/config.yaml` 已核对。
- 本版正式代码的 206 个 Swift 文件见 [source-sha256.txt](evidence/no-core/source-sha256.txt)，清单 SHA-256 为 `7dd1e2afe7c109dbe2dac4b57420c68c5e53d00a27b067f957846202588ffeb0`。清单覆盖 App、共享源文件及测试，项目配置保持基线。临时容器验证补丁单独记录，不能视作正式源码。
- 原生 Xcode `RunAllTests`：**227 passed，0 failed／skipped／not-run**，包括原 Core 测试、业务导航适配测试、8 个呈现会话测试及现有 picker／resolver／下载测试。原先放在 CoreTests 的三项新增验证已移至实际业务边界 `CalendarPresentationRoutingTests.swift`。详见[测试结果](evidence/no-core/tests.txt)。
- 原生 Debug 构建、安装运行通过；本版 Release compile-only 构建通过，耗时 123.7 秒，见 [Release 摘要](evidence/no-core/release-build.txt)。native `BuildProject` 没有 configuration 参数，故使用 XcodeBuildMCP `build_sim`，核对同一项目／scheme／Simulator，独立 DerivedData 并复用已解析的依赖；临时 session 配置覆盖已恢复。
- `./Scripts/format.sh --check`、`./Scripts/lint.sh`、`git diff --check` 通过；217 个格式检查文件无须修改，strict lint 206 个文件零问题，见[检查摘要](evidence/no-core/format-lint.txt)。
- 中英文 skill 入口与 NAV 规则对应，首轮 `quick_validate.py` 通过，该轮后 skill 内容未变；本版修改文档的本地链接已复核通过。

## no-core 阶段验收状态与交互证据（历史）

当前二进制的证据位于 `evidence/no-core/`；首版 `evidence/` 根目录的截图、226 项测试及 13 项定向测试保留为历史，不充当本版全量测试或宿主交互证据。未被本次范围修订改变的 BCE 行定位与历史 Tab 行为可参考首轮记录，并明确没有在当前二进制重复完整矩阵。

| 验收项 | 当前状态 | 证据与范围 |
| --- | --- | --- |
| NAV-AC-01 | 已验证 | 入口盘点、实际调用链和系统 API 复扫；按运行时可达性判断 DEBUG 页面 |
| NAV-AC-02 | 已验证 | 四个入口写入同一 Core 树；业务适配／会话测试和本版关键开关交互通过 |
| NAV-AC-03 | 已验证 | 本版选年回传、按钮／下滑取消重开、进度更新与完成自动关闭通过；受控切换时详情保留、旧 picker 失效、新 picker 使用新 context 回传。BCE／CE 滚动 ID 修复有首轮交互及本版既有 picker 测试证据 |
| NAV-AC-04 | 已验证 | 本版模态子树关闭、取消重开、连续请求最后生效及关闭后宿主复用通过；确定性测试覆盖手动关闭窗口、幂等、路径隔离。首轮完整热深链接／历史 Tab 矩阵保留在历史报告 |
| NAV-AC-05 | 已验证 | Core 目录零差异；业务会话与导航结构分离；本版演示及子详情无重复导航栏 |
| NAV-AC-06 | 已验证（按后续范围修订） | 单一 convention、AGENTS／Docs／SwiftUI／中英文 skill 接入及代表性案例完成；Core README 按用户要求保持原样 |
| NAV-AC-07 | 已验证 | 本版 Debug／Release、227 项测试、format／lint、关键交互、受控切换、正式源码恢复及最终冒烟均通过；完整证据边界见各报告 |

[本版常规交互报告](evidence/no-core/runtime-report.md)及证据 01–28 覆盖：

1. 2026 选至 2025 后回到原页，重开时定位及高亮正确；按钮关闭、下滑取消及各自重开正常。
2. picker 可见时连续提交 2020／2021 deep link，日志为 Deferred → Deferred → Applied，最终进入 2021；未残留模态。
3. 演示 50% 子详情关闭后父阶段保留，重开正常；子详情上 hot deep link 关闭 full-screen 和 sheet 整树，进入 2024。
4. 真实 coordinator 的模拟下载从 2% 更新到 28% 并完成；完成态后自动关闭，随后重新打开 2024 picker 正常。

## 受控容器切换与正式版本恢复

为验证真实 SwiftUI 宿主跨越 `.id(storeIdentity)` 的行为，临时在 `simulateFullStoreDownload` 完成分支加入仅由 `--issue-145-memory-switch` 启用的内存样例容器替换，并赋予新 identity；保留原完成态和两秒清理。补丁及哈希分别见[临时补丁](evidence/no-core/temporary-store-switch-harness.diff)、[临时源码哈希](evidence/no-core/temporary-store-harness-sha256.txt)。该验证不写入已有完整数据库。

[本版受控切换报告](evidence/no-core/store-runtime-report.md)及证据 30–46 记录：

1. **详情跨容器保持。** 13:26:04.817728 的日志 marker 证明新容器和 identity 已写入 state；之后的[完成态截图](evidence/no-core/34-switch-completed.png)仍显示下载详情，随后自动关闭。新 picker 仅有 8 个样例年份，证明页面已使用新 context。
2. **旧会话失效。** 重启恢复完整库后，在模拟下载期间打开旧 2026 picker。13:27:16.570305 切换后，[旧 picker 自动关闭](evidence/no-core/44-picker-dismissal-settled.png)；重开仅有样例年份，选 2025 返回当前页面的样例十二月。
3. **正式源码恢复。** 临时补丁已移除，206 个 Swift 文件逐项哈希与本版清单一致，Core 源码／测试／README 及 Package.swift 零差异，见[恢复检查](evidence/no-core/final-restoration.txt)。format、strict lint、diff 检查再次通过。原生 InstallAndRun 已安装不带验证参数的正式版本。最后冒烟确认[完整数据仍已安装](evidence/no-core/47-final-installed-data.png)、[2026 picker 恢复完整连续年份及正确高亮](evidence/no-core/48-final-full-picker.png)，关闭→重开→关闭正常。设备交互 session 已结束。

这证明受控的新 ModelContainer／identity 替换与呈现生命周期协作正常，符合计划中的受控切换选项；未将它记作真实网络下载、校验或完整库安装验证。

## 观察与未覆盖项

首轮在 BCE 日格观察到民用日期因文本较长出现逐字／数字换行。相关布局与日期文案本次未改，没有遮挡；它是独立视觉观察，不能据此认定为导航回归。修复前 picker 定位见历史证据 03，修复后公元前 2 年居中且勾选见[首轮截图](evidence/20-bce-picker-fixed.png)，公元 1 年也在首轮复验。

原有完整数据在验证前已安装，全程未清空。模拟下载与受控内存切换只证明进度／容器生命周期，不代表真实网络下载、校验或完整库安装。没有修改产品文案或数据格式，没有执行数据重建、真机验证、远端 CI、横屏、Duo 或 VoiceOver；最大字号在首轮演示及子详情验证，本版未重复。没有创建／发布 PR、合并或更新 Issue 状态。
