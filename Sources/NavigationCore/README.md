# NavigationCore

`NavigationCore` 用强类型数据表示 Tab、push path、递归页面模态和业务 alert。`present` 接收路由数据，宿主根据路由构建页面或系统提示。状态与路由层不解析 URL、不持有业务模型或查询、不保存 View 或页面回调；页面构建配置由 SwiftUI 宿主持有。

## 源码目录

按职责分为一层目录，全部属于同一个 `NavigationCore` target；根层、Tab 和模态复用其中的类型。

| 目录 | 职责与阅读入口 |
| --- | --- |
| [State](State/) | 导航结构：独立 `NavigationStackState`、组合它们的 `NavigationLayer`、层与栈 ID、`NavigationPresentationNode`、`NavigationAlertNode` 和统一呈现枚举 |
| [Routing](Routing/) | 状态操作与请求协调：`NavigationRouter`、栈／呈现 Context，以及请求、结果和确认数据 |
| [Restoration](Restoration/) | 根、层与模态快照，以及编码、结构校验和恢复 |
| [SwiftUI](SwiftUI/) | 栈与模态宿主、系统呈现适配，以及业务 alert／确认提示的系统适配和文案 |

理解状态结构可从 [NavigationLayer](State/NavigationLayer.swift) 开始；页面调用入口见 [NavigationContext](Routing/NavigationContext.swift)，界面接入见 [NavigationScopeView](SwiftUI/NavigationScopeView.swift) 与 [NavigationHostConfiguration](SwiftUI/NavigationHostConfiguration.swift)。模块日志入口保留在根目录，测试仍位于相邻的 `NavigationCoreTests` target。

## 状态与作用域

```text
NavigationRouter<Scope, Destination, AlertRoute>
└── 根呈现层 NavigationLayer
    ├── route → 根／模态入口 Destination + 纯身份 ID
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

## Destination 与入口容器

`Destination` 遵循 [NavigationDestination](State/NavigationDestination.swift)。两个声明分别表达容器归属和 Core 容器种类：

- `providesNavigationContainer == true`：页面组织自己的顶层容器，例如根 TabView 或多 Tab 模态，Core 不在外面重复包 NavigationStack。内部每个 Tab 继续使用 Core 的栈。
- `providesNavigationContainer == false`：由 Core 按 `navigationContainer` 承载。当前仅 `.stack` 可用；`.twoColumn` / `.threeColumn` 是预留声明，状态写入和恢复拒绝它们。多栏状态、栏间联动、宽窄折叠和栏目呈现权限仍由 [#146](https://github.com/huahuahu/chinese-calendar/issues/146) 跟踪，不能将其当作已实现能力。

`allowedNavigationEntries` 限定根入口、显式栈根、模态和 push。Core 始终禁止自带顶层容器的页面进入普通栈根或 path。普通根／模态入口自动成为其承载栈的初始根，不另要求 `.stackRoot` 权限；显式配置 Tab 根或替换栈根时才检查该权限。push、path 赋值、Router 请求和快照恢复共用入口校验；无效 `submit` 返回 `.rejected` 且不触发离开确认。普通 push 只复用现有栈，绝不再根据该 Bool 包一层栈。

`NavigationLayerRoute` 为 `.root(destination:)` 或 `.presentation(id:destination:)`，由层状态唯一保存。`presentation.route` / `presentation.destination` 读取本层入口，失效后为 nil；节点的 id/destination 也投影同一个来源。`route.id` 才是缓存、关闭和查找使用的纯身份。push、切 Tab 不改变层入口；同一 destination 再次打开会生成新 UUID。不要把入口 destination 与本栈的 `rootDestination`、path 或当前详情混淆。

| 要判断的事情 | 依据 |
| --- | --- |
| 是否属于 App 根层 | `presentation.id == .root` |
| 是否位于当前栈根部 | `navigation.path.isEmpty` |
| 页面承载需求 | Destination 的容器声明 |
| 本层最初打开什么页面 | `presentation.destination` |

## 根宿主配置与完整示例

根 `NavigationRootView` 根据入口路由构建内容，外部调用一次 `navigationHost(context:configuration:)`。`NavigationHostConfiguration` 只集中定义页面、业务 alert 和离开确认；容器声明已经移入 Destination。每个真实 NavigationStack 由自己的 `NavigationScopeView` 注册 destination。

```swift
import NavigationCore
import SwiftUI

enum AppTab: String, Codable, Hashable { case home, history }
enum AppRoute: Codable, NavigationDestination {
    case root, home, history, detail(String), tabs

    var providesNavigationContainer: Bool { self == .root || self == .tabs }
    var allowedNavigationEntries: Set<NavigationDestinationEntry> {
        switch self {
        case .root: [.root]
        case .tabs: [.presentation]
        case .home, .history: [.stackRoot]
        case .detail: [.stackRoot, .presentation, .push]
        }
    }
}
nonisolated enum AppAlert: Codable, NavigationAlertRoute {
    case notice
    enum Action: Hashable { case acknowledge }
}
typealias AppNavigation = NavigationContext<AppTab, AppRoute>
typealias AppPresentation = NavigationPresentationContext<AppTab, AppRoute, AppAlert>

struct DemoConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = AppTab
    typealias Destination = AppRoute
    typealias AlertRoute = AppAlert

    @ViewBuilder
    func destination(for route: AppRoute) -> some View {
        switch route {
        case .root, .tabs: DemoTabs()
        case .home: DemoPage(title: "首页")
        case .history: DemoPage(title: "历史")
        case let .detail(title): DemoPage(title: title)
        }
    }

    func confirmationContent(for request: NavigationRequest<AppTab, AppRoute>) -> NavigationConfirmationContent? {
        NavigationConfirmationContent(
            title: "离开当前页面？", message: "将关闭当前弹出页面并打开链接。",
            confirm: "关闭并前往", cancel: "留在当前页面"
        )
    }

    func alertContent(for route: AppAlert) -> NavigationAlertContent<AppAlert.Action>? {
        NavigationAlertContent(
            title: "提示", message: "这是一个业务提示。",
            buttons: [NavigationAlertButton("知道了", action: .acknowledge)]
        )
    }
}

struct DemoRoot: View {
    @State private var router = NavigationRouter<AppTab, AppRoute, AppAlert>(
        rootDestination: .root, selectedScope: .home,
        rootDestinations: [.home: .home, .history: .history]
    )

    var body: some View {
        NavigationRootView(context: router.rootPresentation)
            .navigationHost(context: router.rootPresentation, configuration: DemoConfiguration())
    }
}

struct DemoTabs: View {
    @Environment(AppPresentation.self) private var presentation

    var body: some View {
        @Bindable var presentation = presentation
        TabView(selection: $presentation.selectedStack) {
            Tab("首页", systemImage: "house", value: NavigationStackID<AppTab>.scope(.home)) {
                NavigationScopeView(stack: .scope(.home), presentation: presentation)
            }
            Tab("历史", systemImage: "clock", value: NavigationStackID<AppTab>.scope(.history)) {
                NavigationScopeView(stack: .scope(.history), presentation: presentation)
            }
        }
    }
}

struct DemoPage: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(AppPresentation.self) private var presentation
    let title: String

    var body: some View {
        List {
            NavigationLink("资料", value: AppRoute.detail("资料"))
            Button("下一页") { navigation.push(.detail("下一页")) }
            Button("弹窗") { presentation.present(.sheet(.detail("弹窗"))) }
            Button("全屏") { presentation.present(.fullScreen(.detail("全屏"))) }
            Button("多 Tab 弹窗") {
                presentation.present(.tabs, initialStack: .scope(.home), rootDestinations: [
                    .scope(.home): .home, .scope(.history): .history
                ])
            }
            Button("业务提示") { presentation.present(.alert(.notice)) }
        }
        .navigationTitle(title)
        .toolbar {
            if presentation.isPresented {
                Button("关闭") { presentation.dismiss() }
            }
        }
    }
}

#Preview { DemoRoot() }
```

根和模态复用 `DemoTabs`，各自从本层栈状态取得根 Destination。多 Tab 模态不再挂 `navigationHost`：框架已为本层提供唯一递归呈现宿主。普通模态自动以入口 Destination 初始化 `.primary` 根；普通根入口自动初始化初始 scope 的栈根。

`rootDestinations` 保存各栈的根页面身份，`setRootDestination` 清空相应 path，但不改变层入口，替换后的根状态可以保存并恢复。生产栈使用无 root 闭包的 `NavigationScopeView(stack:presentation:)`，从状态读取根路由，直接调用共享页面构建方法。带 `root` 闭包的旧初始化器仅保留给独立 Preview／测试组合；它们不会替生产页面补建路由状态。有效 Context 缺少已声明的栈根属于接入错误；关闭过程中的失效 Context 不再构建根页面。

## 配置与业务上下文

- `destination(for:)` 统一构建根入口、Tab 根、push、模态初始页面和模态内 push 页面。栈与模态入口直接调用 `page(for:)` 方法，不按是否模态分流，也没有转调 builder 的包装 View。
- 配置实现用值类型保存 coordinator 等依赖，并用方法构建 View。App 共享的数据环境在根呈现宿主外统一提供；模态入口只提供本层 presentation，栈宿主提供 navigation 与发起栈信息。页面继承这些环境；年份选择器按 session ID 获取发起页的 selection、ModelContext 和回调。
- 环境默认配置为 nil，栈或模态宿主缺少配置时会报接入错误。类型擦除只发生在 `page(for:)` 方法内，Router 与两个 Context 均不持有配置或 View。Swift 6 使用 MainActor 隔离的路由时，配置显式声明 `: @MainActor NavigationHostConfiguration`。
- App 的 `.root` 和 `.downloadPreview(sessionID:)` 声明自带容器；日历、历史、设置及演示两个 Tab 均保存明确根路由。页面组织 TabView，各栈与呈现仍由 Core 承载。
- `confirmationContent(for:)` 和 `alertContent(for:)` 默认返回 nil。使用业务 alert 必须提供文案；省略确认文案时业务须自行处理 `context.confirmation`，它不会隐式批准请求。
- `handleAlertAction` 在系统提示实际关闭后执行；框架等待异步动作完成，再推进队列或外部导航。`presentationDidDismiss` 在任意层子模态实际关闭、框架处理状态后调用，只用于释放业务会话，不重复执行全局导航。
- `NavigationPresentationNodeView(node:context:)` 是递归节点宿主。单独组合时也须位于同一配置环境内；一般不需要手动创建它。
- 独立 Preview 也配置自己的根宿主。App 的 `SampleDataPreviewHost` 已统一提供配置，`SampleNavigationPreview` 只声明栈和根内容；`FullStoreDownloadPreviewHost` 从自己的根配置打开多 Tab 模态。

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
2. 宿主用强类型 `Action` 调用 `handleAlertAction`，等待异步业务动作结束；重复关闭回调不会重复执行动作。
3. 依次处理同层排队的业务提示。业务动作可以再 `present(.alert(...))` 显示结果；如果队列中是页面模态，则展示该页，等它关闭后继续队列。
4. 队列处理完后，重新评估外部请求。有页面模态则显示离开确认；只有根 alert 的场景直接跳转。
5. 用户取消离开则保留页面；同意则等模态实际关闭，再执行请求。

业务 alert 的“确定”只处理业务动作，不表示批准等待中的 Deep Link。按钮本身明确要求导航时，可以在 `handleAlertAction` 里 `submit` 已批准的请求，它也会等动作和系统关闭完成。请求之间采用 latest-wins，不复用之前请求的确认授权。

页面的关闭请求也会等活动 alert／业务动作完成，避免移除仍负责展示提示的页面。关闭后丢弃该层排队的提示，旧 Context 和旧回调不能控制新层。`router.alertRoutes` 可查询当前与排队中的业务路由，供 App 清理临时消息数据；它不包含导航确认。

内部 `NavigationAlertSession` 以单个枚举记录生命周期：`presented → dismissing → handlingCompletion → nil`。`presented` 仅表示会话已占用；`isConfirmation` 独立表示提示种类。宿主通过 `alertWillDismiss` 从 `presented` 开始关闭，在真实 UIKit completion 中调用 `beginAlertCompletion` 从 `dismissing` 取得一次业务动作处理权，等待动作结束后才调用 `alertDidDismiss` 从 `handlingCompletion` 释放会话。各入口同时核对会话 ID 和 Context 有效性；提前、重复或过期回调被忽略，不能跳过阶段、使状态倒退或提前恢复队列。无按钮选择时也遵循同一顺序。

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

快照包含根 rootDestination／selectedScope／rootDestinations／paths，以及唯一 `presentation`。`NavigationPresentationSnapshot<Scope, Destination, AlertRoute>` 的 `.node` 保存页面节点及其内部层，`.alert` 保存提示 ID 和业务路由；alert 没有下一层。同层同时展示页面和 alert 在类型结构上无法表达。

恢复会创建新的模态节点、层和栈对象；之前保存的模态 context 无法控制新节点，也不能经它重新取得同 ID 新层的栈。根层复用已有栈对象及上下文，清除快照中缺失的根身份和路径。`restore` 在有活动模态／alert、等待关闭、处理 alert 动作、等待导航请求或待确认时返回 false；重复节点 ID、非法页面入口、未实现容器、缺失普通模态 primary 根或无效 path 的快照也被拒绝，且不部分修改原状态。当前格式替代本分支此前未发布的快照格式，没有提供旧格式兼容解码；本次必须新增根 rootDestination 字段；此前缺少入口的编码不能直接解码，App 如需保留旧数据须显式迁移。

快照不含 View、ModelContext、闭包、排队的呈现／导航请求、执行中的业务动作和转场。业务应检查 `snapshot.destinations` 和 `snapshot.presentation?.alerts` 是否仍有效，并自行决定何时保存、版本迁移和数据不可用的呈现方式。框架不会自动写入 UserDefaults。

App 示例的 `CalendarRouter.restorableSnapshot`／`restore` 只接受可以重新查询的日历与历史地址，拒绝年份选择器、下载详情、演示的临时会话、业务提示及仅 DEBUG 存在的测试路由。实际自动跨启动恢复不在当前 App 行为中。

## App 示例与迁移

- `CalendarHomeTabView`：三个 Tab 绑定各自 context。
- `CalendarNavigationHost`／`CalendarNavigationConfiguration`：根宿主统一配置页面映射与呈现策略，保留外部请求、下载错误及数据生命周期协调。
- `CalendarAlert`／`CalendarAlertContent`／`CalendarHomeCoordinator+Alerts`：提示路由、文案和按钮业务动作；设置清理确认及结果提示也走统一宿主。
- `CalendarDestinationView`：统一从路由构建业务页面，读取所在作用域的环境；store identity 改变时重建页面内容，保留导航与呈现宿主。
- `ChineseCalendarRootView`／`calendarStoreEnvironment`：在根导航宿主外统一提供当前容器的 ModelContext 与数据完整度，覆盖根页面及递归模态。
- `CalendarPresentationMenu`：历史列表／资料卡的 sheet 和 full-screen 入口。
- `DynastyFactCard`：同一页面组件在 Tab 或模态里调用当前 context.push。
- `CalendarHomeCoordinator`：年份选择回传、演示状态等业务会话；它们不构成第二套模态状态。
- `CalendarDebugActionsMenu`：Debug 构建中，从设置页的“调试 → 调试操作”打开导航测试或下载调试。
- `CalendarDebugNavigationView`：由 `.debugNavigation(id:)` 数据构建，显示当前作用域、path 长度与页面 ID；同一页可继续 push、sheet、full-screen、pop、dismiss，也可触发跨 Tab 与 Deep Link 确认，以及普通 alert、连续两个 alert、从 alert 按钮导航、alert 期间提交外部导航。调试页复用正式宿主，不自行创建栈或模态。

新增 App 调试类别时，在 `CalendarDebugActionsMenu` 组合对应动作；新增业务测试页面仍先定义 destination，再由 `CalendarDestinationView` 构建。调试工具不进入 NavigationCore。入口、范围及验证见 [Debug 操作记录](../../Docs/Tasks/issue-145-unified-navigation/007-debug-actions.md)。

此前 #148 的根宿主配置迁移将 `navigationPresentations(context:..., destinationContent:)` 改为 `navigationHost(context:configuration:)`，并集中页面、提示和回调配置。各 `NavigationScopeView` 删除 `destinationContent` 参数；`NavigationPresentationNodeView` 只传 node 和 context。递归 `navigationPresentations` 成为框架内部实现，不由业务重复调用。容器选择的 `providesNavigationStack` 在本轮 #152 中进一步移出宿主，见下方迁移说明。

后续简化统一使用 `destination(for:)`，删除模态专用 builder 和 `NavigationConfiguredDestination`。原模态 builder 中的共享数据注入移至 App 根环境，具体调整与验证见 [统一页面构建方法](../../Docs/Tasks/issue-148-navigation-host/002-unified-destination-builder.md)。

前一轮 alert 接入增加 `AlertRoute` 泛型、独立呈现 Context 及强类型业务提示；这些状态 API 保持不变。旧 `rootContext` 已改为 `rootPresentation`，页面直接从呈现环境调用 present/dismiss，与栈环境的 push/pop 分离。

## #152 迁移说明

- 业务 Destination 从 `Hashable` 改为遵循 `NavigationDestination`，默认普通页面使用 Core stack。
- 删除宿主的 `providesNavigationStack(for:)` 和 App 的 `usesPresentationNavigationStack`。旧值 true 表示 **Core 包栈**，新 `providesNavigationContainer` true 表示 **页面组织顶层容器**，不能原值照搬。
- Router 初始化增加整个根层的 `rootDestination`；根 Tab 通过 `rootDestinations` 配置，根内容使用 `NavigationRootView`。多 Tab 模态通过 `present(..., rootDestinations:)` 提供本层各栈根路由。
- 查询所在层入口使用 presentation 的 route/destination，运行时位置仍用层 ID 或本栈 path。快照恢复同 UUID 时继续检查原层／栈对象身份。
- 多栏声明仅保留接入边界，未实现 SplitView。当前 selectedStack 的呈现权限仅适用于互斥 Tab；#146 需要单独设计多个同时可交互栏目。

方案与本轮证据见 [Issue #152 任务记录](../../Docs/Tasks/issue-152-destination-containers/000-plan.md)。
