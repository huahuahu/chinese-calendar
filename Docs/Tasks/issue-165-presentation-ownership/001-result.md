# Issue #165：发起方所有权与导航公开接口收敛结果

- 方案：[000-plan.md](000-plan.md)
- 关联：[Issue #165](https://github.com/huahuahu/chinese-calendar/issues/165)、[PR #170](https://github.com/huahuahu/chinese-calendar/pull/170)
- 状态：原实现及宿主映射／签名补充各有本地 506 条通过证据；XcodeGen 2.45.3 遗漏 SettingPresets 的 CI 安装问题已在干净副本复现，完整安装修复后直接全量测试也通过 506 条实例。PR #170 尚未合并，远程 CI 状态以 PR 最新提交检查为准；OWN-07／09 的具体覆盖边界见验收表。
- 记录日期：2026-10-23 至 2026-10-24
- 代码状态：`codex/issue-165-presentation-ownership` 的原实现提交 `edcf930e908a9bb9f5858fa23e52878da5d4adc0`，包含 126 个实现、测试与配置文件；提交 tree 为 `c4d7ffbbd74583560e603f42b20942e0c50bdb73`，对应下文 00:33 全量测试及原构建／静态检查证据。此后文档与 evidence 已单独提交；首轮 CI 的 head 为 `f2ebde6d56f5d164952313497d00ae56cc50823e`。宿主映射与 Simulator 签名补充的验证版本以该 `f2ebde6d` base 加 [ci-configuration.json](evidence/validation/ci-configuration.json) 中 `project.yml`／`Scripts/test.sh` 的 `configurationSHA256` 定位，已取得独立的全新 DerivedData 成功结果，随后提交为 `6cad5a9b13ce54a8f9077a62d20aa2a57dd6e449`。该轮使用本地完整安装的 XcodeGen 2.46，不能证明 CI 的 2.45.3 安装环境已修复。后续 SettingPresets 安装修复以 `6cad5a9b` base 加同一证据的 `xcodegenInstallationFix.workflowSHA256` 定位，已在 CI 同版 2.45.3、干净源码副本和全新 DerivedData 下完成直接全量回归。实施前基线为 `224b13aa38390c9f8f677ac9ab29a0980853655c`。

## 已接入的实现

公开呈现返回 Submission 与本次 handle，业务资源及 `onFinish` 保存在 SwiftUI endpoint 的 render record 中。Router 只保存结构和内部 lifetime，lifetime 弱引用 record observer；拒绝时撤回记录且不回调，已接受请求沿单次结束合同清理。节点、队列、内部身份、有效性查询和手动完成接口收回库内。接线位置见 [Endpoint](../../../Sources/NavigationCore/SwiftUI/Presentation/NavigationPresentationEndpoint.swift)、[RenderRecord](../../../Sources/NavigationCore/SwiftUI/Presentation/NavigationPresentationRenderRecord.swift) 和 [Lifetime](../../../Sources/NavigationCore/Routing/Presentation/NavigationPresentationLifetime.swift)。

年份、下载演示、正式下载详情、历史和 DEBUG 分栏分别由来源 feature／完整容器持有资源；年份配置直接连接具体 session、selection、ModelContext 和结果接收方，提示 route 携带结构化错误值。集中会话字典与导航扫描清理链已从当前实现移除。源码、自动测试与实际交互的证据按下表分别列明。

页面的接手点由 [NavigationModalLifecycle](../../../Sources/NavigationCore/SwiftUI/Presentation/NavigationModalMount.swift) 在 `makeUIViewController` 创建控制器时同步调用 `claim`，不以 builder 求值或 `onAppear` 代替。probe 记录实际 presenter／window 关联；已挂载模态依靠真实 dismiss 或未取消的 transition completion 完成，只有从未挂载的同一个 probe 销毁才可结束被丢弃的界面。dismantle 不直接报告完成，晚到 probe 不能复活已结束请求。

宿主拆除期间由内部关闭对象保留 render record；Router 销毁时保留后代 lifetime 的完成依赖，祖先实际关闭仍等待后代异步 alert handler。[原生 alert presenter](../../../Sources/NavigationCore/SwiftUI/Alerts/NavigationSystemAlertHost.swift) 在关闭 completion 中清除本次 `currentAlert` 及同 ID 的 `desiredAlert`，由独立动作 Task 持有 definition／render lifetime 到动作完成。

## 实施调整与诊断依据

### 真实呈现需要 App host 与前台 scene

首轮独立 SwiftPM runner 的诊断显示 `connectedScenes` 为空。使用相同窗口环境的纯 UIKit 对照和 Core 呈现都停在 `isBeingPresented == true`、被呈现控制器 `view.window == nil`；Core 请求的 `hostClaimed` 已为 true。这个对照说明该轮失败首先暴露了宿主环境缺失，不能把 `onAppear` 或提交 `.applied` 当作系统呈现成功，也不能据此跳过真实关闭验收。

[project.yml](../../../project.yml) 现在显式声明 App-hosted `ChineseCalendarUITests`，配置 `TEST_HOST` 与 `BUNDLE_LOADER`，由 `ChineseCalendar-iOS` 承载全部 App 测试以及 Core 的两个 physical host 文件。[Sources/Package.swift](../../../Sources/Package.swift) 移除原独立 App test target，并从 SwiftPM `NavigationCoreTests` 排除这两个物理文件；其余 Core 状态与协调测试仍保留。scheme MacroExpansion 只提供展开上下文，不会替代 test host 配置。

两个真实窗口 helper 共用 [NavigationTestWindowLease](../../../Sources/ChineseCalendarUI/Tests/NavigationTestWindowLease.swift)：串行获取前台 `UIWindowScene`，用 `UIWindow(windowScene:)` 创建窗口，等待实际挂载条件；缺少前台 scene 明确失败。取消等待、挂载错误和关闭均释放相应责任，并恢复先前 keyWindow。UIKit completion 超时仍记录测试失败，随后清理窗口，避免阻塞后续测试。

这个环境调整保持原验收标准。App 业务集成测试继续普通 `import NavigationCore`；Core 物理合同测试仍按内部测试使用 `@testable`，没有为测试新增公开或 SPI 后门。App-hosted 自动测试与实际 Simulator 手势、布局和业务交互分别记录。

### host 与 hosted test 的共享产品和资源环境

加入 App host 后暴露了两层重复链接，需分别处理。hosted test 最初除 `ChineseCalendarUI` 外还直接链接 Localization、Persistence、Core 和 NavigationCore 产品；Xcode 在 host／test 共享依赖图中将 UI 产品生成为 `PackageProduct.framework`，其传递依赖与测试 bundle 的静态副本同时存在，出现 `swift_isClassType` 崩溃。移除 hosted test 的额外产品后，后续全量运行仍报告 Persistence 等类同时存在于 UI framework 和 App 的 `Chinese Calendar.debug.dylib`；App 直接链接 Logging／Persistence 形成了第二处重复。

第二轮日志明确包含 `ChineseLunarDay`、`ChineseLunarMonth` 等类的 `is implemented in both` 警告。App 与 UI 产品的 `LinkFileList` 同时包含 Logging／Persistence／Localization／Core／Data 对象，二进制符号检查也发现重复的 Swift metadata。该轮既有错误分类的 `as?` 失败并落入通用 `.download` 分支，也有 `ChineseLunarDay.chineseLunarMonth.getter` 经 `swift_dynamicCastFailure` 崩溃；不能把这些现象直接归因于 SwiftData 数据内容或修改业务断言掩盖它们。当前 [project.yml](../../../project.yml) 使 App 与 hosted test 均只直接链接 `ChineseCalendarUI` 产品，使用 `SWIFT_INCLUDE_PATHS = $(inherited) $(BUILT_PRODUCTS_DIR)` 供源码显式导入传递模块。

2026-10-24 00:19:35（UTC+8）的定向 `RunSomeTests` 已取得共享 BuildForTesting 图的[限定链接证据](evidence/validation/source-boundary.md#0019-定向测试构建的链接结论)：`ChineseLunarMonth` 与 `ChineseCalendarFullSeedStoreInstallError` 的 metadata accessor／nominal descriptor 共四个符号，在 App 与 hosted xctest 中定义数均为 0，在共享 UI framework 中各为 1；两份 LinkFileList 没有重复 package 对象，console 的项目重复实现信息为 0。[linkage.json](evidence/validation/linkage.json) 保存 binary、符号和输入 hash。这不代表已穷举全部类型；后续全量回归与普通 App build 的成功结果在下文单独登记，不扩大该符号检查范围。

独立 package test runner 另有 `Bundle.module` 无法找到 Localization resource bundle 的 fatal error。资源实际生成于 `Debug-iphonesimulator` 产品目录，而该轮 runner 的默认候选位置未覆盖它。已核对 Xcode 生成的 accessor 在 Debug 下支持 `PACKAGE_RESOURCE_BUNDLE_PATH`，因此只在共享 scheme 的 test action 中设置为 `$(BUILT_PRODUCTS_DIR)`；没有修改生产资源定位逻辑或生成 accessor。[工程后处理脚本](../../../Scripts/fix_xcodegen_local_package_backlinks.py) 补充 package testables 时保留 XcodeGen 生成的 hosted test 与独立 UI test 引用。后续完整 scheme 的 506 条测试全部通过，其中 Localization target 的 14 条测试通过；详见[最终自动验证](#最终自动验证)。

### 系统确认按钮交互迁入独立 XCUITest

App 两条热 Deep Link 测试已经呈现真实 `UIAlertController`，但通过其辅助功能元素调用 `accessibilityActivate()` 返回失败，日志为 `.actionCannotBeActivated("留在当前页面")`／`.actionCannotBeActivated("关闭并前往")`。该路径不能充当系统按钮被点击的证据，现已删除对应 helper。[CalendarNavigationContextTests](../../../Sources/ChineseCalendarUI/Tests/CalendarNavigationContextTests.swift) 和 [CalendarRouterTests](../../../Sources/ChineseCalendarUI/Tests/CalendarRouterTests.swift) 保留提交请求、真实确认出现、两种 action 存在、来源模态仍挂载、path／Tab 未改变及结束回调未提前发生的断言，并将名称改为等待确认的实际覆盖范围。

取消与批准的完整按钮流程移入独立 `CalendarNavigationUIIntegrationTests` target 的 [CalendarDeepLinkUITests](../../../Tests/NavigationUIIntegrationTests/CalendarDeepLinkUITests.swift)，由测试进程通过公开 `XCUIDevice.shared.system.open(url)` 向正在运行的 App 投递系统 URL，再真实点击系统按钮。初次使用 `XCUIApplication.open(_:)` 时发生按 launch 语义重启，日志 PID 从 23999 变为 24143，因此那轮不能作为活动模态上的热链接证据。现用已有 DEBUG 菜单进入 sheet／fullScreen，以页面 UUID、来源 Tab、目标皇帝详情及整棵模态树消失作为 UI 断言；每条测试正常启动／终止 App，不新增生产测试后门。年份场景核对目标年确认文案、关闭两层模态和进入日历；精确内部路由与一次性结束顺序仍由 Core 合同测试承担。原 Core 取消／批准和异步完成测试完整保留，没有 skip，也没有用私有 action handler 或 App 手动完成通知代替真实点击。

打开 DEBUG 菜单时，Form 外层辅助功能行虽然带有“调试操作”名称且 `isHittable` 为 true，行中央并不位于实际 Menu 控件。当前按 `StaticText("调试操作")` 的实时坐标点击标签位置，随后选择导航测试项；不依赖外层同名行中央触摸。

独立 UI test target 使用 Swift 6 与 MainActor 默认隔离。最初把整个测试类标记为 `@MainActor`，与 `XCTestCase` 父类的非隔离要求冲突。现显式将测试类声明为 `nonisolated`，只在执行 UI 操作的测试方法和 helper 上标记 `@MainActor`；没有改变生产实现或按钮场景断言。

2026-10-24 00:31:17（UTC+8），native Xcode MCP `RunSomeTests` 在共享 scheme 与目标 Simulator 上定向执行以下两条测试，结果为 **2 passed、0 failed、0 skipped、0 notRun**：

- `testCancellingEmperorDeepLinkPreservesTheSheetAndSourceTabThenApprovalNavigates()`：系统皇帝热 URL 取消后保持原 sheet UUID，正常关闭后仍在来源设置 Tab；重开并批准后进入 `朱元璋(太祖)`，原模态消失。
- `testApprovingYearDeepLinkDismissesTheWholeModalTreeBeforeShowingCalendar()`：系统年份热 URL 显示 2026 年确认文案；批准后 sheet 与子 fullScreen 的 UUID 均消失，日历 Tab 可交互。

这次结果证明上述系统投递与可见按钮流程，不单独证明资源释放、回调次数或父子结束顺序。两条测试也在随后完整 scheme 回归中通过；资源与顺序由对应 Core／hosted 断言提供证据，见下表。

### 测试前置条件与生命周期阶段必须一致

部分 Core 结构测试直接创建节点后，按“系统已接手”的时序断言延迟关闭；新合同中，尚未 claim 的请求允许立即取消，原测试缺少这一阶段的前置条件。当前只在需要模拟已接手的 Core 内部测试中显式调用 `lifetime.claimHost()`，例如 [NavigationCoordinationTests](../../../Sources/NavigationCoreTests/NavigationCoordinationTests.swift) 与 [NavigationSystemAlertTests](../../../Sources/NavigationCoreTests/NavigationSystemAlertTests.swift)；未接手取消场景继续保持未 claim。真实物理测试仍由 lifecycle probe 认领，App 测试不取得该内部能力。

[CalendarStoreEnvironmentTests](../../../Sources/ChineseCalendarUI/Tests/CalendarStoreEnvironmentTests.swift) 的 store 替换场景已使用真实窗口；该轮 timeout 的直接前因是 `operation=present outcome=rejected reason=missingRootDestination`。测试 destination 声明自带导航容器，却未为模态声明 `.primary` 栈根，因此根本未进入预期呈现阶段。修复为显式传入 `rootDestinations: [.primary: .probe]`，并在等待系统呈现前用 `#require` 核对 `.applied`。store 环境传播及替换后 presentation identity 的原断言保留，`rootAndModalShareStoreAndReplacementKeepsPresentationIdentity()` 已在最终全量回归中通过。

### alert 释放探针需排除生产与测试两侧的额外持有

一次 hosted 定向运行在父宿主拆除、后代 alert 异步动作结束之后，父子 `onFinish` 和延迟导航均已发生、物理控制器链已为空，但配置的弱引用释放等待超时。源码中存在 `presenter → desiredAlert → didDismiss → definition／button handler → configuration` 的额外持有链。当前实现已在真实关闭 completion 中按同 ID 清除已消费的 `desiredAlert`，不同 ID 的下一条提示仍保留；动作 Task 继续持有完成所需资源。

同时，[NavigationPhysicalHostTests](../../../Sources/NavigationCoreTests/NavigationPhysicalHostTests.swift) 中该场景曾用测试局部变量强持有 `alertPresenter`，它本身是模态内的 UIKit 子控制器，会延长整棵 SwiftUI 渲染树的寿命。测试现改为即时取得 presenter 发起动作，不把它保留到弱引用断言；等待动作期间资源存在、动作结束后释放的断言均保留。因此 `desiredAlert` 不是这一轮释放超时的唯一诊断，生产持有链与测试自身引用都需要核对。最终全量回归中的 `parentHostTeardownKeepsFeatureUntilDescendantAlertActionFinishes()` 以及 `routerDestructionWaitsForSuspendedDescendantAction(releaseBeforeDismissal:)` 的两个参数实例均通过，修复后的资源存活、结束门槛与释放结果见[逐项测试记录](evidence/validation/all-tests.tsv)。

### CI 补充：宿主映射、Simulator 签名与 XcodeGen 预设

[CI run 39989186408](https://github.com/huahuahu/chinese-calendar/actions/runs/39989186408) 在 head `f2ebde6d56f5d164952313497d00ae56cc50823e` 上于测试前报告 `Could not find test host`。`ChineseCalendarUITests` 已有 `TEST_HOST`／`BUNDLE_LOADER`，但缺少 XcodeGen 用来生成项目 `TestTargetID` 的 `TEST_TARGET_NAME`；生成逻辑见 [XcodeGen 2.45.3 源码](https://github.com/yonaskolb/XcodeGen/blob/90dfa9da31eeb3b95153e22f46dce676d9ebaba7/Sources/XcodeGenKit/PBXProjGenerator.swift#L542-L557)。[project.yml](../../../project.yml) 补充 `TEST_TARGET_NAME: ChineseCalendar-iOS` 后，重新生成的两个项目测试 target 均具备宿主映射，scheme 的 8 个 testables 保留。但该补充随 `6cad5a9b` 推送后，[CI run 40021033420](https://github.com/huahuahu/chinese-calendar/actions/runs/40021033420) 仍报告相同的 `Could not find test host`。因此它补齐了项目关系，不能单独解释或解决远程原始错误。

补齐映射后，使用全新 DerivedData 及 CI 原有 `CODE_SIGNING_ALLOWED=NO`／`CODE_SIGNING_REQUIRED=NO` 运行，编译与其余 504 个测试实例通过，但两条系统热 URL XCUITest 都在 `launchApplication()` 等待设置 Tab 时失败。日志中的 `client is not entitled` 与 `Missing app group` 指向 App Groups 权限缺失；辅助功能层级确认 App 停在“无法打开日历数据／无法访问日历数据存储位置”错误页，尚未进入热 URL 场景。

[Scripts/test.sh](../../../Scripts/test.sh) 现改用 `CODE_SIGN_IDENTITY=-`、`CODE_SIGNING_ALLOWED=YES`、`CODE_SIGNING_REQUIRED=YES`，通过 ad-hoc 签名保留 Simulator App Groups entitlements，无需开发者证书。第二个全新 DerivedData 的构建与全量测试已通过：2026-10-24 04:34:36.634 至 04:37:39.512（UTC+8，xcresult 时间），**506 passed、0 failed、0 skipped、0 expectedFailures**，8 个 testables 保留。该计数包含参数化实例；xcresult 顶层汇总为 393 个测试定义。构建复用已有 package source checkout，没有复用先前构建产品。

本轮 XcodeBuildMCP `test_sim` 响应在 300 秒时传输超时，但底层 `xcodebuild` 已输出 `TEST EXECUTE SUCCEEDED`；成功状态和计数由完成的 xcresult 确认，不把工具超时当作测试失败或单凭超时推定成功。[ci-configuration.json](evidence/validation/ci-configuration.json) 保存 unsigned 504／2 与 ad-hoc signed 506／0 的原始 summary、配置 SHA256、实际签名与 simulated App Group；App 已成功打开共享数据库。该证据还记录 format、strict lint、本地化、3 条 seed-store Node 测试及 shell 语法检查通过。原 00:33 全量结果保留在下节，各轮独立计数。这两轮本地生成工程使用完整安装的 XcodeGen 2.46；全新 DerivedData 只排除了旧构建产物，没有复制 CI 的 XcodeGen 安装方式，因此 506 条通过不能证明 CI 相同生成环境已修复。

后续核对发现 CI 安装 XcodeGen 2.45.3 时只从 release ZIP 复制 `bin/xcodegen`，遗漏同包 `share/xcodegen/SettingPresets`。远端生成日志已有 `No base/debug config/release config/iOS settings found`，因此生成工程缺少预设；此前只修改 test target 关系没有处理这项安装差异。

主流程以 `git archive 6cad5a9b` 创建从未由 Xcode 打开的干净副本 `.output/ci-165-pristine`，使用 CI 同版 2.45.3 ZIP、只安装 bin、直接 `xcodebuild test` 与全新 DerivedData，精确复现同一 test host 错误，退出码为 70。改为安装相同 ZIP 的完整 bin／share 后，31 份 preset 文件核对通过，生成 warnings 为空。当前 [.github/workflows/ci.yml](../../../.github/workflows/ci.yml) 的两处安装步骤均补充复制 `SettingPresets` 到 `$RUNNER_TEMP/share/xcodegen`。

这轮直接测试于 2026-10-24 04:46:36 至 04:51:52（UTC+8，xcresult 时间）完成，命令退出码 0，输出 `TEST SUCCEEDED`；xcresult 确认 **506 passed、0 failed、0 skipped、0 expectedFailures**。[ci-configuration.json](evidence/validation/ci-configuration.json) 的 `xcodegenInstallationFix` 保存 base commit、workflow SHA256、release ZIP SHA256、31 份 preset 数量及修复前后的 warning／退出码／完整 summary。本轮 2.45.3 直接回归与前轮 2.46 的 signed 506 条测试分开记录；各自是本地运行证据，远程 CI 状态以 PR 最新提交检查为准。

## 最终自动验证

本节记录原实现提交 `edcf930e908a9bb9f5858fa23e52878da5d4adc0` 的本地验证；后续 CI 配置补充及其独立回归见上节。

2026-10-24 00:33:41 至 00:36:54（UTC+8），native Xcode MCP `RunAllTests` 完成共享 scheme `ChineseCalendar-iOS` 的完整回归：**506 passed，0 failed、0 skipped、0 expectedFailures、0 notRun**。环境为 Xcode 27.1（27A9275）、iOS Simulator SDK 27.1、iOS 27.0 runtime，以及 `chinesedate iPhone 18 Pro Max (885f)`（`16A9CAA7-45CE-46D5-8915-F61531FC617C`）。[all-tests.json](evidence/validation/all-tests.json) 保存环境、计数及快照，[all-tests.tsv](evidence/validation/all-tests.tsv) 保存每个测试及参数实例的结果。

| Target | 通过数 |
| --- | ---: |
| `ChineseCalendarUITests`（App-hosted，含 Core physical host） | 217 |
| `CalendarNavigationUIIntegrationTests` | 2 |
| `NavigationCoreTests` | 181 |
| `ChineseCalendarLocalizationTests` | 14 |
| `ChineseCalendarCoreTests` | 24 |
| `ChineseCalendarDataTests` | 10 |
| `ChineseCalendarLoggingTests` | 3 |
| `ChineseCalendarPersistenceTests` | 55 |

构建与检查结果见 [build-and-checks.json](evidence/validation/build-and-checks.json)：

| 检查 | 本次结果 |
| --- | --- |
| native Xcode MCP `BuildProject` | 2026-10-24 00:37:11（UTC+8）成功，0 errors；与测试构建分别记录 |
| 公开 API 配对编译 | 普通 import 正向控制通过，18 个独立负向样例均得到预期保护级别／符号缺失诊断；[报告](evidence/validation/public-api-report.json)与[诊断](evidence/validation/public-api-diagnostics.txt)保留 module hash、命令及每例结果 |
| `./Scripts/format.sh --check` | 退出码 0，检查范围内 0/356 文件需要格式化，100 文件按工具规则跳过 |
| `./Scripts/lint.sh` | 退出码 0，343 文件，0 violations、0 serious |
| `python3 Scripts/validate_localized_copy.py` | 退出码 0，核对 337 个资源条目与 21 个剩余生产字符串 |
| 工作区与暂存区 diff 检查 | 退出码 0 |

## 验收证据

以下完整保留方案中的验收项。两轮实际交互的逐场景记录见 [Simulator 交互记录](evidence/runtime/runtime-results.md)，其中保存 10 张关键截图和 45 份 hierarchy。环境为共享 scheme `ChineseCalendar-iOS` 与 `chinesedate iPhone 18 Pro Max (885f)`（`16A9CAA7-45CE-46D5-8915-F61531FC617C`），由 native Xcode MCP 执行。第二轮在 App 停止时使用本地完整数据 fixture；随后在 App 内真实清空，使运行中的 store 恢复基础数据。这两步分别记录，fixture 准备不作为网络下载或运行中替换证据。交互完成后停在根设置页、基础数据、无活动模态，并由主流程结束交互 session，再运行自动测试。

下表的自动测试结果来自原实现提交的 00:33 本地 506 条全量回归，具体参数实例见[逐项测试记录](evidence/validation/all-tests.tsv)；同一测试可能支撑多个验收项，不重复累计。宿主映射／签名补充通过了[独立全新 DerivedData 回归](evidence/validation/ci-configuration.json)，但使用本地完整 XcodeGen 2.46；随后补齐 CI 同版 2.45.3 的 SettingPresets，并在干净副本以直接 `xcodebuild test` 完成另一次 506 条实例全量回归，修复前后证据保存于同一文件的 `xcodegenInstallationFix`。各轮证据保持独立，不扩大原验证快照。资源释放、结束次数、父子顺序与旧结果失效由对应断言证明，不由页面状态推断。[源码边界记录](evidence/validation/source-boundary.md) 保存生产源码与配置的限定快照及调用链核对。“部分已验证”保留 OWN-07 的组合端到端场景及 OWN-09 的完整生产容器释放观测边界。

| 验收项 | 场景与预期行为 | 状态 | 验证证据与覆盖边界 |
| --- | --- | --- | --- |
| OWN-01 | 两个日历来源及嵌套 picker 使用各自 selection、ModelContext、结果接收方；保留选年滚动与动画 | 通过（自动／交互） | [年份来源与真实 builder 测试](../../../Sources/ChineseCalendarUI/Tests/CalendarYearPresentationTests.swift)的嵌套来源、关闭期间 session 保留及结果处理通过；`CalendarYearFeatureTests` 验证各自 selection／ModelContext 与月份过渡。[第二轮交互](evidence/runtime/runtime-results.md#第二轮已完成)中根 2025、嵌套 2024、重开及滚动保持来源隔离；未测动画帧率。 |
| OWN-02 | App 无集中业务字典、弱寻址替代、导航扫描清理和全局关闭回调 | 通过（源码核对） | [源码边界记录](evidence/validation/source-boundary.md#源码结论)保存 210 文件限定快照及调用链核对：旧集中字典、内部身份、导航树查询、手动 completion 和 `@testable` 合并搜索零命中；weak／dictionary／filter／ObjectIdentifier 命中按上下文核对，没有替代 registry 或扫描清理。实现提交见本文代码状态。 |
| OWN-03 | 拒绝只同步回滚；已接受请求恰好结束一次；queued / 同轮取消不残留资源和等待状态 | 通过（自动） | [NavigationSubmissionTests](../../../Sources/NavigationCoreTests/NavigationSubmissionTests.swift)的拒绝回滚及 weak 捕获释放、[NavigationRetentionTests](../../../Sources/NavigationCoreTests/NavigationRetentionTests.swift)的 queued 一次完成与 FIFO、physical／App host 的同轮取消及年份同步回滚全部通过；参数化实例均列入全量结果。 |
| OWN-04 | 按钮、下滑和 fullScreen 关闭完成前保留渲染资源，完成后解除引用；交互撤销和被覆盖不释放 | 通过（自动／交互） | [NavigationPhysicalHostTests](../../../Sources/NavigationCoreTests/NavigationPhysicalHostTests.swift)的 sheet／fullScreen 真实关闭、宿主拆除、入场移除与配置 weak 释放通过；App 年份 feature／session 释放测试通过。[手势撤销与子层覆盖](evidence/runtime/runtime-results.md#首轮已完成)、[picker 完整下滑与重开](evidence/runtime/runtime-results.md#第二轮已完成)补充实际交互，页面 UUID 不用作释放证明。 |
| OWN-05 | 祖先退出、Deep Link 取消／批准、整树销毁覆盖活动及排队后代；父子结束顺序正确 | 通过（自动／交互） | [Core physical host](../../../Sources/NavigationCoreTests/NavigationPhysicalHostTests.swift)的祖先关闭、父宿主 teardown、Router 销毁及后代异步动作通过；retention 的活动／排队后代与先子后父顺序通过。[两条系统热 URL XCUITest](#系统确认按钮交互迁入独立-xcuitest)在定向及全量中均通过，验证取消／批准和两层模态可见关闭；实际嵌套交互见 runtime。 |
| OWN-06 | 旧完成通知、旧 handle、重复点击和结束回调重入不操作新请求，不绕过外部导航顺序 | 通过（自动） | [NavigationRetentionTests](../../../Sources/NavigationCoreTests/NavigationRetentionTests.swift)的具体 lifetime、旧 handle、重复完成及回调重入顺序通过；[NavigationSystemAlertTests](../../../Sources/NavigationCoreTests/NavigationSystemAlertTests.swift)的过期按钮／完成回调通过；年份旧结果和旧结束通知不改新 session、下载旧 handle 不影响新请求的业务测试通过。 |
| OWN-07 | store 替换立即阻止旧业务操作；旧容器退出安全，待处理外部导航继续完成 | 部分已验证（分层自动／交互） | 年份 context／generation 失效、真实 picker 定点关闭、排队取消、[store 环境与呈现 identity](../../../Sources/ChineseCalendarUI/Tests/CalendarStoreEnvironmentTests.swift)、Persistence 文件 read lease 以及真实关闭后应用最新外部请求的测试均通过。[设置真实清空](evidence/runtime/runtime-results.md#第二轮已完成)后根日历恢复基础数据，历史仍可用；未把“活动 picker、设置真实清空与待处理系统热 URL”合为一个端到端场景。 |
| OWN-08 | 下载演示跨 Tab / 子详情共享；子详情退出保留父状态；正式进度消失只取消自己的详情 | 通过（自动／交互） | [CalendarPresentationTests](../../../Sources/ChineseCalendarUI/Tests/CalendarPresentationTests.swift)的详情定点取消、未展示取消及 preview 真实 fullScreen 关闭后 weak 释放／重开通过；模拟下载顺序与排他测试通过。[交互记录](evidence/runtime/runtime-results.md)验证跨 Tab／子详情共享 50%、子关闭保留父状态、整流程重开准备，以及正式进度附件／详情路径随进度结束自动退出；不包含真实网络下载或数据库安装。 |
| OWN-09 | 历史／DEBUG 分栏在普通重绘、Tab、push、宽窄切换保持状态，容器结束可释放 | 部分已验证（自动／交互） | 历史／DEBUG state 和 Core context 测试通过，覆盖作用域隔离、路径保持、旧状态拒绝与重开独立。[第二轮交互](evidence/runtime/runtime-results.md#第二轮已完成)验证 DEBUG 三栏与正式历史的 Tab、push、横竖保持；[源码](evidence/validation/source-boundary.md#源码结论)确认完整容器以 `@State` 持有布局。通用 host／年份 weak 探针不等于这两个生产容器内部状态的直接释放观测；无后者专门实测，未穷举两栏、全部宽度与历史目标。 |
| OWN-10 | alert 独立 Action、串行队列、异步按钮、错误文案和 Deep Link 确认保持正确 | 通过（自动／交互） | [NavigationSystemAlertTests](../../../Sources/NavigationCoreTests/NavigationSystemAlertTests.swift)及 physical host 的独立 Action、异步 handler 挂起与 teardown 测试通过；alert FIFO、业务错误映射和清空结果提示通过。[首轮提示交互](evidence/runtime/runtime-results.md#首轮已完成)及两条系统热 URL XCUITest 补充真实连续提示、确认文案和取消／批准按钮。 |
| API-01 | 正常 App 用普通 import 可完成 Tab、SplitView、push、呈现、取消和结果处理 | 通过（编译／自动） | [普通 import 正向控制](evidence/validation/public-api-report.json)通过；完整 iOS App BuildProject 成功，普通 `import NavigationCore` 的 App 集成测试通过，覆盖 Tab／分栏接入、push、嵌套呈现、取消和结果处理。正向样例本身不单独构造全部 UI 容器。 |
| API-02 | 普通 import 无法访问 node、队列、事务、内部 ID、保留查询或伪造系统完成 | 通过（独立负向编译） | [API 报告](evidence/validation/public-api-report.json)与[诊断](evidence/validation/public-api-diagnostics.txt)确认正向控制成功后，18 个独立负向样例均按预期拒绝；检查的是目标符号缺失／保护级别，不将 SDK 或模块导入错误记作通过。 |
| VAL-01 | Core / App 相关回归、iOS build、format 和 strict lint 通过 | 本地通过（含 CI 配置与安装复现） | [最终自动验证](#最终自动验证)：506 passed，失败／跳过／预期失败／未运行均为 0；iOS BuildProject、API 正向及 18 负向、format、strict lint、本地化与 diff 检查通过，代码对应 `edcf930e908a9bb9f5858fa23e52878da5d4adc0`。宿主映射与 Simulator 签名补充也在完整 XcodeGen 2.46 环境下通过全新 DerivedData 构建、506 条测试实例及静态检查，见 [ci-configuration.json](evidence/validation/ci-configuration.json)。CI 同版 2.45.3 缺少 SettingPresets 的安装问题已精确复现，补齐后的干净副本直接全量回归另有 506 条实例通过；远程 CI 状态以 PR 最新提交检查为准。 |

当前验证入口：

- Core 结构与协调：[NavigationCoreTests](../../../Sources/NavigationCoreTests/)。
- UIKit 对照、正常／祖先关闭、宿主拆除、Router 销毁和入场期间移除：[NavigationPhysicalHostTests](../../../Sources/NavigationCoreTests/NavigationPhysicalHostTests.swift)。
- 业务来源、实际 builder 和资源释放：[App 集成测试](../../../Sources/ChineseCalendarUI/Tests/)。
- 真实系统确认按钮及热 Deep Link：[独立 XCUITest](../../../Tests/NavigationUIIntegrationTests/CalendarDeepLinkUITests.swift)。
- 手势、来源隔离、Tab／宽窄切换及真实清空：[两轮 Simulator 交互与覆盖边界](evidence/runtime/runtime-results.md)。
- 公开 API 正向与独立负向编译：[validate_navigation_public_api.py](../../../Scripts/validate_navigation_public_api.py)、[样例目录](../../../Scripts/NavigationCoreAPI/)。

本次证据已保存于任务 `evidence`：测试汇总及逐项结果、API 编译报告和诊断、构建与静态检查、源码及链接快照、两轮交互截图与 hierarchy。原始工具临时路径仅供追溯，不是唯一证据。主流程按 [Xcode 工作流](../../agent-workflows.md#xcode-project-context) 使用共享 scheme 和目标 Simulator；文档整理未启动额外构建、测试或交互。

## 交付状态与覆盖边界

1. 原实现、文档及 evidence 已分别提交并推送，已创建 [PR #170](https://github.com/huahuahu/chinese-calendar/pull/170)，尚未合并。宿主映射与 Simulator 签名补充后的远程 run 40021033420 失败记录保留；随后确认并修复 XcodeGen SettingPresets 安装缺失，在干净副本、CI 同版 2.45.3 和全新 DerivedData 下直接全量回归 506 条实例通过。各轮本地结果保持原环境边界，远程 CI 状态以 PR 最新提交检查为准，本记录不代表发布已完成。
2. OWN-07 的 store／context、旧文件安全及外部请求完成已有分层自动证据和真实清空交互，但没有活动 picker、设置清空与待处理系统热 URL 的合并端到端场景。
3. OWN-09 已有状态／context 自动测试、容器源码核对及实际布局交互；两个生产容器内部 `@State` 的退出释放没有直接 weak 观测。没有穷举全部布局、宽度和历史目标，也没有动画帧率数据。
4. 下载交互使用模拟进度及本地 fixture，不包含真实网络下载或数据库安装。本次结果整理不代表已执行 `review-changes` 专项审查。
