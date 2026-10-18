# NavigationCore

`NavigationCore` 用强类型数据表示 Tab、push path、递归页面模态和业务 alert。`present` 接收路由数据，宿主根据路由构建页面或系统提示。模块不解析 URL、不持有业务模型或查询、不保存 View 或页面回调。

## 源码目录

按职责分为一层目录，全部属于同一个 `NavigationCore` target；根层、Tab 和模态复用其中的类型。

| 目录 | 职责与阅读入口 |
| --- | --- |
| [State](State/) | 导航结构：独立 `NavigationStackState`、组合它们的 `NavigationLayer`、层与栈 ID、`NavigationPresentationNode`、`NavigationAlertNode` 和统一呈现枚举 |
| [Routing](Routing/) | 状态操作与请求协调：`NavigationRouter`、栈／呈现 Context，以及请求、结果和确认数据 |
| [Restoration](Restoration/) | 根、层与模态快照，以及编码、结构校验和恢复 |
| [SwiftUI](SwiftUI/) | 栈与模态宿主、系统呈现适配，以及业务 alert／确认提示的系统适配和文案 |

理解状态结构可从 [NavigationLayer](State/NavigationLayer.swift) 开始；页面调用入口见 [NavigationContext](Routing/NavigationContext.swift)，界面接入见 [NavigationScopeView](SwiftUI/NavigationScopeView.swift) 与 [NavigationPresentationHost](SwiftUI/NavigationPresentationHost.swift)。模块日志入口保留在根目录，测试仍位于相邻的 `NavigationCoreTests` target。

## 状态与作用域

```text
NavigationRouter<Scope, Destination, AlertRoute>
└── 根呈现层 NavigationLayer
    ├── selectedStack
    ├── stacks[StackID] → NavigationStackState
    │   └── rootDestination / path
    └── presentedContent?（二选一）
        ├── page → id / destination / style / 下一呈现层
        │                                    └── 同样的栈与 presentedContent
        └── alert → id / 业务提示路由（没有栈，也没有下一层）
```

每层包含独立栈集合和一个可选的直接呈现内容，页面模态与业务 alert 共用 `NavigationPresentation` 状态。`sheet`／`fullScreen` 是页面节点的只读样式查询。一个层可以只有一个栈，也可以包含多个 Tab 的栈；alert 位于呈现链末端，不能在它上面再叠一个系统 alert。

每个 `NavigationStackState` 是该栈根身份与 path 的唯一运行时来源，不依赖 Router、呈现层或模态生命周期。层的 `roots`／`paths` 是栈对象的值投影，供快照与兼容 API 使用。整批替换路径和恢复根快照时更新原栈对象，已有根上下文继续连接真实状态。仅获取上下文不会在快照里增加空路径条目；内部保留“未记录路径”和“显式空路径”的区别，页面读取时两者均为空数组。

环境上下文按职责分为两种：

- `NavigationPresentationContext<Scope, Destination, AlertRoute>`：负责当前层的 `present`、`dismiss`、离开确认及多栈容器的 `selectedStack`，没有 path／push／pop。层级入口由呈现宿主注入；栈宿主再注入带发起栈身份的入口，所有入口共享同一层状态。
- `NavigationContext<Scope, Destination>`：每栈一个实例，弱引用独立栈状态，通过 `NavigationStackAccess` 的 `isActive`／`canMutate` 判断约束访问；实现不引用 Router 或 `NavigationLayer`。只负责本栈的身份、有效性、path／push／pop，不提供 `present`／`dismiss`／`isPresented`。页面按需分别读取两种环境。

`NavigationStackAccess` 只描述栈是否有效、是否允许修改，不解释阻止操作的原因。Router 作为组合方，用弱捕获的闭包实时检查层与栈的对象身份、待确认请求和关闭事务。这样上下文既不会延长 Router 或已关闭层的生命周期，也不必理解 presentation；栈状态与访问约束是内部类型，页面继续通过现有公开 API 取得上下文。

`NavigationStackID<Scope>` 用 `.primary` 表示普通模态的默认栈，用 `.scope(scope)` 表示命名栈。同名栈在不同呈现层中互相隔离。根 Router 的 `selectedScope`、`paths` 和 `rootDestinations` 是根层命名栈的投影。

| 上下文 | 栈导航 | 模态呈现 |
| --- | --- | --- |
| `router.context(for: tab)` | 指定根 Tab 的 path／push／pop | 不提供 |
| `router.context(for: node)` | 模态 `.primary` 栈的 path／push／pop | 不提供 |
| `layer.context(for: .scope(tab))` | 当前层指定 Tab 的 path／push／pop | 不提供 |
| `router.rootPresentation` | 不提供 | 根层 present；自身 dismiss 返回 false |
| `router.presentationContext(for: node)` | 不提供 | 当前模态层 present；dismiss 关闭当前模态及其后代 |
| `presentation.scoped(to: stackID)` | 不提供 | 共享原层呈现状态，present 额外检查发起栈是否选中 |

`dismiss()` 只存在于呈现上下文，关闭当前所在的模态及其后代；根层的呈现上下文返回 `false`，不会关闭它展示的模态。栈内返回由 navigation 的 `pop()` 负责。App 的调用规则见[导航规范 NAV-03](../../Docs/Conventions/Navigation.md#nav-03--发起作用域与生命周期)。

`navigation.push`／`pop` 和 `presentation.present`／`dismiss` 返回 Bool 表示是否接受操作。已关闭节点的上下文失效，不能操控随后恢复的同 ID 新节点。`NavigationScopeView(context:presentation:...)` 从显式传入的呈现入口取得 `scoped(to:)` 入口并注入后代，保留发起栈身份，防止后台 Tab 的旧回调弹窗。页面直接使用呈现环境，无需把 navigation 传入 present。

同层已有页面模态时，新的 present 被拒绝，应通过该模态自己的环境继续呈现。当前层有 alert 或正在处理其按钮动作时，后续呈现按顺序排队；返回 true 表示已接受，可能还未显示。页面正在关闭时拒绝新的页面请求；业务 alert 可以排队等关闭完成，所属层失效则一起丢弃。层级入口不绑定某个栈，适用于 TabView 附件等控件。离开确认、alert 和根关闭事务期间，局部 push/pop 暂停；栈上下文只通过窄接口获得是否允许修改，不理解呈现状态。

需要从父层明确关闭其子模态时，使用 `dismissPresented(id:)`；旧 ID 不会关闭后来展示的新节点。系统下滑关闭也由宿主写回同一入口。

根 Router 的 `push(_:on:)` 用于明确切换 Tab 后 push；保留的 `presentSheet`／`presentFullScreen` 在整棵树最前节点继续嵌套。普通页面优先使用局部 context，不让全局操作猜测发起作用域。

## 完整接入示例

下列示例独立于日历业务。每个 Tab 由 `NavigationScopeView` 提供一个栈；根只挂一次 `navigationPresentations`，后者递归提供模态栈和局部 context。栈宿主显式接收对应层的呈现入口，再给后代注入绑定了发起栈的环境。

```swift
import NavigationCore
import SwiftUI

enum AppTab: String, Codable, Hashable { case home, history }
enum AppRoute: Codable, Hashable { case detail(String) }
nonisolated enum AppAlert: Codable, NavigationAlertRoute {
    case notice
    enum Action: Hashable { case acknowledge }
}
typealias AppNavigation = NavigationContext<AppTab, AppRoute>
typealias AppPresentation = NavigationPresentationContext<AppTab, AppRoute, AppAlert>

struct DemoRoot: View {
    @State private var router = NavigationRouter<AppTab, AppRoute, AppAlert>(selectedScope: .home)

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedScope) {
            Tab("首页", systemImage: "house", value: AppTab.home) {
                NavigationScopeView(
                    context: router.context(for: .home), presentation: router.rootPresentation
                ) {
                    DemoPage(route: .detail("首页"))
                } destinationContent: { DemoPage(route: $0) }
            }
            Tab("历史", systemImage: "clock", value: AppTab.history) {
                NavigationScopeView(
                    context: router.context(for: .history), presentation: router.rootPresentation
                ) {
                    DemoPage(route: .detail("历史"))
                } destinationContent: { DemoPage(route: $0) }
            }
        }
        .navigationPresentations(
            context: router.rootPresentation,
            confirmationContent: { _ in
                NavigationConfirmationContent(
                    title: "离开当前页面？",
                    message: "将关闭当前弹出页面并打开链接。",
                    confirm: "关闭并前往",
                    cancel: "留在当前页面"
                )
            },
            alertContent: { alert in
                switch alert {
                case .notice:
                    NavigationAlertContent(
                        title: "提示", message: "这是一个业务提示。",
                        buttons: [NavigationAlertButton("知道了", action: .acknowledge)]
                    )
                }
            },
            onAlertAction: { route, action, presentation in
                // 根据 route 和 action 执行业务动作；异步工作可以在这里 await。
                // 不需要手动关闭 alert，宿主调用此闭包时系统提示已关闭。
            }
        ) { DemoPage(route: $0) }
    }
}

struct DemoPage: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(AppPresentation.self) private var presentation
    let route: AppRoute

    var body: some View {
        List {
            Button("下一页") { navigation.push(.detail("下一页")) }
            Button("弹窗") { presentation.present(.sheet(.detail("弹窗"))) }
            Button("全屏") { presentation.present(.fullScreen(.detail("全屏"))) }
            Button("业务提示") { presentation.present(.alert(.notice)) }
        }
        .navigationTitle(title)
        .toolbar {
            if presentation.isPresented {
                Button("关闭") { presentation.dismiss() }
            }
        }
    }

    private var title: String {
        switch route { case let .detail(title): title }
    }
}
```

同一个 `DemoPage` 在 Tab 内 push，在 sheet 中 push，或在 sheet 上继续 present，均使用环境中的当前作用域。也可使用 `NavigationLink(value:)`；`NavigationScopeView` 已注册 destination，不应重复注册或再包同一层 `NavigationStack`。

`rootDestinations` 保存可变根页面身份，`setRootDestination` 会清空相应 path；调用方的 root builder 负责读取并渲染该根身份。静态 Tab 根页可像示例一样直接构建。

## 模态内部包含多个 Tab

为多 Tab destination 设置 `providesNavigationStack: false`，让它自行组合多个 `NavigationScopeView`。呈现时用 `initialStack: .scope(...)` 指定初始 Tab；这些栈属于新模态层，不会复用根 Tab 的 path。下面的内容可以由任意对应的 destination builder 返回：

```swift
struct DemoModalTabs: View {
    @Environment(AppPresentation.self) private var presentation

    var body: some View {
        @Bindable var presentation = presentation
        TabView(selection: $presentation.selectedStack) {
            Tab("首页", systemImage: "house", value: NavigationStackID<AppTab>.scope(.home)) {
                NavigationScopeView(
                    context: presentation.context(for: .scope(.home)), presentation: presentation
                ) {
                    DemoPage(route: .detail("模态首页"))
                } destinationContent: { DemoPage(route: $0) }
            }
            Tab("历史", systemImage: "clock", value: NavigationStackID<AppTab>.scope(.history)) {
                NavigationScopeView(
                    context: presentation.context(for: .scope(.history)), presentation: presentation
                ) {
                    DemoPage(route: .detail("模态历史"))
                } destinationContent: { DemoPage(route: $0) }
            }
        }
    }
}
```

两个栈注入不同的 `AppNavigation`，以及各自带发起栈身份的 `AppPresentation`。呈现入口的对象可以不同，但它们访问同一个层的选中栈、唯一子模态和确认状态。业务页面通过 navigation 调用 `push`／`pop`，通过 presentation 调用 `present`／`dismiss`；层级控件只取不绑定栈的 `AppPresentation`。这个容器不再挂第二个 `navigationPresentations`，子模态和确认由外部递归宿主承载。App 中的完整例子是 `FullStoreDownloadPreview`，其发起方指定 `initialStack: .scope(.years)`。

## 容器策略与提示

- `navigationPresentations` 统一绑定 sheet/full-screen/alert、注入子 context、处理关闭完成及确认提示。`onDismiss` 在任意一层关闭完成后通知业务清理会话；不要再次从该回调执行全局导航。
- `NavigationPresentationNodeView(node:context:...)` 是可单独组合的递归节点宿主，接收 `NavigationPresentationContext`；通常直接使用根 modifier 即可。
- `providesNavigationStack` 默认对每个 destination 返回 true，宿主为它提供 `.primary` 栈。自带 Tab 的内容返回 false，并将内部 `NavigationScopeView` 绑定到本层命名栈；完全不需要 push 的内容也可返回 false，只使用呈现 context。不要另设局部 path 或重复包装栈。
- 业务提示由 `AlertRoute` 驱动，按钮返回其关联的 `Action` 数据。离开提示由 `NavigationConfirmation` 驱动，两者共用系统 alert 宿主；alert 不拥有导航栈。没有业务提示的调用方可使用 `NoNavigationAlert` 作为第三个泛型。
- sheet 的拖动指示器、detents 与导航栏是不同能力。导航栏由栈提供；需要指示器时在对应业务内容设置 `.presentationDragIndicator(.visible)`，不因缺少指示器再嵌套一层栈。

## Deep link 与离开确认

URL、通知或启动参数由 App 解析为业务地址，再提交请求：

```swift
router.submit(
    .replacePath([.detail("链接目标")], on: .history),
    confirmIfPresented: true
)
```

没有模态时立即应用并返回 `.applied`。有模态时返回 `.awaitingConfirmation`，保留全部 path 和模态，`pendingConfirmation` 保存请求及唯一 ID。**必须为宿主提供 `confirmationContent` 或自行处理 pendingConfirmation**；Core 不提供默认业务文案。

页面若需要业务自己的离开决策，可不提供默认 `confirmationContent`，直接观察呈现环境的 `confirmation`，完成保存或确认后在呈现 context 调用 `confirmNavigation(id:)`／`cancelNavigation(id:)`。只有当前应处理请求的最前呈现层会读到确认数据，同层多个 Tab 共享该数据；由容器协调一次提示，避免每个 Tab 重复处理。根可通过 `pendingConfirmation` 管理整笔请求。不要同时启用默认提示和页面自己的提示。

默认宿主只在最上层模态展示提示。取消保留页面；确认调用 `confirmNavigation(id:)`，先关闭根模态树，返回转场前的页面结构，直到根宿主报告 `onDismiss` 才应用请求。子模态的关闭通知不能提前完成全局跳转。

相同待确认请求去重；不同请求替换待确认数据并生成新 ID，系统关闭旧提示再展示新提示，旧提示不能批准新目标。已批准关闭期间新到达的链接仍需单独确认：先完成原请求，转场完成后在根提示新请求。模态自行关闭也不会自动批准待确认请求。

提示宿主使用 `UIAlertController`，将按钮动作与真正的关闭完成分开。新确认 ID 会先关闭旧提示再展示新提示，旧 ID 不能批准新请求。`dismiss(animated:completion:)` 的 completion 在 `viewDidDisappear` 之后调用，框架以此推进流程，不使用固定延时。旧的 SwiftUI `alert(item:content:)` 确认宿主已移除；业务页面也不直接挂另一份 alert。依据见 [Apple 的关闭完成说明](https://developer.apple.com/documentation/uikit/uiviewcontroller/dismiss(animated:completion:))。

`submit` 默认 `confirmIfPresented: false`，供业务已经批准的导航使用；有模态时返回 `.deferredUntilPresentationDismisses`，关闭期间以最新的已批准请求为准。自定义宿主必须在真实根关闭完成后调用 `presentationDidDismiss(isRoot: true)`；使用内置宿主则不必手动通知。

## 业务 alert 期间收到新请求

```swift
presentation.present(.alert(.notice))
router.submit(.push(.detail("链接目标"), on: .history), confirmIfPresented: true)
```

此时 `submit` 返回 `.deferredUntilAlertDismisses`，保留最新请求及其原本的确认要求，原页面和原业务提示保持不变：

1. 用户回答当前业务提示，系统完成关闭动画。
2. 宿主用强类型 `Action` 调用 `onAlertAction`，等待异步业务动作结束；重复关闭回调不会重复执行动作。
3. 依次处理同层排队的业务提示。业务动作可以再 `present(.alert(...))` 显示结果；如果队列中是页面模态，则展示该页，等它关闭后继续队列。
4. 队列处理完后，重新评估外部请求。有页面模态则显示离开确认；只有根 alert 的场景直接跳转。
5. 用户取消离开则保留页面；同意则等模态实际关闭，再执行请求。

业务 alert 的“确定”只处理业务动作，不表示批准等待中的 Deep Link。按钮本身明确要求导航时，可以在 `onAlertAction` 里 `submit` 已批准的请求，它也会等动作和系统关闭完成。请求之间采用 latest-wins，不复用之前请求的确认授权。

页面的关闭请求也会等活动 alert／业务动作完成，避免移除仍负责展示提示的页面。关闭后丢弃该层排队的提示，旧 Context 和旧回调不能控制新层。`router.alertRoutes` 可查询当前与排队中的业务路由，供 App 清理临时消息数据；它不包含导航确认。

## 快照与恢复

当 Scope、Destination 和 AlertRoute 都是 Codable 时：

```swift
let data = try JSONEncoder().encode(router.snapshot)
let snapshot = try JSONDecoder().decode(
    NavigationSnapshot<AppTab, AppRoute, AppAlert>.self,
    from: data
)
let accepted = router.restore(snapshot)
```

快照包含根 selectedScope／rootDestinations／paths，以及唯一 `presentation`。`NavigationPresentationSnapshot<Scope, Destination, AlertRoute>` 的 `.node` 保存页面节点及其内部层，`.alert` 保存提示 ID 和业务路由；alert 没有下一层。同层同时展示页面和 alert 在类型结构上无法表达。

恢复会创建新的模态节点、层和栈对象；之前保存的模态 context 无法控制新节点，也不能经它重新取得同 ID 新层的栈。根层复用已有栈对象及上下文，清除快照中缺失的根身份和路径。`restore` 在有活动模态／alert、等待关闭、处理 alert 动作、等待导航请求或待确认时返回 false；重复节点 ID 的快照也被拒绝，且不部分修改原状态。当前格式替代本分支此前未发布的快照格式，没有提供旧格式兼容解码；独立栈状态拆分不改变当前快照字段。

快照不含 View、ModelContext、闭包、排队的呈现／导航请求、执行中的业务动作和转场。业务应检查 `snapshot.destinations` 和 `snapshot.presentation?.alerts` 是否仍有效，并自行决定何时保存、版本迁移和数据不可用的呈现方式。框架不会自动写入 UserDefaults。

App 示例的 `CalendarRouter.restorableSnapshot`／`restore` 只接受可以重新查询的日历与历史地址，拒绝年份选择器、下载详情、演示的临时会话、业务提示及仅 DEBUG 存在的测试路由。实际自动跨启动恢复不在当前 App 行为中。

## App 示例与迁移

- `CalendarHomeTabView`：三个 Tab 绑定各自 context。
- `CalendarNavigationHost`：根宿主、外部请求、下载错误及数据生命周期协调。
- `CalendarAlert`／`CalendarAlertContent`／`CalendarHomeCoordinator+Alerts`：提示路由、文案和按钮业务动作；设置清理确认及结果提示也走统一宿主。
- `CalendarPresentedDestinationView`：从路由数据构建业务页面并提供数据环境。
- `CalendarPresentationMenu`：历史列表／资料卡的 sheet 和 full-screen 入口。
- `DynastyFactCard`：同一页面组件在 Tab 或模态里调用当前 context.push。
- `CalendarHomeCoordinator`：年份选择回传、演示状态等业务会话；它们不构成第二套模态状态。
- `CalendarDebugActionsMenu`：Debug 构建中，从设置页的“调试 → 调试操作”打开导航测试或下载调试。
- `CalendarDebugNavigationView`：由 `.debugNavigation(id:)` 数据构建，显示当前作用域、path 长度与页面 ID；同一页可继续 push、sheet、full-screen、pop、dismiss，也可触发跨 Tab 与 Deep Link 确认，以及普通 alert、连续两个 alert、从 alert 按钮导航、alert 期间提交外部导航。调试页复用正式宿主，不自行创建栈或模态。

新增 App 调试类别时，在 `CalendarDebugActionsMenu` 组合对应动作；新增业务测试页面仍先定义 destination，再由 `CalendarDestinationView` 构建。调试工具不进入 NavigationCore。入口、范围及验证见 [Debug 操作记录](../../Docs/Tasks/issue-145-unified-navigation/007-debug-actions.md)。

本轮 alert 接入：Router、呈现 Context、模态节点、快照增加第三个 `AlertRoute` 泛型；栈 `NavigationContext` 仍只有两个泛型。`NavigationScopeView` 增加显式 `presentation:` 参数。接入业务提示时向宿主提供 `alertContent` 与 `onAlertAction`，并从页面调用 `presentation.present(.alert(route))`；`presentAlert(route)` 是等价便捷入口。

此前版本的迁移点：`rootContext` 改为 `rootPresentation`；`navigationPresentations` 和 `NavigationPresentationNodeView` 改接收呈现 context（节点使用 `router.presentationContext(for: node)`）；节点类型增加 Scope 泛型参数。节点 path／sheet／fullScreen 改为只读查询，修改经对应 context。页面的模态和确认操作直接读取 `NavigationPresentationContext` 环境，不再通过栈 context 访问；`NavigationContext` 的 `presentation`、`isPresented`、`present` 和 `dismiss` 已移除。旧 `onChildDismiss` 改用 `onDismiss` 作为业务清理通知。App 已移除重复的 `CalendarPresentationNodeView` 和 destination 注册 helper。

## 依赖与验证

当前 UI 宿主面向 iOS，系统 alert 适配使用 UIKit；本轮没有验证 macOS 等其他平台。模块依赖 Foundation、Observation、SwiftUI、UIKit 及 `ChineseCalendarLogging`；日志只描述结构事件。不得引入具体业务模型、页面、路由规则或数据查询。

`NavigationCoreTests` 使用无业务含义的枚举测试作用域、嵌套、关闭时序、请求确认和快照；`NavigationStackStateTests` 验证无 Router 的栈操作、跨入口单一状态、Observation 隔离、稀疏快照与根上下文恢复。App 集成测试负责业务地址和临时会话边界。真实系统动画、提示点击和环境继承还需 Simulator 交互验证。项目规范见[导航规范](../../Docs/Conventions/Navigation.md)，业务 alert 协调及验证见[011](../../Docs/Tasks/issue-145-unified-navigation/011-unified-alerts.md)，内部拆分结果见[010](../../Docs/Tasks/issue-145-unified-navigation/010-independent-stack-state.md)。
