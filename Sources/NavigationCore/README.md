# NavigationCore

`NavigationCore` 管理 SwiftUI 应用的页面导航：在当前页面继续 push、返回上一页、打开 sheet／full-screen、显示业务 alert，以及在收到 Deep Link 时协调确认和关闭。

例如，用户在“历史”Tab 打开资料详情，再弹出一个编辑页。历史 Tab 的浏览位置由一个导航栈保存；编辑页拥有自己的栈，关闭后回到原来的历史详情。其他 Tab 的路径保持独立。这些导航状态由 Core 管理，资料查询、编辑内容和 URL 解析由 App 负责。

本模块是 [Sources/Package.swift](../Package.swift) 中的一个共享 target，不依赖日历业务类型。App 定义页面地址，并告诉宿主如何把地址构建成 SwiftUI View。

## 按需求阅读

第一次接入先读[核心概念](#核心概念)和[最小接入](#最小接入)，再按页面结构选择示例。

| 你要做什么 | 阅读入口 |
| --- | --- |
| 查 push、换根、present、dismiss 应从哪里调用 | [操作入口速查](#操作入口速查) |
| 判断操作已应用、已排队、无操作或被拒绝 | [操作结果与诊断](#操作结果与诊断) |
| 打开 sheet／full-screen | [打开和关闭模态](#打开和关闭模态) |
| 为多个 Tab 保留各自路径 | [每个 Tab 保留独立路径](#每个-tab-保留独立路径) |
| 接入两栏／三栏布局 | [App 原生分栏组合](#app-原生分栏组合) |
| 显示提示并处理按钮动作 | [业务 alert](#业务-alert) |
| 处理外部链接和离开确认 | [Deep Link 与离开确认](#deep-link-与离开确认) |
| 排查操作被拒绝、Context 失效或后台 Tab 弹窗 | [操作约束与生命周期](#操作约束与生命周期) |
| 注入业务依赖、配置页面或编写 Preview | [配置与业务数据放在哪里](#配置与业务数据放在哪里) |
| 了解状态保留范围 | [运行时状态与启动边界](#运行时状态与启动边界) |
| 阅读框架实现或查找 App 示例 | [源码目录](#源码目录)、[在日历 App 中继续阅读](#在日历-app-中继续阅读) |

项目调用约定以[导航规范](../../Docs/Conventions/Navigation.md)为准；已有调用方升级看[迁移说明](MIGRATION.md)。发起方持有业务资源，Core 按本次呈现的真实结束通知发起方。所有权与生命周期设计见 [Issue #165 方案](../../Docs/Tasks/issue-165-presentation-ownership/000-plan.md)，构建、自动测试和实际交互的证据及覆盖边界见[结果记录](../../Docs/Tasks/issue-165-presentation-ownership/001-result.md)。

## 核心概念

先区分“在一个栈里前进”和“打开新的一层界面”：push 只改变当前栈；sheet／full-screen 创建新的导航层。切换 Tab 选择同一层中的另一个栈。

```text
NavigationRouter：管理整棵导航树
└── 根导航层 NavigationLayer
    ├── 首页栈：根页面 + push 路径
    ├── 历史栈：根页面 + push 路径
    └── sheet：新的 NavigationLayer
        ├── 自己的栈：根页面 + push 路径
        └── 可以继续打开子模态或显示 alert
```

| 名称 | 表示什么 | 由谁定义或使用 |
| --- | --- | --- |
| `Destination` | 一个页面的路由数据，例如 `.detail(id: 42)` | App 定义，遵循 `NavigationDestination`；页面配置将它转换成 View |
| 导航栈 | 一个栈底页面 `rootDestination`，以及其上已经 push 的 `path` | Core 保存状态；`NavigationScopeView` 将它接到真实的 `NavigationStack` |
| 导航层 `NavigationLayer` | App 根界面，或一次 sheet／full-screen 打开的整个界面 | Core 管理；一层可以有一个栈或多个 Tab 栈 |
| `NavigationContext` | 对一个栈的操作入口 | 页面从环境读取，调用换根、push、pop |
| `NavigationPresentationContext` | 对所在层的操作入口 | 页面从环境读取，调用 present、dismiss；容器用它选择本层的栈 |
| `NavigationRouter` | 运行时导航树的持有者和外部请求协调者 | App 根 View 或 coordinator 持有，处理 Deep Link 和整树关闭协调 |

栈 ID 使用 `NavigationStackID<Scope>`：`.primary` 是默认栈，`.scope(.history)` 这样的值是 App 命名的栈。`Scope` 遵循 `NavigationScope`，只负责命名，不描述页面或栏数。同名栈在不同导航层中互相隔离。

业务 alert 是某层直接展示的提示，没有自己的栈或下一层。一层的直接呈现内容是页面模态或 alert 中的一种；模态中的页面可以通过它自己的层继续呈现。

## 最小接入

先实现一个普通单栈：首页 → 资料 → 返回。以下示例可以放入已依赖 `NavigationCore` 的 SwiftUI target，将 `DemoRoot` 放入现有 `WindowGroup` 或 Preview。示例使用内联文案便于阅读，接入本 App 时遵循[文案规范](../../Docs/Conventions/Localization.md)。

```swift
import NavigationCore
import SwiftUI

// 本例只用 .primary，暂时没有需要命名的栈。
nonisolated enum AppScope: NavigationScope {}
nonisolated enum AppRoute: NavigationDestination {
    case home
    case detail(id: Int)
}

typealias AppNavigation = NavigationContext<AppScope, AppRoute>
typealias AppPresentation = NavigationPresentationContext<AppScope, AppRoute, NoNavigationAlert>

struct DemoConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = AppScope
    typealias Destination = AppRoute
    typealias AlertRoute = NoNavigationAlert

    @ViewBuilder
    func destination(for route: AppRoute) -> some View {
        switch route {
        case .home: DemoPage(title: "首页")
        case let .detail(id): DemoPage(title: "资料 \(id)")
        }
    }
}

struct DemoRoot: View {
    @State private var router = NavigationRouter<AppScope, AppRoute, NoNavigationAlert>(
        rootDestination: .home
    )

    var body: some View {
        NavigationRootView(context: router.rootPresentation)
            .navigationHost(context: router.rootPresentation, configuration: DemoConfiguration())
    }
}

struct DemoPage: View {
    @Environment(AppNavigation.self) private var navigation
    let title: String

    var body: some View {
        List {
            NavigationLink("查看资料 1", value: AppRoute.detail(id: 1))
            Button("查看资料 2") { navigation.push(.detail(id: 2)) }
            Button("返回上一页") { navigation.pop() }
                .disabled(navigation.path.isEmpty)
        }
        .navigationTitle(title)
    }
}

#Preview { DemoRoot() }
```

这段接入包含三件事：

1. `AppRoute` 描述页面身份，`DemoConfiguration.destination(for:)` 构建页面。暂不使用业务 alert，所以第三个泛型参数采用 `NoNavigationAlert`。
2. `DemoRoot` 持有 Router，并在导航树根部挂一次 `navigationHost`，提供页面配置与呈现宿主。
3. 页面通过环境中的 `AppNavigation` 操作本栈。`NavigationLink(value:)`、`push` 和系统返回读写同一份 path。

普通路由的 `providesNavigationContainer` 默认为 `false`，Core 会创建 `.primary` 栈，并以 `.home` 为栈根。首页及所有 push 后代共享这个栈的 `NavigationContext`。业务页面无需再包 `NavigationStack` 或注册 `navigationDestination`。

点击“查看资料 1”后，栈根仍为 `.home`，path 变为 `[.detail(id: 1)]`；返回后 path 为空。**根页面不计入 path**，所以 `navigation.path.isEmpty` 表示已经在栈底。

## 操作入口速查

页面从环境取得所属栈的 `navigation` 和所属层的 `presentation`；App 根部持有 `router`，协调外部导航。

| 意图 | 入口 | 状态变化或注意点 |
| --- | --- | --- |
| 前进到下一页 | `navigation.push(destination)` | 追加当前栈的 path |
| 返回上一页 | `navigation.pop()` | 移除当前栈的最后一个 path 元素 |
| 切换栈底页面 | `navigation.setRootDestination(destination)` | 换根并清空当前栈 path |
| 打开页面模态 | `presentation.present(.sheet(destination))`／`.fullScreen(destination)` | 创建新的导航层 |
| 显示业务提示 | `presentation.present(.alert(route))` | 使用本层的统一提示宿主 |
| 关闭当前模态 | `presentation.dismiss()` | 关闭所在模态及后代；根层返回 `.noChange(.notPresented)` |
| 从来源取消／关闭自己发起的请求 | `submission.handle?.dismiss()` | 排队时取消；已展示时发起真实关闭，不寻找节点 |
| 切换本层 Tab | `presentation.setSelectedStack(stack)` 或绑定 `selectedStack` | 各栈保留自己的根与 path；方法返回具体结果 |
| 显式取得某个栈 | `presentation.context(for: stackID)` | 栈必须已声明；获取操作不会创建栈 |
| 从外部链接跳转 | `router.submit(request, confirmIfPresented: true)` | 协调提示、离开确认与真实关闭，再应用请求 |

栈修改返回 `NavigationMutationResult`；`present`／`presentAlert` 返回 `NavigationPresentationSubmission`，其 `result` 为既有呈现结果，`handle` 对应本次请求；`dismiss` 返回 `NavigationPresentationResult`，`submit` 返回 `NavigationRequestResult`。**接受请求不等于界面已经显示或关闭。** 需要联动业务状态时，按下面的结果语义处理；具体限制见[操作约束与生命周期](#操作约束与生命周期)。

## 操作结果与诊断

结果使用强类型枚举，调用方无需解析日志或数字错误码。命令保留 `@discardableResult`；只发起导航时可以忽略结果，需要同步业务状态或处理拒绝时则检查结果。

| 操作类型 | 结果 | 调用方判断 |
| --- | --- | --- |
| 同步栈、根或选择修改 | `NavigationMutationResult`：`.applied`、`.noChange(reason)`、`.rejected(reason)` | `isApplied` 仅在 `.applied` 时为 true |
| 页面／alert 呈现 | `NavigationPresentationSubmission`：`result` 与可选 `handle` | `submission.result.isAccepted` 在 `.applied` 或 `.queued` 时为 true；接受时提供 handle |
| 当前模态或 handle 的关闭命令 | `NavigationPresentationResult`：`.applied`、`.queued`、`.noChange(reason)`、`.rejected(reason)` | `isAccepted` 判断命令是否接受，不表示动画完成 |
| 根请求提交 | `NavigationRequestResult`：应用、等待确认、两种延迟、`.noChange(reason)`、`.rejected(reason)` | 用 `switch` 区分处理阶段，见 [Deep Link 与离开确认](#deep-link-与离开确认) |

`.applied` 表示导航数据已应用，SwiftUI 更新和呈现动画可能尚未结束。`.queued` 表示已排队，所属层失效后可能丢弃，不保证最终执行。同步结果不表示最终界面完成。已接受请求的 `onFinish` 在本次请求真正结束后通知来源；未显示就取消时也会结束，业务 alert 还需等待按钮异步动作完成。拒绝不调用 `onFinish`，由来源同步回滚。

`.noChange` 表示正常无操作，例如栈底 `pop()` 返回 `.alreadyAtRoot`、根层 `dismiss()` 返回 `.notPresented`、已经结束的 handle 再次关闭返回 `.notPresented`。它与 `.rejected` 分开；`isApplied`／`isAccepted` 为 false 并不自动表示发生错误。重复写入相同的合法 path 或选中栈仍为 `.applied`，用于通过访问约束后同步业务布局。

需要联动业务状态时，先应用导航数据，再更新业务值。例如：

```swift
guard navigation.setRootDestination(newRoot).isApplied else { return }
selectedCategory = newCategory
```

`path`、`selectedStack` 等可写属性仍可用于 Binding，其 setter 转调对应命令并忽略返回值。业务代码需要获知结果时，直接调用 `setPath`、`setSelectedStack` 等方法。

Core 使用共享日志模块的 `navigation` category，在命令决策处记录一次操作、结果和原因，转发入口不重复记录。非法栈或容器配置记录为 `notice`；正常应用、排队、无操作和生命周期／事务阻挡记录为 `debug`。查询 getter 与内部幂等回调不产生日志；动态层和栈身份使用 private 隐私标记，不输出业务 Destination。日志用于排查，业务分支依赖结果枚举。方案及验证入口见[导航操作结果与诊断](../../Docs/Tasks/task-2026-10-22-navigation-results/000-plan.md)。

## 单次请求身份与公开边界

App 自己声明的 `NavigationStackID`、Destination、栈根、path 和选中栈是公开 UI 契约。呈现节点、队列、关闭事务、确认对象及其内部 ID 只供 Core 协作，不作为业务清理或结果回传的凭据。

模态、确认和业务提示在 Core 内部继续使用不同的强类型身份，保留 #166 的领域隔离。一次呈现另有内部 lifetime 与 View 侧 render record 直接配对；业务持有的 `NavigationPresentationHandle` 只能结束这次请求，不公开 ID、状态或节点查找。

年份 session、下载演示和分栏布局由来源 owner 直接持有。提示路由携带结构化值，配置构建本地化文案；不再汇总会话 ID 或以内部导航身份查业务对象。迁移步骤见 [MIGRATION](MIGRATION.md#迁移到发起方所有权与单次结束通知)。

## 常见组合

下面的模态与 Tab 示例在最小示例上逐步扩展；业务 alert 是一个可选扩展。分栏部分链接到本仓库的完整实现。

### 打开和关闭模态

在 `DemoPage` 增加对 `AppPresentation` 的环境读取，并把按钮放入页面内容：

```swift
@Environment(AppPresentation.self) private var presentation

// 放入页面的 List 或其他 ViewBuilder 中。
Button("弹出资料") { presentation.present(.sheet(.detail(id: 3))) }
Button("全屏资料") { presentation.present(.fullScreen(.detail(id: 4))) }
if presentation.isPresented {
    Button("关闭") { presentation.dismiss() }
}
```

未显式传入 `configuration` 时，新模态继承当前宿主的 `DemoConfiguration`，获得自己的 `.primary` 栈和 `NavigationPresentationContext`。模态里的 push 不改变下面页面的路径；继续 present 会从当前模态创建下一层。

`pop()` 返回本栈上一页，`dismiss()` 关闭当前所在模态及其后代。根层没有自身模态，调用 `router.rootPresentation.dismiss()` 返回 `.noChange(.notPresented)`。发起方需要关闭自己打开的请求时，保存提交回执中的 handle 并调用 `handle.dismiss()`。它也能取消尚未展示的请求。

呈现返回 `NavigationPresentationSubmission`，关闭命令返回 `NavigationPresentationResult`。当前 alert 或业务动作尚未结束时，请求可能排队；`.applied` 也只表示数据已修改。需要回收本次资源时，在提交处绑定 `onFinish`：

```swift
let submission = presentation.present(.sheet(.detail(id: 3)), onFinish: {
    // 来源清理本次流程的资源；应核对资源身份，避免旧通知清空新流程。
})
if submission.result.isAccepted {
    // 来源保存 submission.handle，用于取消排队或关闭已展示的本次请求。
} else {
    // 未接受不触发 onFinish；来源在这里同步回滚刚准备的资源。
}
```

已接受请求恰好结束一次。排队或系统尚未接手时取消可直接结束；已接手展示则等真实关闭完成。handle 不保活 Router，释放 handle 不会取消请求；`onDisappear`、子页覆盖、Tab 切换和手势取消不触发业务结束。完整合同见 [Issue #165](../../Docs/Tasks/issue-165-presentation-ownership/000-plan.md#每次请求的结束合同)，验证证据见[结果记录](../../Docs/Tasks/issue-165-presentation-ownership/001-result.md)。

### 每个 Tab 保留独立路径

让 App 组织 `TabView`，每个 Tab 内放一个 `NavigationScopeView`。先替换示例中的 Scope 和路由定义，为两个栈命名，并增加一个容器入口 `.tabs`：

```swift
nonisolated enum AppScope: NavigationScope { case home, history }
nonisolated enum AppRoute: NavigationDestination {
    case home, history, detail(id: Int), tabs

    var providesNavigationContainer: Bool { self == .tabs }
}
```

`providesNavigationContainer == true` 表示页面自己组织导航容器，Core 直接构建它；`false` 表示 Core 提供默认单栈。这条规则同时适用于根界面和模态入口。

然后在 `DemoConfiguration.destination(for:)` 的 switch 中加入 `case .tabs: DemoTabs()` 和 `case .history: DemoPage(title: "历史")` 两个分支，并添加容器 View：

```swift
struct DemoTabs: View {
    @Environment(AppPresentation.self) private var presentation

    var body: some View {
        @Bindable var presentation = presentation
        TabView(selection: $presentation.selectedStack) {
            Tab("首页", systemImage: "house", value: NavigationStackID<AppScope>.scope(.home)) {
                NavigationScopeView(stack: .scope(.home), presentation: presentation)
            }
            Tab("历史", systemImage: "clock", value: NavigationStackID<AppScope>.scope(.history)) {
                NavigationScopeView(stack: .scope(.history), presentation: presentation)
            }
        }
    }
}
```

最后，在 `DemoRoot` 中替换 Router 初始化，声明入口、初始选中栈及各栈根页面：

```swift
@State private var router = NavigationRouter<AppScope, AppRoute, NoNavigationAlert>(
    rootDestination: .tabs,
    initialStack: .scope(.home),
    rootDestinations: [.scope(.home): .home, .scope(.history): .history]
)
```

`DemoTabs` 绑定的是**所在层**的 `selectedStack`。两个 Tab 共享这一层的模态呈现状态，保留各自的根页面和 path。每个栈自行注册 destination，Tab 内无需再挂 `navigationHost`。

同一个 Tab 容器也能在模态中打开。在页面按钮动作中调用：

```swift
presentation.present(
    .tabs,
    style: .sheet,
    initialStack: .scope(.history),
    rootDestinations: [.scope(.home): .home, .scope(.history): .history]
)
```

将 `style` 改为 `.fullScreen` 即使用全屏。新层拥有自己的选择和两个栈，`DemoTabs` 从环境取得新层的 `NavigationPresentationContext`，不捕获根层 Context。根界面和模态因此可以自由选择普通单栈或 Tab 容器。

需要先构造呈现请求数据时，也能通过 `.sheet(.tabs, initialStack:rootDestinations:paths:)` 或 `.fullScreen` 传入同样的栈配置，再交给 `presentation.present(request)`。页面始终使用所属环境的 `NavigationPresentationContext`，返回提交回执；原 Router 的节点相关便利入口不再公开。下载错误等全局事件可使用 `router.presentAlert(route)`，由库内部选择前台层，也返回提交回执。

### 分清层入口、栈根和当前页面

以上例为例：根界面打开 `.tabs`，选择“历史”Tab，再 push `.detail(id: 42)`。

| 要查询的内容 | 值 | 对应 API |
| --- | --- | --- |
| 整个根界面的入口 | `.tabs` | Router 初始化参数 `rootDestination`；入口由业务配置收到的 Destination 描述 |
| 历史栈的栈底页面 | `.history` | `historyNavigation.rootDestination`，其中 `historyNavigation = presentation.context(for: .scope(.history))` |
| 历史栈继续 push 的页面 | `[.detail(id: 42)]` | `historyNavigation.path` |
| 根层当前选中栈的页面 | `.detail(id: 42)` | 取得 `presentation.context(for: presentation.selectedStack)`，读取其 `path.last ?? rootDestination` |
| 初始化时各栈的根页面 | 首页为 `.home`、历史为 `.history` | `rootDestinations` 参数，以完整的 `NavigationStackID` 为 key |

若这个 Tab 容器位于 sheet 中，配置仍收到 `.tabs`，各页面使用该模态层的栈 Context。层入口和内部路由记录不提供额外公开查询；容器通过当前层 `selectedStack` 和对应栈 Context 读取显示状态。

换根使用 `navigation.setRootDestination(newRoot)`：它同时清空本栈 path，不改变层入口或其他栈。每个有效栈必须有根，空详情也用一个明确的 Destination 表示。`rootDestination` 的可选返回值用于表达 Context 未声明或已失效。

### App 原生分栏组合

两栏或三栏由 App 声明原生 `NavigationSplitView`，只有最后一栏使用 Core 的详情栈：

```text
App 的 NavigationSplitView
├── sidebar：分类列表，App 管理分类选择
├── content：对象列表，选择动作更新详情根
└── detail：NavigationScopeView
    ├── 根页面：选中对象的详情或空态 Destination
    └── path：继续 push 的页面
```

两栏时省去中间 content 栏。前栏不维护独立的 push 栈，整个 SplitView 外也不再包一个 NavigationStack。容器入口的 `providesNavigationContainer` 返回 `true`；只有一个详情栈时可使用 `.primary`，并在入口的 `rootDestinations` 中为它声明空态或详情根。

| 状态或动作 | 归属与接法 |
| --- | --- |
| 分类、筛选及切换分类时的保留策略 | App 管理 |
| 当前对象与空详情 | App 定义详情根路由；对象 selection 从该根投影，不另存一份相互同步的状态 |
| 详情 push、pop、系统返回 | 一个 `NavigationContext` 与 path；根页和 push 后代共享它 |
| 前栏操作详情 | App 显式传入详情 Context 或业务动作 |
| `columnVisibility`、`preferredCompactColumn` | App 持有 Binding，接受系统写回；它们不等同于 `selectedStack` |
| 模态、alert、离开确认 | 复用本层 `NavigationPresentationContext` 与唯一的呈现宿主 |

选择动作集中处理根与 path，行为如下：

| 用户动作 | 详情根与 path |
| --- | --- |
| 选择另一个对象 | `setRootDestination` 换根，同时清空旧 path |
| 重复选择同一对象 | 保留根和 path；不要再次调用换根 |
| 清空选择 | 换成空态根，同时清空 path |
| 切换分类 | App 明确决定保留当前详情及 path，或换成空态根 |
| 从详情继续浏览 | `push` 追加 path，根保持不变 |

只有栈操作结果的 `isApplied` 为 true 后，App 才同步修改分类或布局。重复选择、程序显示详情等只改变布局的动作，可以先检查 `navigation.setPath(navigation.path).isApplied`。这样等待离开确认或关闭时，前栏也不会提前改变界面。

完整接法见 [CalendarDebugSplitView](../ChineseCalendarUI/Debug/CalendarDebugSplitView.swift) 和 [CalendarDebugSplitState](../ChineseCalendarUI/Debug/CalendarDebugSplitState.swift)：前者声明两栏／三栏及列表 Binding，后者集中处理选择和布局。空态使用 `.debugSplitEmpty`，对象详情使用 `.debugSplitDetail(item:level: 0)`；它们由 App 的统一页面配置构建。

分栏作为 sheet／full-screen 时，继承当前导航树配置，取得新模态层的 Context，内部不再挂第二份 `navigationHost`。详情根与 path 在当前导航层存续期间保留；分类、保留策略和布局由 App 管理。原生折叠、深 path 下返回、宽窄切换及系统 Binding 写回需分别进行实际交互验证，API 接法本身不代表运行验证已通过。具体约定见 [NAV-07](../../Docs/Conventions/Navigation.md#nav-07--app-原生分栏与详情栈组合)。

### 业务 alert

业务提示使用独立路由及强类型按钮动作。要在最小示例中启用它，定义以下类型，并将 Router、`AppPresentation` 和 `DemoConfiguration.AlertRoute` 中的 `NoNavigationAlert` 一起替换为 `AppAlert`：

```swift
nonisolated enum AppAlert: NavigationAlertRoute {
    case notice, openDetail
}
nonisolated enum NoticeAction: Hashable { case acknowledge }
nonisolated enum DetailAction: Hashable { case open, cancel }
```

在 `DemoConfiguration` 中增加提示映射：

```swift
func alert(for route: AppAlert, presentation: AppPresentation) -> NavigationAlertDefinition? {
    switch route {
    case .notice:
        NavigationAlertDefinition(
            content: NavigationAlertContent(
                title: "提示", message: "资料已更新。",
                firstButton: NavigationAlertButton("知道了", action: NoticeAction.acknowledge)
            )
        ) { action in
            switch action {
            case .acknowledge: break
            }
        }
    case .openDetail:
        NavigationAlertDefinition(
            content: NavigationAlertContent(
                title: "查看资料？", message: "将打开资料页面。",
                firstButton: NavigationAlertButton("查看", action: DetailAction.open),
                cancelButton: NavigationAlertCancelButton("取消", action: .cancel)
            )
        ) { action in
            switch action {
            case .open: presentation.present(.detail(id: 42))
            case .cancel: break
            }
        }
    }
}
```

页面通过 `presentation.present(.alert(.notice))` 提交提示。`NavigationAlertDefinition` 的泛型初始化器同时绑定 content 和异步 handler：`NoticeAction` 的内容不能接 `DetailAction` 的 handler。每个 handler 完整处理自己的选项，不需要其他提示的 case 或 default；同类提示也可以复用一个 Action。

具体 Action 在定义内部捕获为按钮动作，调用方无需强转或运行时 route/action 校验。Router 和队列只保存路由，definition 与 handler 由宿主配置构建。宿主在系统提示真实关闭后执行动作，并等待异步工作完成再处理后续导航；单纯关闭的提示也显式提供只处理自身 Action 的空操作。框架离开确认使用独立的内部动作类型，不并入业务 Action。

提示必须至少有一个按钮：普通／危险按钮使用必填 `firstButton` 和可选 `additionalButtons`；取消按钮使用单独的 `cancelButton: NavigationAlertCancelButton<Action>`。只有取消按钮时，使用 `NavigationAlertContent(title:message:cancelButton:)`。

普通按钮按 `Action` 去重：相同 Action 采用最后的标题和样式，保留首次出现的位置。取消按钮独立于普通按钮集合，宿主将它放在首位，并使用同一顺序映射点击动作。详细构造见 [NavigationAlertContent](SwiftUI/Alerts/NavigationAlertContent.swift)。

## Deep Link 与离开确认

URL、通知或启动参数由 App 解析。需要先处理当前模态的跳转交给根 Router 的 `submit`，例如对最小示例的根栈提交：

```swift
router.submit(
    .replacePath([.detail(id: 42)], on: .primary),
    confirmIfPresented: true
)
```

Tab 根界面可把目标换成 `.scope(.history)`。请求始终指向**根层**栈；模态内部的局部 push 使用该层的 `NavigationContext`。

使用 `confirmIfPresented: true` 时，在配置中提供确认文案：

```swift
func confirmationContent(
    for request: NavigationRequest<AppScope, AppRoute>
) -> NavigationConfirmationContent? {
    NavigationConfirmationContent(
        title: "离开当前页面？", message: "将关闭当前弹出页面并打开链接。",
        confirm: "关闭并前往", cancel: "留在当前页面"
    )
}
```

| 当前情况 | `submit` 的结果与宿主行为 |
| --- | --- |
| 没有模态或待处理事务 | `.applied`：请求已应用到导航数据 |
| 需要用户同意离开模态 | `.awaitingConfirmation`：保留原页面与路径，显示确认 |
| 已获准，等待页面模态关闭 | `.deferredUntilPresentationDismisses`：真实关闭完成后才应用 |
| 正在显示业务 alert 或处理按钮动作 | `.deferredUntilAlertDismisses`：先完成提示流程，再判断是否需要离开确认 |
| 目标与根层栈结构不兼容或栈未声明 | `.rejected(reason)`：不修改状态，原因如 `.incompatibleContainer`、`.undeclaredStack` |

取消保留原状态；批准后先关闭模态树，再由根宿主的真实关闭回调触发跳转。App 的额外 selection 也应在请求实际应用时同步，不能在提交或仅获批准时提前修改。真实关闭通知由内置宿主处理，业务不手动报告完成。

`submit` 的 `confirmIfPresented` 默认为 `false`，用于业务已批准的导航；即使如此，仍会等待模态真实关闭。局部栈修改由对应 Context 发起；需要跨层确认和关闭时使用 `submit`。

确认对象、内部确认 ID 及批准／取消命令仅供 Core 宿主使用。业务选择确认流程时必须提供 `confirmationContent(for:)` 文案；默认返回 nil 不会自动批准。需要业务保存的流程由业务动作明确完成后再提交外部请求，不自行接管内部确认事务。

### alert、关闭与新请求如何排序

业务 alert 存在时，外部请求保留最新目标及其确认要求，按以下顺序推进：

1. 当前提示实际关闭。
2. `NavigationAlertDefinition` 所绑定的异步业务动作完成。
3. 同层排队呈现按顺序处理；若排到页面模态，等待该页关闭后继续。
4. 重新评估外部请求：仍有页面模态则显示离开确认，只有根 alert 的场景可直接导航。
5. 获准后等待模态树真实关闭，再应用目标。

业务提示的“确定”不代表批准 Deep Link。新链接也不能沿用旧链接的批准：相同待确认请求去重，不同请求使用新 ID；已批准的 A 与待确认的 B 可以并存，取消 B 不撤销 A。

关闭当前模态同样要等待活动 alert 和按钮动作完成，关闭后丢弃失效层的排队呈现。框架通过提示会话 ID 和真实 UIKit 关闭 completion 串行推进流程，不依赖固定延时。业务页面通过统一宿主提交提示，不另建一套 `.alert` 状态。项目规则见 [NAV-05](../../Docs/Conventions/Navigation.md#nav-05--关闭和外部导航协调)。

## 操作约束与生命周期

`NavigationContext` 绑定一个具体栈，`NavigationPresentationContext` 绑定一个具体层。页面应使用环境里所属作用域的入口；coordinator 需要操作某个栈时，可通过 `presentation.context(for: stackID)` 显式取得。

- **先声明根，再取得 Context。** 获取 Context 不创建栈；未声明栈的 Context 无效，后来出现同 ID 栈也不会使它复活。外部容器应为所有要显示的栈提供根；初始化还会检查选中栈和所有带 path 的栈都有根。非法 Router 初始化触发前置条件失败，非法 `present` 的 `submission.result` 为 `.rejected(.incompatibleContainer)` 或 `.rejected(.missingRootDestination)`。
- **有效不等于此刻允许修改。** 是否仍关联原层或栈由库内校验，不提供公开有效性查询。离开确认、活动 alert 或关闭事务期间，局部导航可能返回 `.rejected(.awaitingConfirmation)`、`.rejected(.alertInProgress)` 或 `.rejected(.awaitingDismissal)`。`setRootDestination`、`setPath`、`push`、`pop` 返回 `NavigationMutationResult`；需要同步 App 状态时检查 `isApplied`。
- **呈现需要已挂载的宿主。** Context 尚未接入 `navigationHost` 时，提交结果为 `.rejected(.hostUnavailable)`；测试不能只构造 Router 就假装系统已接手。
- **页面模态从当前层继续打开。** 同层已有页面模态时，新的 `present` 被拒绝；用该模态内部的 `NavigationPresentationContext` 继续嵌套。业务 alert 期间可排队，接受不等于立即显示。
- **关闭后旧入口失效。** Context 弱引用导航状态，持有旧 Context 不会保活 Router 或模态。模态从树中移除时 Context 立即失效；对象身份检查确保同 ID 的新层或新栈不能让旧 Context 重新有效。

### Context 缓存与释放

每个 Router 独立持有一个 MainActor 隔离的内部 `NavigationContextStore`，统一缓存栈入口、层级呈现入口和带发起栈身份的呈现入口。重复获取有效入口复用同一对象；缓存命中同时核对原状态对象，旧入口不能覆盖新对象的有效缓存。真实 dismiss 完成后，Router 统一调用 `removeInactiveContexts()` 释放失效缓存；Context 的失效不等待这次清理。

### 发起呈现的栈限制

栈宿主默认注入 `presentation.scoped(to: stackID)`：它与本层其他 `NavigationPresentationContext` 共享状态，但额外限制只有选中栈可以发起 present，防止后台 Tab 的回调弹窗。因此“一层”不等于“只有一个 Context 对象”。Tab 公共附件使用层级入口；同时可交互的栏目可用 `unscoped()`，或给栈宿主传 `restrictsPresentationToSelectedStack: false`，显式取消发起栈限制。

### 只读取本页面需要的局部状态

容器绑定当前层的 `presentation.selectedStack`，页面读取所属栈的 `rootDestination` 和 `path`；关闭按钮使用 `presentation.isPresented`，栈底判断使用 `navigation.path.isEmpty`。操作是否获准以命令结果为准，资源结束以单次 `onFinish` 为准。

原 Router 的整树投影、节点查询、等待／确认状态，以及 Context 的内部层身份、route／destination 和 `isActive` 均不再对外开放。不要新增 App 包装来恢复这些查询，也不要把它们当成生命周期通知。

### 容器入口与 push 的边界

`providesNavigationContainer` 决定的是整层入口的承载方式。普通 push 在当前栈构建页面，不创建新的层或栈命名空间。每层的同一个栈只能有一个宿主；不要在某个 Tab 的栈内再次 push 复用这些同名栈的整个 Tab 容器。

## 配置与业务数据放在哪里

`NavigationHostConfiguration.destination(for:)` 统一构建层入口、栈根和 push 页面。根宿主提供默认配置；`present(request, configuration:onFinish:)` 可提供本次流程的配置，该模态的栈根、push 和普通子模态继续继承它。子流程需要不同资源时再提供自己的配置，不修改父流程的配置。

业务依赖保存在配置的值类型中，配置直接引用这一次资源，不能仅在渲染时查询 `owner.currentSession`。App 共享 store 环境仍从根部注入；页面的 selection、ModelContext 和结果动作由对应来源 feature 提供。日历 App 的 `CalendarYearFeature` 持有本次 picker session，`CalendarHomeCoordinator.yearPickerConfiguration` 把 feature 与具体 session 交给原有 builder，不再按 session ID 回查字典。

```text
来源 feature ──拥有── 本次资源与 handle
                   ↓ 直接传入
View 宿主 → endpoint → render record → 本次配置 + onFinish
                            ↑ weak observer
Router 的结构请求／节点 → 内部 lifetime ← handle
```

`NavigationPresentationEndpoint` 由 SwiftUI 宿主持有，在提交结构请求前建立 `NavigationPresentationRenderRecord`。该记录保存具体配置和 `onFinish`，拒绝时立即撤回；Router 的节点及队列只保存结构数据与 lifetime。lifetime 弱引用 record observer，handle 弱引用 Router，因此这些操作入口不反向保活配置或业务 feature。

页面接手由内部 `NavigationModalLifecycle` probe 在 `makeUIViewController` 创建控制器时同步完成 `claim`，不以业务 builder／sheet 内容闭包求值或 `onAppear` 代替。认领只表示宿主承担本次结束责任，不表示页面已显示完成。probe 记录真实 presenter／window 关联；已挂载页面等 UIKit dismiss／未取消的 transition completion，只有从未挂载的同一 probe 真实销毁才证明该次界面已被丢弃。dismantle 本身不报告物理完成，已结束请求也不接受晚到 probe。

终止信号由 Core 决定；record 取走一次性回调并解除登记，以局部引用保留配置到回调返回。来源只清理本次资源，不能清空页面仍使用的 selection 或 ModelContext。来源/store 变化可立即撤销结果资格、取消自己的任务和 handle；真正关闭后再释放动画所需引用。`onFinish` 不提供关闭起点广播，也不能由 owner deinit、普通 `onDisappear` 或固定延时替代。

配置协议没有无参数的全局关闭回调。`retainedPresentationRoutes`、`retains(context)`、`alertRoutes` 和 `CalendarNavigationSessionCleanup` 已移除，不建立替代注册表或扫描器。历史与 DEBUG 分栏的布局状态属于完整容器的 `@State`，数据查询子树的 identity 重建不重建布局 owner；纯值提示无需会话 owner。

正式页面使用 `NavigationScopeView(stack:presentation:)`，让配置从根路由构建内容。带 `root` 闭包的初始化器供独立 Preview／测试覆盖显示内容，仍须声明栈根，覆盖内容不改变路由状态。独立 Preview 也提供根 `navigationHost`；递归节点宿主是 Core 内部实现。App 集成测试用普通 `import NavigationCore` 和真实宿主，测试探针只能观测，不伪造系统关闭完成。

真实关闭、祖先退出、宿主拆除及资源释放的测试环境、运行结果和覆盖边界见 [Issue #165 结果记录](../../Docs/Tasks/issue-165-presentation-ownership/001-result.md)。

## 运行时状态与启动边界

Core 保留当前导航树中的栈根、path、Tab 选择和递归模态。切换 Tab 或关闭子模态后，仍存续的父层状态继续可用；这些行为由运行时状态对象提供。

Core 不提供完整导航树的快照、编码或恢复 API，日历 App 也没有完整界面跨启动恢复入口。新建 Router 使用正常初始化参数建立根层，模态通过 `present` 建立新层；二者共用内部初始化校验，普通单栈只接受 `.primary`，外部容器必须为选中栈和所有带路径栈声明根。完整校验通过后才建立状态，非法呈现不会部分修改当前树。

Deep Link 继续由 App 解析稳定业务地址，再交给 Router 的请求协调。若未来产品需要跨启动恢复，应另行定义需要保存的业务状态、数据校验及迁移策略。决策与本轮验收见 [Issue #159／#158](../../Docs/Tasks/issue-159-navigation-runtime/000-plan.md)。

## 源码目录

源码采用两级组织：一级目录表示实现层次，二级目录表示职责。

- `State` 保存导航结构和运行时状态。
- `Routing` 提供操作入口、请求处理和生命周期协调。
- `SwiftUI` 将状态接到页面、系统容器和提示宿主。

按下面的职责行横向阅读，可以找到同一能力涉及的状态、操作和界面。空白位置用“—”表示该能力由其他分组共同承担，无需为保持对称而新建目录。

| 职责 | State | Routing | SwiftUI |
| --- | --- | --- | --- |
| 导航栈：根页面、push 路径与操作入口 | [Stack](State/Stack/) | [Contexts](Routing/Contexts/) | [Stack](SwiftUI/Stack/) |
| 导航层：层入口、栈集合与内容 | [Layer](State/Layer/) | [Presentation](Routing/Presentation/) | [Layer](SwiftUI/Layer/) |
| 呈现：页面模态节点、请求与递归宿主 | [Presentation](State/Presentation/) | [Presentation](Routing/Presentation/) | [Presentation](SwiftUI/Presentation/) |
| 提示：路由、会话、按钮与系统适配 | [Alerts](State/Alerts/) | [Alerts](Routing/Alerts/) | [Alerts](SwiftUI/Alerts/) |
| 协调：外部请求、离开确认与操作约束 | [Coordination](State/Coordination/) | [Coordination](Routing/Coordination/) | 确认提示位于 [Alerts](SwiftUI/Alerts/) |
| 整树入口与统一配置 | — | [Router](Routing/Router/) | [Hosting](SwiftUI/Hosting/) |

`Layer` 表示一整层界面，根界面和模态界面都拥有自己的层；`Presentation` 表示呈现内容及其生命周期。`NavigationPresentationContext` 是层操作入口，因此也负责访问本层栈和选中栈。

### 沿着一次操作阅读

- **push：** [NavigationContext](Routing/Contexts/NavigationContext.swift) 修改 [NavigationStackState](State/Stack/NavigationStackState.swift) 的 path → [NavigationScopeView](SwiftUI/Stack/NavigationScopeView.swift) 绑定 path → [NavigationHostConfiguration](SwiftUI/Hosting/NavigationHostConfiguration.swift) 构建目标页。
- **present：** [公开提交命令](SwiftUI/Presentation/NavigationPresentationCommands.swift) → [Endpoint](SwiftUI/Presentation/NavigationPresentationEndpoint.swift) 建立 [RenderRecord](SwiftUI/Presentation/NavigationPresentationRenderRecord.swift) → Router 接受或排队结构请求 → [NavigationPresentationHost](SwiftUI/Presentation/NavigationPresentationHost.swift) 驱动系统呈现 → [NavigationPresentationNodeView](SwiftUI/Presentation/NavigationPresentationNodeView.swift) 使用本次配置接入新层。
- **外部跳转：** [NavigationRouter.submit](Routing/Router/NavigationRouter.swift) 接收请求 → [NavigationCoordinationState](State/Coordination/NavigationCoordinationState.swift) 保存确认与延迟意图 → 宿主报告真实关闭 → Router 应用目标。

`NavigationRouter+Alerts` 同时负责业务提示与页面模态的排队，追踪呈现流程时也需要阅读它。离开确认的数据在 `Routing/Coordination`，对应提示界面在 `SwiftUI/Alerts`。

这些目录属于同一个 `NavigationCore` target。模块日志入口是 [NavigationCoreLog.swift](NavigationCoreLog.swift)。相邻 [NavigationCoreTests](../NavigationCoreTests/) 中的结构与协调测试仍运行在 SwiftPM target；`NavigationPhysicalHostTests.swift` 和其 support 则由 [project.yml](../../project.yml) 的 App-hosted `ChineseCalendarUITests` 编译，与 App 集成测试共用真实前台 `UIWindowScene` 和串行窗口租约。

独立 SwiftPM runner 不保证有 connected scene；仅创建 `UIWindow(frame:)` 和等待 `onAppear` 不能证明 UIKit 呈现环境可用。真实呈现测试必须从配置了 `TEST_HOST`／`BUNDLE_LOADER` 的 App-hosted target 运行，窗口使用 `UIWindow(windowScene:)`，没有前台 scene 时明确失败。App 测试继续使用普通 `import NavigationCore`；Core 物理合同测试按内部测试使用 `@testable`，放入同一宿主 target 不改变 API 边界。自动测试与手势、宽窄切换等实际交互证据分别记录。

## 在日历 App 中继续阅读

| 想了解的接入 | 文件 |
| --- | --- |
| 根数据环境与宿主如何连接 | [ChineseCalendarRootView](../ChineseCalendarUI/App/ChineseCalendarRootView.swift)、[CalendarNavigationHost](../ChineseCalendarUI/Home/Navigation/CalendarNavigationHost.swift) |
| 三个 Tab 如何使用各自的栈 | [CalendarHomeTabView](../ChineseCalendarUI/Home/CalendarHomeTabView.swift) |
| 页面路由如何变成 View | [CalendarNavigationConfiguration](../ChineseCalendarUI/Home/Navigation/CalendarNavigationConfiguration.swift)、[CalendarDestinationView](../ChineseCalendarUI/Home/Navigation/CalendarDestinationView.swift) |
| 提示文案与异步业务动作 | [CalendarAlertContent](../ChineseCalendarUI/Home/Navigation/CalendarAlertContent.swift)、[CalendarHomeCoordinator+Alerts](../ChineseCalendarUI/Home/Navigation/CalendarHomeCoordinator+Alerts.swift) |
| 业务 selection 和临时会话 | [CalendarYearFeature](../ChineseCalendarUI/Calendar/Year/CalendarYearFeature.swift)、[CalendarYearPickerSession](../ChineseCalendarUI/Calendar/Year/Picker/CalendarYearPickerSession.swift) |
| 下载演示与正式详情的来源 owner | [FullStoreDownloadPreviewFeature](../ChineseCalendarUI/PreviewSupport/FullStoreDownloadPreviewFeature.swift)、[CalendarDownloadDetailsFeature](../ChineseCalendarUI/App/Store/CalendarDownloadDetailsFeature.swift) |
| 普通导航及外部请求的 DEBUG 示例 | [CalendarDebugNavigationView](../ChineseCalendarUI/Debug/CalendarDebugNavigationView.swift) |
| 两栏／三栏的 DEBUG 示例 | [CalendarDebugSplitView](../ChineseCalendarUI/Debug/CalendarDebugSplitView.swift)、[CalendarDebugSplitState](../ChineseCalendarUI/Debug/CalendarDebugSplitState.swift) |

DEBUG 入口位于设置页“调试 → 调试操作”，由 [CalendarDebugActionsMenu](../ChineseCalendarUI/Debug/CalendarDebugActionsMenu.swift) 组织。示例使用正式 SDK 宿主。交互验证结果和未完成项以对应任务记录为准，不以 README 的示例替代验证证据。

当前接入规则见[导航规范](../../Docs/Conventions/Navigation.md)；旧 API 的替换关系、历史方案和验收记录入口见[迁移说明](MIGRATION.md)。
