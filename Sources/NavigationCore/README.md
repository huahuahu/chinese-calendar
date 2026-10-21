# NavigationCore

`NavigationCore` 用强类型数据表示各层导航栈、push path、递归页面模态和业务 alert。根界面可以使用普通单栈，也可以由 App 组合 TabView 或 NavigationSplitView。`present` 接收路由数据，宿主根据路由构建页面或系统提示。状态与路由层不解析 URL、不持有业务模型或查询、不保存 View 或页面回调；页面构建配置由 SwiftUI 宿主持有。

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

`Scope` 必须显式遵循 [NavigationScope](State/NavigationScope.swift)。这是继承 `Hashable` 的标记协议，不新增方法或属性，只表示业务命名的导航栈身份；不要求 `CaseIterable`、`Codable` 或布局信息。需要编码快照时，调用方再为 Scope 提供 `Codable`。从旧的 `Scope: Hashable` 接口迁移时，为已有作用域类型补充协议遵循即可，栈身份和快照编码结构保持不变。

```text
NavigationRouter<Scope, Destination, AlertRoute>
└── 根 NavigationLayer
    ├── route → 根／模态入口 Destination + 纯身份 ID
    ├── selectedStack
    ├── stacks[StackID] → NavigationStackState
    │   └── rootDestination / path
    └── presentedContent?（二选一）
        ├── page → id / destination / style / 下一 NavigationLayer
        │                                    └── 同样的栈与 presentedContent
        └── alert → id / 业务提示路由（没有栈，也没有下一层）
```

导航层（`NavigationLayer`）表示 App 根界面或一次 sheet／fullScreen 打开的整个界面范围。每层包含独立栈集合和一个可选的直接呈现内容，页面模态与业务 alert 共用 `NavigationPresentation` 状态。`sheet`／`fullScreen` 是页面节点的只读样式查询。一个层可以只有一个栈，也可以包含多个 Tab 的栈；alert 位于呈现链末端，不能在它上面再叠一个系统 alert。

每个 `NavigationStackState` 是该栈根身份与 path 的唯一运行时来源，不依赖 Router、`NavigationLayer` 或模态生命周期。每个已声明栈必须具有非可选 `rootDestination`，`path` 使用非可选数组，空数组表示停留在根页面。层的 `roots`／`paths` 是栈对象的值投影，供快照与兼容 API 使用。整批替换路径和同种容器归属的根快照恢复会更新仍存在的栈对象；删除栈或改变根层容器归属会使旧 Context 失效。获取 Context 不创建栈；未声明栈返回无效 Context，随后注册同 ID 栈也不会使它复活。快照省略空 path，缺失条目与显式空数组统一为空，不再记录路径是否曾被写入。

环境上下文按职责分为两种：

- `NavigationPresentationContext<Scope, Destination, AlertRoute>`：负责当前层的 `present`、`dismiss`、离开确认及多栈容器的 `selectedStack`，没有 path／push／pop。层级入口由呈现宿主注入；栈宿主再注入带发起栈身份的入口，所有入口共享同一层状态。
- `NavigationContext<Scope, Destination>`：每栈一个实例，弱引用独立栈状态，通过 `NavigationStackAccess` 的 `isActive`／`canMutate` 判断约束访问；实现不引用 Router 或 `NavigationLayer`。负责本栈的身份、有效性、根页面替换及 path／setPath／push／pop，不提供 `present`／`dismiss`／`isPresented`。页面按需分别读取两种环境。

`NavigationStackAccess` 只描述栈是否有效、是否允许修改，不解释阻止操作的原因。Router 作为组合方，用弱捕获的闭包实时检查层与栈的对象身份、待确认请求和关闭事务。这样上下文既不会延长 Router 或已关闭层的生命周期，也不必理解 presentation；栈状态与访问约束是内部类型，页面继续通过现有公开 API 取得上下文。

`NavigationStackID<Scope>` 用 `.primary` 表示默认栈，用 `.scope(scope)` 表示业务命名的栈；根层与模态层遵循同一规则，不要求根层使用 TabView。同名栈在不同 `NavigationLayer` 中互相隔离。根 Router 的 `selectedScope`、`paths` 和 `rootDestinations` 是面向命名栈的便利投影；通用访问使用 `rootPresentation.selectedStack` 和该 Context 的 `context(for:)`。

Router 和快照的 `selectedScope` 都是 `Scope?`：选中 `.primary` 时返回 `nil`，选中 `.scope(scope)` 时返回对应值。Router 写入非 `nil` scope 保留原有直接切换命名栈的语义，写入 `nil` 不改变选择；切换到默认栈需显式设置 `rootPresentation.selectedStack = .primary`，并遵守该 Context 的事务检查。调用方需要适配可选返回值，TabView 的绑定应使用完整的 `selectedStack`，不要用默认 Tab 填补 `nil`。快照编码格式保持不变，完整选择仍存于 `layer.selectedStack`。

| 上下文 | 栈导航 | 模态呈现 |
| --- | --- | --- |
| `router.rootPresentation.context(for: .primary)` | 根层默认栈的 path／push／pop | 不提供 |
| `router.context(for: tab)` | 指定根 Tab 的 path／push／pop | 不提供 |
| `router.context(for: node)` | 模态 `.primary` 栈的 path／push／pop | 不提供 |
| `layer.context(for: .scope(tab))` | 当前层指定 Tab 的 path／push／pop | 不提供 |
| `router.rootPresentation` | 不提供 | 根层 present；自身 dismiss 返回 false |
| `router.presentationContext(for: node)` | 不提供 | 当前模态层 present；dismiss 关闭当前模态及其后代 |
| `presentation.scoped(to: stackID)` | 不提供 | 共享原层呈现状态，present 额外检查发起栈是否选中 |

`dismiss()` 只存在于呈现上下文，关闭当前所在的模态及其后代；根层的呈现上下文返回 `false`，不会关闭它展示的模态。栈内返回由 navigation 的 `pop()` 负责。App 的调用规则见[导航规范 NAV-03](../../Docs/Conventions/Navigation.md#nav-03--发起作用域与生命周期)。

`navigation.setRootDestination`／`setPath(_:)`／`push`／`pop` 和 `presentation.present`／`dismiss` 返回 Bool 表示是否接受操作。`setPath` 检查 Context 有效性和事务访问约束，不检查 Destination 的位置权限；App 需要同步修改 selection 时，只有返回 true 才更新外部状态。系统 NavigationStack 继续通过 path Binding 读写同一份路径。已关闭节点的上下文失效，不能操控随后恢复的同 ID 新节点。`NavigationScopeView(context:presentation:...)` 从显式传入的呈现入口取得 `scoped(to:)` 入口并注入后代，保留发起栈身份，防止后台 Tab 的旧回调弹窗。页面直接使用呈现环境，无需把 navigation 传入 present。外部 SplitView 等同时可见的栏目，可用 `restrictsPresentationToSelectedStack: false` 注入不绑定发起栈的本层呈现入口；此选项不影响该栏目自己的 push path。

同层已有页面模态时，新的 present 被拒绝，应通过该模态自己的环境继续呈现。当前层有 alert 或正在处理其按钮动作时，后续呈现按顺序排队；返回 true 表示已接受，可能还未显示。页面正在关闭时拒绝新的页面请求；业务 alert 可以排队等关闭完成，所属层失效则一起丢弃。层级入口不绑定某个栈，适用于 TabView 附件等控件。离开确认、alert 和根关闭事务期间，局部 push/pop 暂停；栈上下文只通过窄接口获得是否允许修改，不理解呈现状态。

需要从父层明确关闭其子模态时，使用 `dismissPresented(id:)`；旧 ID 不会关闭后来展示的新节点。系统下滑关闭也由宿主写回同一入口。

根 Router 的 `push(_:on:)` 用于明确切换 Tab 后 push；保留的 `presentSheet`／`presentFullScreen` 在整棵树最前节点继续嵌套。普通页面优先使用局部 context，不让全局操作猜测发起作用域。

## Destination 与入口容器

`Destination` 遵循 [NavigationDestination](State/NavigationDestination.swift)，只声明 `providesNavigationContainer`。所有层使用同一种 `NavigationLayer` 和 `NavigationLayerContent`，在以下两种承载方式中选择：

- `true`：Destination 对应的 View 组织 TabView／NavigationSplitView 等容器，Core 直接构建该 View。页面通过当前层上下文接入各栈，不捕获全局根上下文。
- `false`（默认）：Core 为本层提供 `.primary` NavigationStack，以 Destination 初始化栈根。该方式同样适用于 App 最底层和任意模态层。

两栏、三栏由 App 组合原生 NavigationSplitView 与最后一栏的 Core 详情栈，不是 SDK 提供的容器种类。接法见下文“App 原生分栏组合”。

Router 的 canonical 初始化器与 `present` 使用同形参数：入口 Destination、`initialStack`、以 `NavigationStackID` 为 key 的 `rootDestinations` 和 `paths`。普通单栈可以省略后三项；页面自带容器时，调用方必须为初始选中栈和所有带路径栈声明根。非法 Router 初始化触发前置条件失败，非法 `present` 或快照恢复返回 false 并保持原状态。需要随后增加命名栈时，先用 Router 的 `setRootDestination` 或 `.setRoot` 请求明确声明根，再获取 Context；push、path 赋值及切换选中栈不会隐式创建栈。

页面不声明允许出现的位置，不再提供入口白名单或尚未实现的 Core 多栏声明。push、path 赋值、栈根替换和恢复不会按页面身份拒绝；普通 push 继续在当前栈直接构建页面，不自动再创建一个 `NavigationLayer`。容器入口的导航结构由它自己的 View 和当前层状态协作提供。App 原生分栏的栏目联动、宽窄布局边界及实际验收见 [#146 任务记录](../../Docs/Tasks/issue-146-navigation-containers/000-plan.md)。

层入口与内部栈页面有不同职责。主 Tab 容器在根层或模态层作为入口时，取得该层独立的栈集合；在某个栈内部再次嵌套同一个 Tab 容器，会重复绑定正在展示它的栈，形成结构循环。移除数据入口白名单不代表这类循环布局可用；业务 View 仍须保证同一层同一栈只有一个宿主。此处不增加 push 容器的独立栈命名空间。

`NavigationLayerRoute` 为 `.root(destination:)` 或 `.presentation(id:destination:)`，由层与其呈现 Context 共享一份可观察记录。`presentation.route` / `presentation.destination` 均非可选，Context 失效或层释放后仍能读取最后的入口；是否允许操作和渲染由 `isActive` 及现有事务检查决定。记录不持有 Router、Layer 或栈，Context 仍弱引用它们。根快照恢复会更新已有根及 scoped Context 的路由；恢复出的同 ID 模态使用新记录，不改变旧 Context 的信息或有效性。`NavigationLayerContent` 只在 Context 有效时构建页面。节点的 id/destination 也投影同一份层记录；`route.id` 才是缓存、关闭和查找使用的纯身份。push、切 Tab 不改变层入口；同一 destination 再次打开会生成新 UUID。不要把入口 destination 与本栈的 `rootDestination`、path 或当前详情混淆。设计与验证见[路由读取与有效性记录](../../Docs/Tasks/issue-145-unified-navigation/016-readable-context-route.md)。

| 要判断的事情 | 依据 |
| --- | --- |
| 是否属于 App 根层 | `presentation.id == .root` |
| 是否位于当前栈根部 | `navigation.path.isEmpty` |
| 页面承载需求 | Destination 的容器声明 |
| 本层最初打开什么页面 | `presentation.destination` |

## 根宿主配置与完整示例

根 `NavigationRootView` 根据入口路由构建内容，外部调用一次 `navigationHost(context:configuration:)`。`NavigationHostConfiguration` 只集中定义页面、业务 alert 和离开确认；容器声明已经移入 Destination。每个真实 NavigationStack 由自己的 `NavigationScopeView` 注册 destination。

`NavigationScopeView` 在栈和每个 push 目标页面上显式注入同一个导航 Context 与对应的呈现 Context，保证 App SplitView 的紧凑布局也能取得正确作用域。业务页面只读取环境，不重复注册路径或自行创建 Context。

### 普通单栈根入口与 Tab 模态

根层使用普通 NavigationStack，随后打开的模态可以使用 TabView。每个导航层独立选择自己的容器结构；根层的结构不会限制后续模态。

```text
根层：.home → .primary 栈
└── sheet / full-screen：.tabs → TabView
    ├── 首页 Tab：.scope(.home) 栈
    └── 历史 Tab：.scope(.history) 栈
        └── 还可继续呈现普通单栈模态或另一个 Tab 模态
```

下面是这个组合的完整示例。`AppTab` 为导航树中可能出现的 Tab 命名，本例仅在 Tab 模态中使用；根 Router 以 `.home` 初始化，默认选择 `.primary`。只有 `.tabs` 声明 `providesNavigationContainer == true`，由 `DemoTabs` 构建 TabView；其他路由由 Core 提供单栈。

`DemoTabs` 从环境取得当前模态层的呈现 Context，绑定该层的 `selectedStack` 并取得各 Tab 栈。根 View 只安装一次 `navigationHost`，Tab 模态复用同一配置和 Core 为它创建的呈现宿主。

```swift
import NavigationCore
import SwiftUI

nonisolated enum AppTab: String, Codable, NavigationScope { case home, history }
nonisolated enum AppRoute: Codable, NavigationDestination {
    case home, history, detail(String), tabs

    var providesNavigationContainer: Bool { self == .tabs }
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
        case .tabs: DemoTabs()
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
            firstButton: NavigationAlertButton("知道了", action: .acknowledge)
        )
    }
}

struct DemoRoot: View {
    @State private var router = NavigationRouter<AppTab, AppRoute, AppAlert>(
        rootDestination: .home
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
            Button("返回上一页") { navigation.pop() }
                .disabled(navigation.path.isEmpty)
            Button("弹窗") { presentation.present(.sheet(.detail("弹窗"))) }
            Button("全屏") { presentation.present(.fullScreen(.detail("全屏"))) }
            Button("多 Tab 弹窗") {
                presentation.present(.tabs, initialStack: .scope(.home), rootDestinations: [
                    .scope(.home): .home, .scope(.history): .history
                ])
            }
            Button("多 Tab 全屏") {
                presentation.present(.tabs, style: .fullScreen, initialStack: .scope(.history), rootDestinations: [
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

点击根页面的“多 Tab 弹窗”或“多 Tab 全屏”，新模态才构建 `DemoTabs`。每个 Tab 使用该模态层的独立 NavigationStack；在其中切换 Tab、push 或继续打开子模态，都不会改变底下根层的 `.primary` 选择和路径。关闭 Tab 模态后回到根栈原来的页面。

`router.selectedScope` 与 `router.snapshot.selectedScope` 只投影**根层**的选择。本例中即使 Tab 模态选中了历史，它们仍为 `nil`；模态选择应读取该模态的 `presentation.selectedStack`，不能从根 Router 取代它。

持有 Router 的协调器可分别取得根栈和模态层。例如，下面在普通根栈已有 push 页面时打开 Tab 模态：

```swift
let router = NavigationRouter<AppTab, AppRoute, AppAlert>(rootDestination: .home)
let rootNavigation = router.rootPresentation.context(for: .primary)
rootNavigation.push(.detail("根详情"))
router.rootPresentation.present(.tabs, initialStack: .scope(.home), rootDestinations: [
    .scope(.home): .home, .scope(.history): .history
])

if let node = router.presentedNode {
    let modal = router.presentationContext(for: node)
    modal.selectedStack = .scope(.history)
    modal.context(for: .scope(.history)).push(.detail("模态详情"))

    assert(modal.selectedStack == .scope(.history))
    assert(rootNavigation.path == [.detail("根详情")])
    assert(router.rootPresentation.selectedStack == .primary)
    assert(router.selectedScope == nil)
    assert(router.snapshot.selectedScope == nil)
}
```

只有整棵导航树都不需要命名栈时，才适合用 `Never` 作为 Scope。根层不用 TabView，并不意味着 Scope 应为 `Never`。

### 根层也使用 TabView 的变体

沿用上面的 `AppTab`、`AppRoute`、`DemoConfiguration` 和页面，只需改变根层初始化：

```swift
struct DemoTabRoot: View {
    @State private var router = NavigationRouter<AppTab, AppRoute, AppAlert>(
        rootDestination: .tabs, initialStack: .scope(.home),
        rootDestinations: [.scope(.home): .home, .scope(.history): .history]
    )

    var body: some View {
        NavigationRootView(context: router.rootPresentation)
            .navigationHost(context: router.rootPresentation, configuration: DemoConfiguration())
    }
}
```

此时根层与 Tab 模态复用 `DemoTabs`，各自从所在层取得选择、栈根和路径。两种根入口共用相同的宿主与模态机制。

`rootDestinations` 保存各栈的根页面身份，`setRootDestination` 接收非可选 Destination，清空相应 path，但不改变层入口；替换后的根状态可以保存并恢复。正式页面采用 `NavigationScopeView(stack:presentation:)`，从状态读取根路由，直接调用共享页面构建方法。带 `root` 闭包的初始化器保留给独立 Preview／测试覆盖显示内容，仍要求栈已声明根，覆盖内容不会改变快照。`NavigationContext.rootDestination` 仍返回可选值，用 nil 表示 Context 未声明或已失效；有效栈的根本身不可空。

## App 原生分栏组合

App 自行声明两栏或三栏 `NavigationSplitView`，管理分类与对象的业务联动、`columnVisibility`、`preferredCompactColumn` 及系统写回。整个容器可以由 `.debugSplit(layout:)` 这样的 Destination 构建；最后一栏的空态和详情使用独立根 Destination。前面的列表栏没有独立 push 栈，最后一栏通过 `NavigationScopeView(stack:presentation:)` 提供唯一的 detail `NavigationStack`，根页和 push 页面均由同一个 `navigationHost` 配置构建。

| 状态或动作 | Owner 与接入方式 |
| --- | --- |
| 分类与选择策略 | App；明确切换分类时保留还是清空详情 |
| 当前对象及空详情 | App 定义根 Destination，例如 `.debugSplitDetail(item:level: 0)`／`.debugSplitEmpty`；selection 从详情根投影，根不计入 path |
| 详情 push、pop、系统返回 | SDK 的一个 `NavigationContext` 与 path；根页及 push 后代共享它 |
| 前栏发起详情操作 | App 显式传入详情 Context 或业务动作，不依赖前栏环境猜测目标 |
| 宽窄布局与显示哪一栏 | App 持有原生布局 Binding，并接收系统写回；不映射为 `selectedStack` |
| 模态、alert、离开确认 | 既有 `NavigationPresentationContext` 与同层唯一 presentation host |

不同对象的选择动作调用 `detailNavigation.setRootDestination(.debugSplitDetail(item: item, level: 0))`，同时换根并清空旧 path。清空选择使用 `.debugSplitEmpty`，无需 nil 根或伪造对象。重复选择同一对象不换根，保留 path；若该动作还要更新 App 布局，可先用 `setPath(currentPath)` 检查是否接受操作。切换分类时由业务动作明确保留详情及其 path，或换为空态根。仅在栈操作返回 true 后更新分类和布局，返回 false 时保持界面。App 不另存当前对象，也不通过多个 `onChange` 相互同步选择与路径。

容器作为 sheet／full-screen 入口时声明 `providesNavigationContainer == true`，宿主跳过外层包栈，容器只在最后一栏创建详情栈。继承当前树的 `navigationHost` 配置和本层呈现 Context，不再挂第二个根呈现宿主；父层、模态层与其他 Tab 的详情 Context 彼此隔离。前栏没有独立栈，因此不把它们注册为多个互斥 Tab，也不引入通用容器 Context、列类型或多栏快照。

外部请求沿用既有确认、业务 alert 排队和真实 dismiss 完成流程。等待确认、仅收到批准或等待关闭期间不提前修改根路由及外部业务选择；取消保持原选择、path 与呈现状态，批准的请求实际应用时再同步业务选择。SDK 快照保存详情根 Destination 与 path，因此可以恢复路由所表达的对象；分类、保留策略及布局 Binding 仍由 App 管理，不承诺仅靠 SDK 快照恢复完整分栏界面。App 的 DEBUG 路由继续禁止持久恢复，测试中直接恢复 Core 快照只验证结构能力。

本轮通过固定小数据的 DEBUG 普通／两栏／三栏入口验证组合，正式历史 Tab 保持既有布局。原生折叠、深 path 下的系统返回和布局写回需要独立的 Simulator 交互证据；上述 API 接法不等于这些行为已通过验收。完整方案见 [Issue #146 任务记录](../../Docs/Tasks/issue-146-navigation-containers/000-plan.md)，项目调用规则见[导航规范 NAV-07](../../Docs/Conventions/Navigation.md#nav-07--app-原生分栏与详情栈组合)。

## 配置与业务上下文

- `destination(for:)` 统一构建根入口、Tab 根、push、模态初始页面和模态内 push 页面。栈与模态入口直接调用 `page(for:)` 方法，不按是否模态分流，也没有转调 builder 的包装 View。
- 配置实现用值类型保存 coordinator 等依赖，并用方法构建 View。App 共享的数据环境在根呈现宿主外统一提供；模态入口只提供本层 presentation，栈宿主提供 navigation 与发起栈信息。页面继承这些环境；年份选择器按 session ID 获取发起页的 selection、ModelContext 和回调。
- 环境默认配置为 nil，栈或模态宿主缺少配置时会报接入错误。类型擦除只发生在 `page(for:)` 方法内，Router 与两个 Context 均不持有配置或 View。Swift 6 使用 MainActor 隔离的路由时，配置显式声明 `: @MainActor NavigationHostConfiguration`。
- App 的 `.mainTabs` 和 `.downloadPreview(sessionID:)` 声明自带容器；日历、历史、设置及演示两个 Tab 均保存明确根路由。页面组织 TabView，各栈与呈现仍由 Core 承载。
- `confirmationContent(for:)` 和 `alertContent(for:)` 默认返回 nil。使用业务 alert 必须提供文案；省略确认文案时业务须自行处理 `context.confirmation`，它不会隐式批准请求。
- `handleAlertAction` 在系统提示实际关闭后执行；框架等待异步动作完成，再推进队列或外部导航。`presentationDidDismiss` 在任意层子模态实际关闭、框架处理状态后调用，只用于释放业务会话，不重复执行全局导航。
- `NavigationPresentationNodeView(node:context:)` 是递归节点宿主。单独组合时也须位于同一配置环境内；一般不需要手动创建它。
- 独立 Preview 也配置自己的根宿主。App 的 `SampleDataPreviewHost` 已统一提供配置，`SampleNavigationPreview` 只声明栈和根内容；`FullStoreDownloadPreviewHost` 从自己的根配置打开多 Tab 模态。

## Deep link 与离开确认

URL、通知或启动参数由 App 解析为业务地址，再提交请求：

```swift
router.submit(
    .replacePath([.detail("链接目标")], on: .scope(.history)),
    confirmIfPresented: true
)
```

请求以 `NavigationStackID` 指定根层目标：Core 单栈使用 `.primary`，Tab 等命名栈使用 `.scope(...)`；切换栈对应 `.selectStack(...)`。旧 Scope 便利工厂继续可用。普通根层同样经过确认、关闭完成和延迟请求协调。

没有模态时立即应用并返回 `.applied`。有模态时返回 `.awaitingConfirmation`，保留全部 path 和模态，`pendingConfirmation` 保存请求及唯一 ID。**必须为宿主提供 `confirmationContent` 或自行处理 pendingConfirmation**；Core 不提供默认业务文案。

页面若需要业务自己的离开决策，可不提供默认 `confirmationContent`，直接观察呈现环境的 `confirmation`，完成保存或确认后在呈现 context 调用 `confirmNavigation(id:)`／`cancelNavigation(id:)`。只有当前应处理请求的最前方的 `NavigationLayer` 会读到确认数据，同层多个 Tab 共享该数据；由容器协调一次提示，避免每个 Tab 重复处理。根可通过 `pendingConfirmation` 管理整笔请求。不要同时启用默认提示和页面自己的提示。

默认宿主只在最上层模态展示提示。取消保留页面；确认调用 `confirmNavigation(id:)`，先关闭根模态树，返回转场前的页面结构，直到根宿主报告 `onDismiss` 才应用请求。子模态的关闭通知不能提前完成全局跳转。

相同待确认请求去重；不同请求替换待确认数据并生成新 ID，系统关闭旧提示再展示新提示，旧提示不能批准新目标。已批准关闭期间新到达的链接仍需单独确认：先完成原请求，转场完成后在根提示新请求。模态自行关闭也不会自动批准待确认请求。

提示宿主使用 `UIAlertController`，将按钮动作与真正的关闭完成分开。新确认 ID 会先关闭旧提示再展示新提示，旧 ID 不能批准新请求。`dismiss(animated:completion:)` 的 completion 在 `viewDidDisappear` 之后调用，框架以此推进流程，不使用固定延时。旧的 SwiftUI `alert(item:content:)` 确认宿主已移除；业务页面也不直接挂另一份 alert。依据见 [Apple 的关闭完成说明](https://developer.apple.com/documentation/uikit/uiviewcontroller/dismiss(animated:completion:))。

`submit` 默认 `confirmIfPresented: false`，供业务已经批准的导航使用；有模态时返回 `.deferredUntilPresentationDismisses`，关闭期间以最新的已批准请求为准。自定义宿主必须在真实根关闭完成后调用 `presentationDidDismiss(isRoot: true)`；使用内置宿主则不必手动通知。

## 提示按钮的构造约束

`NavigationAlertContent` 使用必填 `firstButton` 保证至少存在一个普通／危险按钮，其他按钮通过 `additionalButtons` 按顺序提供。集合以 `Action` 为身份：相同 Action 后写覆盖先写的标题和样式，但保留首次出现的位置，不会因为重复配置而触发 `precondition`。构造完成后的按钮集合只读。

取消按钮使用独立的 `NavigationAlertCancelButton` 和单个可选 `cancelButton` 参数。普通按钮的 `Role` 只有 `.standard`、`.destructive`，不能把第二个取消按钮放入普通集合。只有取消按钮的提示使用 `init(title:message:cancelButton:)`；两个初始化入口都不能构造没有按钮的提示。

```swift
enum EditAction: Hashable { case save, delete, cancel }

NavigationAlertContent(
    title: "处理资料", message: "选择操作",
    firstButton: NavigationAlertButton("保存", action: EditAction.save),
    additionalButtons: [
        NavigationAlertButton("删除", action: .delete, role: .destructive),
        NavigationAlertButton("保存修改", action: .save)
    ],
    cancelButton: NavigationAlertCancelButton("取消", action: .cancel)
)
```

普通集合的结果为“保存修改、删除”。取消按钮独立置于宿主按钮列表的首位，不参与普通集合的 Action 覆盖，允许与普通按钮产生相同业务动作。宿主使用同一份展开结果构建显示内容和点击索引映射，保持取消、危险样式及动作回传一致。旧数组调用需迁移为 `firstButton`／`additionalButtons`，原 `.cancel` 按钮需移至 `cancelButton`。

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

Router 内部由一个 `NavigationCoordinationState` 管理请求与延迟关闭意图。`deferredRequest`、`pendingConfirmation`、`requestWaitingForAlert` 是只读投影：已接受 A、等待确认 B 可以并存，取消 B 不撤销 A；alert 后请求将目标与确认策略保存在同一个枚举值中，全部关闭覆盖指定节点集合。转换只管理协调意图，真实模态关闭和 alert 会话仍以 `NavigationLayer` 的生命周期为准，不重复保存。方案与回归范围见[请求协调状态](../../Docs/Tasks/issue-145-unified-navigation/015-coordination-state.md)。

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

根快照保存 `rootDestination` 和 `layer: NavigationLayerSnapshot`。根与每层模态的 layer 都保存相同的 selectedStack／rootDestinations／paths／presentation。`NavigationPresentationSnapshot<Scope, Destination, AlertRoute>` 的 `.node` 保存页面节点及其内部层，`.alert` 保存提示 ID 和业务路由；alert 没有下一层。同层同时展示页面和 alert 在类型结构上无法表达。

恢复会创建新的模态节点、层和栈对象；之前保存的模态 context 无法控制新节点，也不能经它重新取得同 ID 新层的栈。根层在容器归属不变时复用已有栈对象及上下文，清除快照中缺失的根身份和路径；在自带容器与 Core 单栈之间切换时重建栈，旧栈上下文失效。`restore` 在有活动模态／alert、等待关闭、处理 alert 动作、等待导航请求或待确认时返回 false；重复节点 ID、Core 单栈缺少 primary 根或包含非 primary 栈等无效结构也会被拒绝，且不部分修改原状态；栈根允许不同于最初层入口，不检查页面位置权限。根和模态共用同一结构校验。当前 App 未接入跨启动快照持久化；新编码使用 rootDestination + layer，既有旧编码如需保留，宿主须显式迁移。

快照不含 View、ModelContext、闭包、排队的呈现／导航请求、执行中的业务动作和转场，也不含 App 原生分栏的 selection、分类、`columnVisibility` 或 `preferredCompactColumn`。业务应检查 `snapshot.destinations` 和 `snapshot.presentation?.alerts` 是否仍有效，并自行决定何时保存、版本迁移和数据不可用的呈现方式；需要恢复分栏时还须定义 App 状态与详情 path 的一致性。框架不会自动写入 UserDefaults。

App 示例的 `CalendarRouter.restorableSnapshot`／`restore` 只接受可以重新查询的日历与历史地址，拒绝年份选择器、下载详情、演示的临时会话、业务提示及仅 DEBUG 存在的测试路由。实际自动跨启动恢复不在当前 App 行为中。

## App 示例与迁移

- `CalendarHomeTabView`：三个 Tab 绑定当前层 selectedStack 和各自 context，同一页面可在根层或递归模态复用。
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

此前 #148 的根宿主配置迁移将 `navigationPresentations(context:..., destinationContent:)` 改为 `navigationHost(context:configuration:)`，并集中页面、提示和回调配置。各 `NavigationScopeView` 删除 `destinationContent` 参数；`NavigationPresentationNodeView` 只传 node 和 context。递归 `navigationPresentations` 成为框架内部实现，不由业务重复调用。容器选择的 `providesNavigationStack` 在 #152 中进一步移出宿主，见下方迁移说明。

后续简化统一使用 `destination(for:)`，删除模态专用 builder 和 `NavigationConfiguredDestination`。原模态 builder 中的共享数据注入移至 App 根环境，具体调整与验证见 [统一页面构建方法](../../Docs/Tasks/issue-148-navigation-host/002-unified-destination-builder.md)。

前一轮 alert 接入增加 `AlertRoute` 泛型、独立呈现 Context 及强类型业务提示；这些状态 API 保持不变。旧 `rootContext` 已改为 `rootPresentation`，页面直接从呈现环境调用 present/dismiss，与栈环境的 push/pop 分离。

## #152 迁移说明

- 业务 Destination 从 `Hashable` 改为遵循 `NavigationDestination`，默认普通页面使用 Core stack。
- 删除宿主的 `providesNavigationStack(for:)` 和 App 的 `usesPresentationNavigationStack`。旧值 true 表示 **Core 包栈**，新 `providesNavigationContainer` true 表示 **页面组织顶层容器**，不能原值照搬。
- Router 初始化增加整个根层的 `rootDestination`；根 Tab 通过 `rootDestinations` 配置，根内容使用 `NavigationRootView`。多 Tab 模态通过 `present(..., rootDestinations:)` 提供本层各栈根路由。
- 查询所在层入口使用 presentation 的 route/destination，运行时位置仍用层 ID 或本栈 path。快照恢复同 UUID 时继续检查原层／栈对象身份。
- 后续同构层改造移除了入口白名单与 Core 多栏预留声明；外部提供的 SplitView 可接入非排他的层级呈现入口。#146 的 App 原生分栏组合在此基础上管理 selection 与布局，实际交互验证单独记录。

方案与本轮证据见 [Issue #152 任务记录](../../Docs/Tasks/issue-152-destination-containers/000-plan.md)。

## 同构层迁移（2026-10-20）

- 删除 Destination 的 `allowedNavigationEntries`、`navigationContainer` 和对应枚举；仅保留 `providesNavigationContainer`。
- 新代码使用 Router 的 `initialStack` 与 `NavigationStackID` 字典；根层与 `present` 的参数结构一致。基于 Scope 的旧根 Tab 便利入口仍映射同一份层状态。
- 根快照以 `layer` 复用模态层结构；通用读取使用 `snapshot.layer`，旧命名栈投影仅用于根 Tab 适配。
- App `.root` 改名 `.mainTabs`，主 Tab 页面读取当前层环境；通用关闭按钮通过模态状态和本栈 path 决定。

方案及证据见 [同构导航层](../../Docs/Tasks/task-2026-10-20-homogeneous-navigation-layers/000-plan.md)。
