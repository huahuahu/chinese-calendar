# Issue #145：统一页面导航与模态呈现方案

> 当前业务 alert 与导航协调见 [011](011-unified-alerts.md)，承接 [010：独立栈状态与上下文依赖](010-independent-stack-state.md) 和 [009：栈导航与呈现环境分离](009-separate-context-apis.md)。

> 用户于 2026-10-18 决定先合并现有单栏实现，多栏／SplitView 方案暂缓，不属于本次交付。

- 关联：[Issue #145](https://github.com/huahuahu/chinese-calendar/issues/145)，接续已完成的 #81。
- 状态：已实施，结果与验证见 [001-result.md](001-result.md)；用户于 2026-10-07 审阅计划后授权实现。初版仅交计划，未修改产品代码。
- 更新日期：2026-10-07。
- 后续范围修订：曾按 [004-no-core-adjustment.md](004-no-core-adjustment.md) 保持 Core 不变；用户随后明确要求复用通用呈现宿主，最新采用 [005-reuse-core-host.md](005-reuse-core-host.md)，仅扩展 Core 宿主的容器策略和子关闭回调，Router 与节点状态不变。
- 源码基线：`88e3b74ae7bab044389a9a471346e16f9880bd1c`，与 Issue 的盘点基线一致；开始调查时工作区干净，HEAD 为 detached 状态。
- 初版调查边界：当时仅读取 Issue、项目规范及相关源码，尚未执行构建、测试、Preview 或 Simulator 交互。以下“当前情况”保留实施前的调用链调查；实施后的盘点和证据见结果记录。

## 目标与范围

让 App 可达的页面 push、sheet、full-screen 和嵌套 presentation 使用 `NavigationCore` 保存导航结构，使年份选择器、下载详情和设置中的下载演示参与现有 deep link 关闭协调。保留日期选择、年份过渡、实时下载进度和页面视觉。

建立唯一的导航 convention，并让实现、文档和中英文 review skill 引用同一来源。沿用现有模块和系统呈现 API，不引入第三方导航库，不改日历领域模型、下载协议、历史内容或数据库结构。

依据：[领域术语](../../../CONTEXT.md)、[通用规范](../../Conventions/Common.md)、[SwiftUI 规范](../../Conventions/SwiftUI.md)、[文案与本地化](../../Conventions/Localization.md)、[历史 Tab 导航与 Router 边界](../../history-tab-rewrite-requirement.md#导航关系)、[任务记录约定](../README.md)、[NavigationCore API](../../../Sources/NavigationCore/README.md)。

## 当前入口盘点

下表的 `Home/`、`Calendar/`、`History/`、`App/`、`Settings/`、`PreviewSupport/` 路径均相对于 `Sources/ChineseCalendarUI/`，其他路径相对于仓库根目录。状态描述当前实现；实施后应逐项更新状态与证据，不把搜索命中本身判为违规。

| 入口与调用链 | 当前状态所有者／宿主 | 结论与计划 |
| --- | --- | --- |
| `Sources/ChineseCalendarUI/Home/CalendarHomeTabView.swift`：日历、历史 Tab 的 `NavigationStack` | `CalendarRouter.yearsPath/historyPath` → `NavigationRouter.paths`；各栈注册 `calendarDestinations()` | 已统一，保持独立 path 和系统返回行为。 |
| `Sources/ChineseCalendarUI/History/Timeline/CalendarHistoryHomeView.swift` → 朝代详情；`History/Shared/DynastyFactCard.swift` → 帝王列表、年号列表、朝代起讫；`History/ReignEraList/ReignEraListView.swift` → 年号详情 | `NavigationLink(value: CalendarDestination)` 写入所在 Router path；页面分发在 `Home/Navigation/CalendarDestinationView.swift` | 已统一，保留合法的值导航；卡片调用方和目标 ID 一并核对。帝王卡片等当前没有导航的内容不新增入口。 |
| `Home/CalendarHomeView.swift` → 根 sheet/full-screen → `Home/Navigation/CalendarPresentationNodeView.swift` | `CalendarRouter.navigation.sheet/fullScreen`，根 `onDismiss` 执行待处理导航 | 已统一；调整生命周期与业务页面分发，保留关闭完成后再跳转的时序。 |
| `Sources/NavigationCore/SwiftUI/NavigationPresentationNodeView.swift`、`NavigationPresentationModifiers.swift`（2026-10-12 移动后的路径） | 每个 `NavigationPresentationNode` 的独立 path、sheet/fullScreen；系统 dismiss | 合法的通用宿主；按实际需求补齐节点级关闭／容器能力，不添加业务类型。 |
| `Calendar/Month/YearMonthHeader.swift` → `Calendar/Year/Picker/CalendarYearPickerView.swift` | 局部 `isYearPickerPresented`、`.sheet` 和 `NavigationStack`；继承发起页的 selection、ModelContext，回调执行原年份过渡 | 待迁移。呈现归 Router；发起页上下文和跨年过渡继续归日历 feature。 |
| `App/ChineseCalendarRootView.swift` → `App/Store/FullStoreDownloadDetailView.swift` | 根 View 的 `isShowingDownloadDetails`；进度来自 `ChineseCalendarStoreCoordinator`；详情自己建栈、dismiss | 待迁移。统一呈现状态，持续读取 coordinator 进度；详情与宿主只保留一层对应导航容器。 |
| `Home/CalendarHomeTabView.swift` → `Settings/CalendarSettingsView.swift` | 设置 Tab 当前为无 push 的根 `NavigationStack`；`showsDoneButton: false` | 当前仅提供根页面导航栏，属于集中宿主的合法系统容器；不为一个没有 push 的页面虚造 path。若实施引入设置页 push，则接入相应 Router scope。 |
| `Settings/CalendarSettingsView.swift` → `PreviewSupport/FullStoreDownloadPreview.swift` | DEBUG 局部 `isShowingDownloadPreview` 和 full-screen | App 内可达，待迁移；不能以 DEBUG 或目录名排除。 |
| `PreviewSupport/FullStoreDownloadPreview.swift` → 下载演示的详情 | 演示自己的 TabView、两个根 NavigationStack、`isShowingDetails` 和 sheet；阶段、字号是局部展示状态 | 详情必须作为演示节点的子 presentation 纳入同一棵树。阶段、字号保留在演示 feature。两个 Tab 根栈用于真实附件布局，明确为独立容器作用域，避免外层再套一层无用途的栈。 |
| `Home/CalendarHomeView.swift` 的 `.onOpenURL` 和启动参数 → `CalendarHomeCoordinator` → `CalendarRouter.openDeepLink` | URL 解析在业务层；`NavigationRouter.submit` 暂存请求并关闭模态，根 `onDismiss` 应用最新请求 | 已统一，迁移后的全部模态都必须参与该链路；共享 owner 提升时同步检查 URL／冷启动入口的生命周期。 |
| `CalendarSettingsView` 的可选“完成”、下载详情“关闭”、年份选择器“关闭”、演示“完成”、通用宿主关闭 | 各层使用局部 Boolean 或所在环境的 dismiss | 逐个绑定实际 presentation 节点；设置的 `showsDoneButton: true` 当前无 App 调用方，不凭 `Environment(\.dismiss)` 单独判违规或扩展功能。 |
| 根下载错误 alert、设置清除确认／结果 alert | View 的局部交互状态和 store coordinator 错误状态 | 非页面导航，保留；不改为 destination。 |
| 独立 `#Preview`、Preview helper 和测试构造的导航容器 | 仅提供独立渲染／测试上下文 | 可保留。已核对 `LunarMonthStripPreviewContent`、日格／布局 Preview helper 的调用点；实施后复查新增环境依赖，不给整个目录豁免。 |

其余 `NavigationStack` 命中位于日历、历史组件的 `#Preview` 或上述 Preview helper。对 `Sources/`、`Apps/` 的本次导航 API 扫描未发现页面级 popover、其他 `navigationDestination` 注册入口或旧式 `NavigationView`；实施收尾时复扫并按实际调用链核实。

## 方案与关键决策

### 1. 统一结构状态，保留业务状态归属

继续组合 `CalendarRouter` 与 `NavigationRouter<CalendarTab, CalendarDestination>`，在业务 destination 中补充年份选择器、下载详情、DEBUG 下载演示及必要的演示详情身份。名称以实施时的最小表达为准，路由只携带稳定页面标识或一次呈现会话的 ID。

| 状态 | 计划所有者 |
| --- | --- |
| 选中 Tab、各 Tab path、presentation 树、等待 dismiss 的导航请求 | `CalendarRouter.navigation` |
| 当前选中日、年份切换准备、动画方向、年份列表定位 | 现有日历 feature；不改 `selectedDayIndex` 为唯一业务选择的设计 |
| 年份选择器发起上下文、选择结果回传 | UI 层的呈现会话，与发起页绑定；由业务协调层关联会话 ID |
| 真实下载阶段、实时进度、错误、安装及完成后的两秒清理 | 现有 `ChineseCalendarStoreCoordinator` |
| 演示阶段、字号和演示 Tab 选择 | 下载演示 feature |

会话仅保存构建页面和回传结果所需的上下文，不保存第二套“是否呈现”、path 或 pending deep link。`NavigationCore` 不导入 `ChineseCalendarPersistence`、SwiftData 模型、日历选择或业务页面。

### 2. 年份选择器：显式传递发起页上下文

拟采用 UI 层的短生命周期年份选择会话：从 `YearMonthHeader` 打开时，关联当前页面的 `CalendarSelection`、`ModelContext` 和原 `selectYear` 回调；destination 只引用会话 ID，由业务呈现层解析并构建 `CalendarYearPickerView`。

- 不从根部随意查找一个全局 selection，不把已有页面的选择覆盖为同一个实例。
- 保留 `CalendarYearPickerView.initialScrollTarget`、当前年份高亮、原有查询和 `YearMonthHeader` 的跨年准备／完成链路。选择同一年、向前／向后选年、BCE/CE 边界仍沿用原语义。
- 选年先关闭对应 picker，并将结果回传给原页面；不改为 push 一个新日历页。
- 关闭按钮、下滑取消、deep link 关闭、发起页退出和 store identity 变化都需要明确会话清理；失效会话不能继续调用旧 ModelContext 或更新旧页面。
- 用两个独立日历页面的 selection／context 验证隔离；纯 Preview 注入明确的导航上下文，不在生产 View 内偷偷创建备用 Router。

选择这种方式是为了继续复用集中 presentation host，同时保留发起页上下文。若实施证明更小的作用域宿主可直接绑定同一棵 Router 树并满足全部生命周期约束，可以替代会话关联方式，但应在本文件补记依据；不能退回独立 Boolean。

### 3. 下载详情：稳定宿主与实时进度

目前根下载 sheet 位于带 `.id(storeIdentity)` 的主页之外，而 `CalendarHomeCoordinator` 位于主页内部。直接将 sheet 搬入主页会让安装成功时的主页重建提前销毁下载详情。

拟将共享业务导航 owner 和根 presentation host 放在 store identity 重建边界之外。数据依赖的日历／历史页面继续在当前 container 下构建、按 store identity 重新建立必要的页面状态；`CalendarHomeView` 使用注入的共享 owner。独立使用的主页 Preview 通过明确宿主提供 owner。

- 下载 destination 不保存打开时的 progress 快照。详情构建时读取同一个 store coordinator 的可观察进度，保持阶段和百分比更新。
- `FullStoreDownloadDetailView` 只负责详情内容和关闭动作；通用宿主负责其 NavigationStack，独立 Preview 自己提供容器。
- 保留完成态两秒后进度变为 nil、详情随之关闭的现有行为；失败／取消导致 nil 时也关闭。
- 自动关闭必须定位真实下载详情节点；如果其他模态正在显示，不调用无差别“关闭根 sheet”误关它。
- store 切换使依赖旧 container 的年份会话失效并关闭；纯下载详情可继续显示完成态。Router、等待中的 deep link 和可按稳定 ID 重新查询的页面地址不因 View 的 `.id` 被静默丢弃。
- 主页重新构建不得重复应用冷启动 deep link。容器切换与 deep link 同时发生时，仍以最后收到的有效导航请求为准。

### 4. 下载演示：统一 App 入口与嵌套详情

设置按钮经业务 Router 打开演示 full-screen；演示的详情作为该节点的子 sheet。关闭详情回到原演示阶段，关闭演示回到设置，deep link 关闭整棵树后跳转。

演示必须保留真实 TabView 与底部附件，阶段、字号继续由演示 feature 管理，详情实时读取这些值。演示的 Tab 根栈有独立布局用途，允许保留；它们当前没有页面 push，不额外建立游离的导航状态。

为避免外层通用宿主再包一层 NavigationStack，优先在业务 presentation host 区分“普通页面”和“自带多 Tab 容器的页面”。若递归承载需要在 `NavigationCore` 提供容器选择扩展，扩展只能表达通用的容器归属，默认行为保持不变，并补结构测试；不在 Core 判断下载演示 destination。

### 5. 关闭、嵌套与外部请求协调

沿用 `submit` → 清除 presentation tree → 根 `onDismiss` → `applyDeferredRequestIfReady` 的协调方式，关闭期间的新请求覆盖旧请求。迁移页的按钮关闭与系统下滑关闭必须同步写回同一节点绑定。

针对年份选择结果、进度消失等需要精确关闭的调用，按节点身份提供最小业务入口；如果现有 Core 缺少所需操作，再补通用节点操作及测试。不能把关闭子节点解释为关闭全部根模态，也不能把子节点 `onDismiss` 当作根树已完全关闭而过早执行 deep link。

### 6. 共享规范与 review 接入

拟新增 `Docs/Conventions/Navigation.md`，分配以下稳定规则 ID。正文写清适用条件、要求、例外及验证方式，具体措辞在实施阶段完成：

| 拟定 ID | 规则主题 |
| --- | --- |
| NAV-01 | App 页面导航的唯一结构状态来源，按实际调用链判断适用性 |
| NAV-02 | Router、feature／coordinator 与通用 Core 的职责边界 |
| NAV-03 | 页面与 presentation 作用域、发起上下文和数据容器生命周期 |
| NAV-04 | 系统 API、值导航、集中宿主、纯 Preview 与非页面交互的合法使用 |
| NAV-05 | 关闭目标、状态同步、嵌套呈现与最新外部请求协调 |
| NAV-06 | 容器归属、例外记录和源码／测试／交互证据要求 |

同步修改 `Docs/README.md`、`AGENTS.md`、`Docs/Conventions/SwiftUI.md`、`Sources/NavigationCore/README.md` 的读取入口；模块 README 保留 API 说明，只引用项目 convention。

更新 `.agents/skills/review-changes/SKILL.md` 与 `SKILL.zh-CN.md` 的共享规则来源及导航审查取证要求，保持章节与 ID 对应。用代表性片段验证：绕过 Router 的 App 页面模态应被指出；绑定框架状态的宿主、合法 `NavigationLink(value:)`、纯 Preview 容器、局部确认框以及正确作用域的 dismiss 不应被误报。本轮不启动 review；维护 review skill 也不等于对全部实现自动启动多 Agent 审查。

## 实施顺序

1. **固化边界与基线。** 复核工作区和本计划；记录迁移前关键流程，落实 owner／host 的 store identity 边界和会话生命周期。
2. **实现共享 owner 和呈现分发。** 调整根／主页组合、业务 destination 与 context 关联；先保证现有 Tab、值导航和 deep link 行为，再迁移页面。
3. **迁移年份选择器。** 删除该流程的局部呈现 Boolean 与独立宿主；保留日期选择和过渡逻辑，补隔离、取消与失效测试。
4. **迁移下载详情和演示。** 接入实时进度、精确自动关闭、store 切换，以及 full-screen → sheet 嵌套；消除重复容器。
5. **落地 convention 与入口。** 完成共享规范及 review skill 中英文接入，执行代表性规则案例核对。
6. **验证并记录结果。** 重做入口盘点，运行受影响测试、iOS 构建、format/lint 和 Simulator 场景。到这一步才创建 `001-result.md`，保留实际快照、证据、方案调整和未验证项。

## 验收与验证计划

沿用 Issue 的验收 ID，不降级或改写完成条件。

| ID | 必须满足的结果 | 计划证据 |
| --- | --- | --- |
| NAV-AC-01 | 全部 App 可达入口、状态 owner、宿主及例外可追踪 | 更新入口表；复扫 SwiftUI 导航 API、封装和关闭调用，追踪每个运行时调用方 |
| NAV-AC-02 | 年份选择器、真实下载详情、演示入口及内部详情统一接入 | 业务 Router 测试、实际页面调用链和 Simulator 开关流程；无并行局部 Boolean |
| NAV-AC-03 | 年份定位／高亮／回传／过渡、实时进度／自动关闭／容器切换正常 | 两个 selection/context 的隔离测试；现有 picker／resolver 测试；Simulator 中分别验证选年、下载和 store 切换 |
| NAV-AC-04 | 按钮、下滑、返回、重复打开、嵌套、deep link 与 Tab 隔离正确 | Core／CalendarRouter 的节点关闭和最新请求测试，加下方交互矩阵 |
| NAV-AC-05 | 通用层无业务依赖，feature 状态归属清晰，无重复容器 | 依赖与类型检查、宿主调用链、导航栏／返回层级的 Simulator 证据 |
| NAV-AC-06 | 唯一规范及全部文档／中英文 skill 入口接入，规则无机械误报 | 核对文档链接与规则 ID；记录代表性片段的预期、判断及调用链理由 |
| NAV-AC-07 | 受影响测试、iOS 构建、format/lint 和关键交互均有对应版本证据 | Xcode MCP 结果、检查输出、工作区快照与必要截图；未执行或失败项明确保留 |

### 自动化检查

- 复用 `Sources/NavigationCoreTests/NavigationRouterTests.swift` 中的 scope 隔离、嵌套、推入模态栈、延迟请求、最新请求和幂等测试；仅为新增或改变的通用结构能力补测试。
- 扩展 `Sources/ChineseCalendarUI/Tests/CalendarRouterTests.swift`，覆盖三类迁移入口参与 deep link 协调、子节点关闭、关闭后重开及 Tab path 不受污染；业务会话生命周期可独立测试时另建对应测试文件。
- 复用 `CalendarYearPickerViewTests.swift`、`CalendarSelectionResolverTests.swift`、`FullStoreDownloadSimulatorTests.swift` 和 `FullStoreDownloadProgressTests.swift`；补充原有测试没有证明的上下文隔离、进度清空和 store identity 交界行为，不重复测试纯转发代码。
- 使用 iOS Simulator destination 运行相关测试与 App build；Debug 覆盖演示入口，Release 构建确认 DEBUG destination／页面的条件编译完整。
- 执行 `./Scripts/format.sh --check`、`./Scripts/lint.sh`、`git diff --check`；如实现改变产品文案，额外运行 `python3 Scripts/validate_localized_copy.py`。本次不计划更改数据格式，不以全量数据重建作为导航验证前提。

### Simulator 交互矩阵

| 场景 | 观察点 |
| --- | --- |
| 日历首页打开年份选择器；从另一个日历 destination 再打开 | 各自初始定位和高亮正确；选年只回传发起页面 |
| 选择同一年、较早年、较晚年；跨公元前／公元边界 | 原月条准备和年份过渡语义保留；不引入公元 0 年、不额外 push 页面 |
| picker 的关闭按钮、下滑取消、再次打开 | selection 未被取消操作改变，呈现状态无残留 |
| 真实 coordinator 的模拟下载：打开详情、手动关闭、再次打开、等待完成 | 阶段与百分比持续更新；完成后按原时序关闭；再次打开不显示旧快照 |
| 安装真实完整库或受控 store 切换时详情仍打开 | 新 container 生效，完成态与自动关闭正常；旧年份上下文不能再回传 |
| 下载演示：选择阶段／字号、切 Tab、打开／关闭子详情、关闭 full-screen、再次打开 | 容器层级正确，子详情属于演示节点，演示状态由 feature 控制 |
| picker、真实详情、演示及演示子详情分别可见时打开 deep link | 根树关闭完成后进入目标；无残留蒙层或失效上下文 |
| 模态关闭动画期间连续提交两个不同 deep link | 最后请求生效；结合确定性状态测试证明，不只观察一次跳转 |
| 历史 push 两层 → 返回 → 切日历 Tab → 切回 | 原历史 path 保留；日历与历史 path 相互隔离 |

模拟下载不替代实际数据容器切换验证；若受环境限制未完成后者，NAV-AC-03／07 保持未验证，而不是用 build 或 Preview 代替。

### 工具与证据边界

实施时按 [Xcode 工作流](../../agent-workflows.md#xcode-project-context) 重新读取 `.xcodebuildmcp/config.yaml`。当前配置是项目 `ChineseCalendar.xcodeproj`、scheme `ChineseCalendar-iOS`、Simulator `chinesedate iPhone 18 Pro Max (885f)`，ID `16A9CAA7-45CE-46D5-8915-F61531FC617C`；这些是计划编写时的配置值，当时未验证其运行状态；实施时的实际环境与验证已记入结果。

优先原生 Xcode MCP；先打开本工作区项目、核对 scheme 和目标设备，再进行构建／测试／交互。仅在不支持、不可用或失败时依次使用 XcodeBuildMCP、直接 Xcode 工具。影响方案的系统呈现 API 行为在实施时通过 sosumi 核实。

结果关联实际 commit 或未提交工作区的文件哈希快照，记录工具、Simulator／OS、结果及必要截图。源码、单元测试、build、Preview、Simulator 和真机证据分别标注；本次计划不把未运行的项目写成已通过。

## 待核实点与方案调整

- 年份会话的具体关联 API、按节点关闭所需的最小 Core 扩展，以及演示多 Tab 容器的宿主接口，在实现第一步确定；以上状态归属和验收要求不因此放宽。
- 共享导航 owner 提升后，store identity 切换期间的有效页面地址和等待请求应显式处理；通过基线交互核对是否存在需保留的额外行为，避免依赖 `.id` 的隐式销毁。
- 2026-10-07：用户审阅后明确要求实施。沿用当前工作区，新建 `codex/issue-145-unified-navigation` 分支。
- 2026-10-07：采用集中宿主和按 ID 关联的年份／演示会话；根 App 直接复用 `CalendarHomeTabView`，公开的 `CalendarHomeView` 保留独立宿主，避免给根 App 添加重复 presentation host。
- 2026-10-07：原 Core 仅在外部请求触发关闭时标记等待。为了覆盖按钮／下滑／自动关闭过程中到达的请求，根绑定从非 nil 变为 nil 时也进入等待状态，并在根 `onDismiss` 清除；新增结构测试验证最新请求、重复通知和再次打开。
- 2026-10-07：Simulator 在 `year/-1` 的日历 destination 打开选择器时，实际停在公元前 100 年附近。年份行与世纪分组均使用 `Int` 身份，滚动目标存在冲突。为满足当前年份定位验收，将行的显式滚动 ID 改为独立类型；不改纪年、查询、分组和年份过渡逻辑。修复前后的证据在结果中分别标记。
- 2026-10-07：年份与演示入口加入重复触发保护，保持迁移前 Boolean 对同一呈现入口的幂等语义；不同日历页面仍可使用各自独立的 selection／ModelContext 会话。
- 2026-10-07：用户明确提出不修改 NavigationCore package。撤回对 Core 源码、测试和 README 的修改，继续使用原有节点、present 和 submit API；系统关闭生命周期及业务容器由 ChineseCalendarUI 适配。具体边界和重新验证见 004 补充记录。
