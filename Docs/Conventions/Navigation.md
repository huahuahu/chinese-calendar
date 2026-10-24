# 页面导航与模态呈现

适用于 App 运行时的页面 push、sheet、full-screen、业务 alert、嵌套 presentation 及页面级 popover。实现与 review 使用同一规范；框架 API 见 [NavigationCore](../../Sources/NavigationCore/README.md)。

## NAV-01 — 唯一的结构状态来源

页面导航使用 `CalendarRouter` 组合的 `NavigationCore` 状态。每个导航层（`NavigationLayer`）拥有独立栈集合和一个可选的直接呈现内容：页面模态或业务 alert。页面模态携带 sheet／fullScreen 展示方式及下一层状态；alert 只携带提示 ID 和业务路由，没有下一层或导航栈。根层与模态层遵循同一结构，同层多个 Tab 共享呈现状态、保留各自 path。sheet/fullScreen/alert 读取同一呈现枚举，不为同一流程并行维护局部呈现 Boolean、可选路由项或另一套 path。

Core 内部每层以 `NavigationLayerRoute` 保存开始展示的 Destination，并投影纯身份 `NavigationLayerID`。节点的 destination/id 和 `NavigationPresentationContext` 的 route/destination 来自同一层状态，入口不随 push 或切换 Tab 改变；层身份不能包含 destination。

模态、导航确认和业务提示分别使用 `NavigationPresentationID`、`NavigationConfirmationID`、`NavigationAlertID`；节点与其模态层共用模态身份。API、队列和生命周期回调保留所属身份类型，不转换成 UUID 混用。这些身份及节点属于 Core 内部实现，不向业务开放查找或关闭入口。系统提示宿主区分业务与确认身份，请求继续按内容去重；业务资源按发起方直接持有，不建立聚合会话登记。

单个栈的根身份与 path 由独立 `NavigationStackState` 保存，根 Destination 必填，path 为非可选数组。层只组合这些栈对象和呈现状态，roots/paths 字典是值投影，不重复保存路径。根与 path 的运行时修改更新已有栈对象，保持其 Context 连接；移除原层或栈后，旧上下文失效。获取 Context 不创建无根栈，路径投影省略空 path，不区分缺失条目与显式空数组。App 原生分栏使用详情根 Destination 表达选中对象或空态，边界见 NAV-07。

根据实际调用链判断是否是 App 页面。设置能打开的 DEBUG 下载演示属于本规则；文件位于 `PreviewSupport` 或用 `#if DEBUG` 包围不是豁免依据。

## NAV-02 — 结构、业务与数据的边界

Router 保存“去哪里”的页面身份和导航结构。业务层负责 destination、URL 解析、页面构建和上下文传递。日期选择、列表查询、下载进度、演示阶段、滚动和动画状态留在对应 feature／coordinator。

`NavigationCore` 只理解泛型 scope、destination、path 和 presentation；不得依赖日历类型、SwiftData 模型、数据查询或业务页面。业务路由可以直接携带 Binding、ModelContext 等页面参数，Core 只将泛型 Destination 交给 builder。包含引用或 Binding 的路由必须在创建时确定稳定 ID，以路由种类和 ID 比较、哈希，不使用 wrappedValue 或可变业务状态；普通值路由仍比较完整关联值。

所有 `present` 接收强类型路由数据，由根宿主的统一配置映射为页面或提示文案；不接收按次 configuration。业务 alert 定义独立 AlertRoute，各类提示使用自己的 Action，由 NavigationAlertDefinition 将内容与异步 handler 配对。Core 保留待确认请求、呈现队列和关闭事务；业务不复制导航树或队列。

统一配置按路由委托对应功能构建 alert；内容、错误映射、依赖适配和按钮业务动作与所属 feature 一起维护。根配置只负责分发和依赖注入，不集中实现各功能的提示流程。业务归属不要求宿主绑定具体 View 的生命周期；跨页面事件由所属业务发起，系统呈现和异步动作等待仍交给统一宿主。

## NAV-03 — 发起作用域与生命周期

每个 `NavigationLayer` 注入 `CalendarPresentationContext`，负责本层 `present`、自身 `dismiss`、选中栈和离开确认，不提供 path／push／pop。根宿主使用 `rootPresentation`，不隐式代理当前选中 Tab 的栈操作。栈宿主从层级入口取得带发起栈身份的呈现入口并单独注入环境；这些入口共享同一层状态，不要求对象相同。

每个栈注入绑定本栈的 `CalendarNavigationContext`，根页及其 push 后代共享它。它只公开本栈身份、根 Destination、`setRootDestination`、path、`setPath`、`push` 和 `pop`，不公开 presentation，也不转发 `present`、`dismiss` 或 `isPresented`。页面直接读取 `CalendarPresentationContext` 发起模态操作；需要业务协调时传递发起页面的 `NavigationPresentationContext`，不能借 navigation 获取。带发起栈身份的呈现入口拒绝后台 Tab 的 present；TabView 附件等层级控件使用不绑定栈的呈现入口。页面提供的 SplitView 同时可见栏目，可通过 `NavigationScopeView` 显式关闭选中栈限制，使用当前层不绑定栈的呈现入口。

栈 Context 只弱引用独立栈状态，通过库内窄接口检查 isActive 和 rejectionReason（nil 表示允许修改），不直接引用 Router、NavigationLayer 或 `NavigationPresentationContext`。Router 在组合时通过弱捕获注入对象身份和事务检查；Context 仅额外保存用于诊断的层 ID，不保活层对象。`NavigationPresentationContext` 则弱引用原层及 Router，负责呈现生命周期。

每个 Router 独立持有 MainActor 隔离的内部 `NavigationContextStore`，统一管理栈 Context、层级呈现 Context 和带 sourceStack 的呈现 Context。缓存命中核对原层／栈对象身份；有效入口重复获取保持对象身份，旧入口的调用不得覆盖有效缓存。模态从树中移除时 Context 立即失效，真实 dismiss 完成后通过 `removeInactiveContexts()` 统一释放失效缓存，不依赖 View 重建或零散清理。

层入口 route／destination、内部层身份和 isActive 只用于 Core 渲染与访问检查。业务通过命令结果获知拒绝，通过 isPresented 控制关闭按钮。Context 弱引用原层，退出动画期间由节点保留路由参数；层释放后，旧 Context 不保活 Binding 或业务资源，也不连接同 ID 的新层。

根层与模态层使用相同配置：由 Core 提供容器时使用 `.primary` 栈；页面提供 Tab 等容器时使用 `.scope(...)` 命名栈并显式设置 `initialStack`，为选中栈和所有带路径栈声明根。单详情栈的 SplitView 也可使用 `.primary`。二者共用内部初始化校验，完整校验通过后才建立状态；同名栈在不同层中互相隔离。

`dismiss()` 表示关闭当前所在的模态及其后代。根层的 `NavigationPresentationContext` 没有自身所在的模态，调用时返回 `.noChange(.notPresented)`；它们不能用此方法关闭自己展示的模态。栈内返回单独使用 `pop()`。跨 Tab、外部请求和整树管理使用根 Router。

同步栈／根／选择修改返回 `NavigationMutationResult`，以 `isApplied` 判断数据是否已应用。`present`／`presentAlert` 返回 `NavigationPresentationSubmission`：`result` 为既有 `NavigationPresentationResult`，以 `submission.result.isAccepted` 判断是否接受，`handle` 在接受时提供定点结束能力。当前层 `dismiss()` 和 handle 的 `dismiss()` 仍直接返回 `NavigationPresentationResult`。`.noChange(reason)` 表示正常无操作，`.rejected(reason)` 表示未接受的具体原因，不通过数字错误码或日志文本驱动业务。重复写入同一合法 path 或选中栈仍为 `.applied`；栈底 pop、根层 dismiss 和过期确认分别返回对应 noChange 原因。属性 setter 转调同一命令，业务代码需要结果时直接调用方法。

`.applied` 不保证 SwiftUI 更新或动画已经完成，`.queued` 也不保证最终执行，所属层失效时可能丢弃。不能在仅接受或排队时提交依赖实际完成的业务状态。根请求继续使用 `NavigationRequestResult` 区分应用、确认及延迟阶段。批准／取消确认及其 ID 仅由统一宿主处理，不提供业务手动完成入口。

导航诊断使用共享日志入口的 `navigation` category，最终命令决策记录一次；转发不重复记录，查询 getter 和内部幂等回调不打日志。非法栈／容器配置使用 `notice`，正常应用、等待、无操作及生命周期／事务阻挡使用 `debug`，不能把正常幂等当作 error。动态层／栈身份按 private 处理，不输出业务 Destination。级别和隐私遵循[通用规范](Common.md#日志)。操作结果方案及验证见[2026-10-22 任务记录](../Tasks/task-2026-10-22-navigation-results/000-plan.md)。

需要回传结果的页面使用发起方传入的 Binding。CalendarYearFeature 创建 `.yearPicker(id:selection:modelContext:)`，在 Binding setter 中核对当前 ID、store generation、数据上下文及一次消费标记，保留年份过渡行为。页面先取得 dismiss() 接受，再写回所选年份。

导航 owner 与宿主的生命周期要覆盖其呈现流程。store identity 改变时，应重建依赖新容器的页面、失效旧容器的呈现会话，并显式保留或完成正在协调的外部导航。下载详情持续读取 store coordinator 的进度，不将打开时的快照当作持续状态。

来源或 store 失效时立即撤销结果资格，取消自己的任务和 handle，并清理发起方的 active 字段。取消可能尚未显示，不依赖 onDismiss 执行这些动作；已构建页面的路由保留退出动画需要的数据引用。

## NAV-04 — 系统 API 的合法使用

通用宿主负责实际展示。以下使用允许保留：

- `NavigationScopeView` 与 `navigationHost` 内部递归呈现宿主中的 `NavigationStack`、`.sheet`、`.fullScreenCover` 等，绑定对应 Router／presentation 状态。业务内容复用这些宿主。
- App 自行声明两栏或三栏 `NavigationSplitView`，前面的列表栏使用 App selection，最后一栏由 `NavigationScopeView` 提供唯一的 detail `NavigationStack`。分栏接入遵循 NAV-07，不在前栏另建 push 栈。
- `NavigationLink(value:)` 使用项目 destination，写入 Router 绑定的 path，并由所在栈注册 destination。
- 仅提供导航栏、没有页面 push 的集中 Tab 根容器。新增 push 时，必须明确其 Router scope／path。
- 仅用于独立渲染的 `#Preview` 和测试容器。helper 被 App 调用时，按真实调用链重新判断。
- 组件展开等不需要阻塞外部导航的局部交互状态。
- Core 的统一 alert 宿主使用原生 `UIAlertController`，通过真实关闭 completion 串行处理业务提示与离开确认。业务页通过呈现环境提交 `.alert(route)`，不另挂 `.alert`／`.confirmationDialog` 形成第二套提示状态；旧 `alert(item:content:)` 确认宿主已移除。

不能仅凭搜索到某个 API 判违规；需要指出实际 owner、宿主、触发链和未同步的导航结构。

## NAV-05 — 关闭和外部导航协调

关闭动作应明确对应哪一次请求。页面按钮使用本层 `presentation.dismiss()`；来源的自动关闭使用本次 `NavigationPresentationHandle.dismiss()`，未展示时取消，已展示时走正常关闭。handle 不暴露 ID、节点或状态，不保活 Router，释放 handle 本身不取消请求。按钮关闭、下滑关闭和自动关闭由 Core 同步；关闭子详情不能误关父页面，进度消失不能关闭无关模态。

页面提交的 onDismiss 直接转发 SwiftUI sheet／fullScreenCover 的关闭回调。仅收到原生回调才通知，取出后清空，避免重复调用；回调前先完成对应导航结构的收尾。拒绝、未展示取消、宿主拆除和 Router 销毁不补发 onDismiss，也不保证祖先与后代的通知顺序。业务主动取消时同步撤销自己的状态，正常关闭时用本次回调清理；旧回调不得清空新请求。这个收敛后的边界见 [呈现接口简化](../Tasks/issue-165-presentation-ownership/002-native-dismissal.md)，替代原方案的通用结束合同。

外部导航经过 Router 的请求协调：有模态时先向最前作用域提交离开确认，取消保持原树和路径；批准后关闭 presentation，等待根宿主报告 dismissal 完成，再应用目标。子节点的关闭通知不能冒充整棵根 presentation 已关闭。

页面宿主只使用 SwiftUI sheet／fullScreenCover 及其 onDismiss，不安装额外 UIViewController 生命周期探针。SwiftUI 请求本次内容后，节点等待原生关闭回调；内容构建不作为显示完成证据。业务 alert 继续使用已有原生 alert 宿主，关闭后释放 presenter 内容，异步按钮动作及排队导航由原有 alert session 协调。

当前已有业务 alert 时，保留原提示并保存最新外部请求及其确认要求；等 alert 实际关闭、按钮异步动作完成，再处理排队提示和外部请求。有页面模态时随后显示离开确认，只有根 alert 时直接导航。业务按钮不自动批准外部请求，不在已有 alert 上叠第二个 alert，也不用固定延时推测关闭完成。

后续业务提示按同层队列顺序处理；alert 按钮可以排入结果提示。若队列里是页面模态，等该页关闭后继续。关闭当前模态也须等活动 alert／业务动作完成，随后丢弃失效层的排队呈现。重复关闭回调不能重复执行业务动作。任何子模态仍在关闭时，不提前从父层展示离开确认。

提示与请求 ID 绑定，相同待确认请求去重，新请求替换提示时必须产生新 ID。旧确认不能批准新目标。已批准的导航可采用 latest-wins，但关闭动画期间收到的未批准链接仍需单独确认，不能复用上一次批准。没有模态的冷启动直接导航，重复完成通知应幂等。

`@Environment(\.dismiss)` 可在正确的呈现环境中使用；要沿调用链检查它关闭的是页面、栈中的一页还是窗口，以及框架绑定是否同步，不能只凭属性声明判违规。

## NAV-06 — 容器归属、例外与验证

每个导航栈由一个 `NavigationScopeView` 宿主提供容器，业务详情不得重复创建同一栈的 NavigationStack。自带多 Tab 容器的页面通过本层 `NavigationPresentationContext` 取得各 Tab 栈，并绑定本层 `selectedStack`；Destination 的 `providesNavigationContainer` 返回 true，避免重复包装（旧宿主 `providesNavigationStack == true` 表示 Core 包栈，语义相反）。内部不再挂第二份呈现宿主，页面级子模态仍由该层唯一宿主管理。

App 主 Tab 页面由 `.mainTabs` Destination 描述，根层选择它作为入口，使用 `NavigationRootView` 构建；外部通过 `navigationHost(context:configuration:)` 集中提供 `NavigationHostConfiguration`，统一承载根与递归节点的 sheet/full-screen/alert、context 注入和确认提示。各栈只声明身份与根页面，自动读取所在导航树的配置，并在自己的真实 NavigationStack 内注册 destination；不能只在 TabView 外层注册一次。

配置属于 View 宿主，每棵导航树在根部注入一次。根、各栈 push 和递归模态继承同一配置；独立窗口或 Preview 可以配置自己的导航树。App 共享 store 环境仍从根部注入。单页的 Binding、ModelContext 和业务 state 通过路由关联值直接传给页面，不增加配置工厂、查找字典或模态专属环境容器。

业务配置提供页面和提示文案，容器归属由 Destination 声明。alert(for:presentation:) 配对提示与 handler，实际关闭后执行并等待异步动作，再调用本次提示的回调及推进导航。配置不提供全局关闭回调。CalendarStoreFailure 等结构化值可直接进入 alert route，由配置映射文案。

Core 节点保存路由参数与本次关闭回调，不保存按次配置；呈现队列继续由 Router 管理。NavigationPresentationEndpoint、NavigationPresentationRenderRecord、NavigationModalMount 和宿主 teardown 探针已移除。内部请求身份只用于关闭配对和防重复；handle 弱引用 Router 和请求，旧 handle 不延长业务资源的寿命。

删除 `retainedPresentationRoutes`、`retains(context)`、`alertRoutes` 及 App 集中清理链。业务不得通过节点、内部 ID、等待状态、`isActive` 或手动系统完成通知代替原生关闭回调约定。App 集成测试用普通 `import NavigationCore`、实际 builder、真实宿主和释放探针；Core 内部合同测试使用 `@testable`。独立 Preview 仍提供根配置，已有导航树中的多 Tab 模态不再挂第二个根宿主。

需要真实窗口的 App 集成测试及 Core 物理呈现测试运行在 `project.yml` 的 App-hosted `ChineseCalendarUITests`，使用前台 `UIWindowScene` 和共享串行窗口租约；无前台 scene 必须明确失败。独立 SwiftPM runner、仅 `UIWindow(frame:)`／`onAppear` 或 scheme MacroExpansion 都不能代替 App host 配置。纯 Core 结构测试仍可使用 SwiftPM；App-hosted 自动测试也不能代替实际手势和宽窄布局交互。测试环境的选择依据见 [Issue #165 实施调整](../Tasks/issue-165-presentation-ownership/000-plan.md#2026-10-23-实施调整接手边界与测试宿主)。

Core 管理当前运行时的根、path、Tab 选择和递归模态，不提供完整导航树的公开快照、编码或恢复 API，App 也没有整树恢复适配。运行期间保留父层状态和各 Tab 路径，不等于跨启动恢复。新建 Router 和模态通过正常初始化建立；未来业务持久化需求需单独定义保存范围、数据校验和迁移策略，不能将临时会话、回调或 ModelContext 视为可保存的导航身份。

新增例外需要记录具体调用链、独立作用域的用途、状态 owner 和验证方式，不能按目录一概放行。对导航改动验证打开、关闭、返回、再次打开、涉及的嵌套、deep link、Tab 隔离及上下文失效。源码、结构测试、构建、Preview 与实际交互分别记录，构建或 Preview 不代替 Simulator 交互。

本次迁移的方案与验收见 [Issue #145](../Tasks/issue-145-unified-navigation/000-plan.md)，`NavigationLayer` 与多栈分离见 [008](../Tasks/issue-145-unified-navigation/008-presentation-layers.md)，独立环境 API 见 [009](../Tasks/issue-145-unified-navigation/009-separate-context-apis.md)，独立栈状态与内部依赖分离见 [010](../Tasks/issue-145-unified-navigation/010-independent-stack-state.md)。

业务 alert 的统一呈现与导航排队见 [011](../Tasks/issue-145-unified-navigation/011-unified-alerts.md)。

根宿主配置的迁移与验收见 [Issue #148](../Tasks/issue-148-navigation-host/000-plan.md)。

统一页面构建方法与共享数据环境见 [Issue #148 后续调整](../Tasks/issue-148-navigation-host/002-unified-destination-builder.md)。

### 同构导航层与容器归属

- 每层使用同一种状态和渲染流程：入口 Destination、栈集合、选中栈和唯一直接呈现内容；页面模态递归持有下一层。根层没有父层，不能关闭自身，但不因此限制内容结构。
- 每个可导航入口均使用 `CalendarDestination`。Destination 描述页面身份和容器归属，不声明 root／栈根／push／模态权限；相同页面可以在不同位置构建。主 Tab 的 `.mainTabs` 表达页面内容，不表达其固定位置。
- `providesNavigationContainer == true` 时，页面提供 TabView／NavigationSplitView 等导航结构；false 时 Core 提供 `.primary` NavigationStack。两种方式在根层和任意模态层都可选择。普通 push 在当前栈构建页面内容，不因为入口声明重复创建一个层。
- 外部容器从当前层取得栈和 `NavigationPresentationContext`；Tab 容器绑定当前层 `selectedStack`，分栏 selection 不映射为互斥 Tab；不得捕获 `router.rootPresentation` 或全局根 Tab 选择代替当前层。不同层同名栈隔离。
- 根与模态共用正常初始化校验，不依赖快照模型。普通层只有 primary 栈；外部容器也必须为选中栈和所有带路径栈声明根。栈根可以与最初层入口不同，Preview 的 root closure 不能绕过根声明。
- 框架不再提供 `NavigationContainerKind` 或入口白名单。App 可组合原生 SplitView 与 detail 单栈，选择联动及布局状态按 NAV-07 由 App 持有；通用接入可用不代表分栏交互已经验证。
- Context 的层 ID 判断根／模态位置，path 判断当前栈根部；层入口只说明这一层从哪里开始。关闭控件根据实际运行时位置决定，不根据 Destination 白名单推断。

同构层方案与当时验收见 [同构导航层](../Tasks/task-2026-10-20-homogeneous-navigation-layers/000-plan.md)，它替代了 [Issue #152](../Tasks/issue-152-destination-containers/000-plan.md) 的入口白名单和 Core 多栏预留声明。完整快照恢复的移除、正常初始化与 Context Store 生命周期见 [Issue #159／#158](../Tasks/issue-159-navigation-runtime/000-plan.md)；历史恢复验证只对应其当时版本。

## NAV-07 — App 原生分栏与详情栈组合

App 在 SDK 外声明原生 `NavigationSplitView`，整个容器由 Destination 构建。两栏的前栏、三栏的前两栏是选择列表，没有独立 push 栈；App 管理分类与对象的业务联动，以及 `columnVisibility`、`preferredCompactColumn` 和系统对这些 Binding 的写回。当前对象从详情根 Destination 投影，不另存一份独立 selection。SDK 不引入通用容器 Context、列类型或多栏状态快照，也不接管宽窄布局的切换。

最后一栏使用 `NavigationScopeView(stack:presentation:)`，通过所在导航树的 `navigationHost` 配置统一构建详情根、空态和 push Destination。空选择使用明确的空态根路由，例如 `.debugSplitEmpty`；选中对象使用 `.debugSplitDetail(item:level: 0)`。该宿主提供唯一的 detail `NavigationStack`，根页面不计入 path。一个详情栈只有一个 Context，详情根页与 push 后代共享它；前栏显式持有详情 Context 或调用业务动作，不能从隐含环境推断目标栈。`rootDestination` 在有效 Context 上一定有值，可选返回值用于表达未声明或已失效的 Context。

App 的选择动作必须明确根内容与路径的关系：

- 选择不同对象时通过 `setRootDestination` 同时换根并清空详情 path；重复选择同一对象保留根和 path。
- 切换分类时显式决定保留当前详情及其 path，或同时清空详情选择与 path；不得让多个 `onChange` 相互回写来猜测策略。
- 清空对象选择使用空态根 Destination，同时清空 path，不能留下挂在空详情上的旧路径。
- 根或路径操作结果的 `isApplied` 为 true 后才能同步修改 App 分类和布局；未应用时保持原状态。重复选择等只更新布局的动作也应先确认栈允许操作，例如检查 `navigation.setPath(navigation.path).isApplied`。这些方法沿用本栈有效性与事务访问约束，不能绕过离开确认或关闭事务。

分栏容器作为 sheet／full-screen 入口时，Destination 声明 `providesNavigationContainer == true`，Core 跳过外层包栈；内部只为最后一栏创建详情栈。同层仍只有一个 presentation host，分栏容器继承既有配置与本层 `NavigationPresentationContext`，不再挂第二份 `navigationHost`。不同 Tab 或模态中的详情 Context 独立，关闭后的旧 Context 继续失效。移除入口白名单不改变“一层同一栈一个宿主”的接入要求；普通 push 不为嵌套容器创建新的栈命名空间。

业务 alert、嵌套模态与外部请求沿用 NAV-05 的串行协调和真实 dismiss 完成通知。App 不在请求提交、等待确认或仅收到批准时提前修改外部 selection；取消保留 selection、path 与原呈现状态，只有批准的请求实际应用时才修改 selection。详情根和 path 属于当前导航层的运行时状态，分类、保留策略、栏可见性及紧凑布局偏好由完整分栏容器的 `@State` owner 持有。历史查询子树可随 store identity 重建，`CalendarHistoryContainer` 和 `CalendarDebugSplitContainer` 的布局 owner 留在该边界之外；普通重绘、Tab 切换及子页覆盖不释放它。当前不提供完整分栏界面的跨启动恢复。

Issue #146 使用固定小数据的 DEBUG 普通／两栏／三栏入口验证组合行为。正式历史 Tab 在[历史三栏任务](../Tasks/task-2026-10-22-history-split-view/000-plan.md)中接入同一架构：前两栏为正统时间线与资料种类，最后一栏复用所在层的历史详情栈；时期与资料选择从稳定详情根路由投影。宽窄切换、深 path 下的系统返回以及布局 Binding 写回必须取得交互证据，不能用源码、测试或构建结果代替。基础组合方案与九项验收见 [Issue #146](../Tasks/issue-146-navigation-containers/000-plan.md)。

栈根路由化、非可选路径及本轮验证见 [002：栈根统一使用 Destination](../Tasks/issue-146-navigation-containers/002-routed-stack-roots.md)。
