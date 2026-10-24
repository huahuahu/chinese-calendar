# NavigationCore

NavigationCore 是一个面向 SwiftUI 的导航库，支持栈内 push／pop、sheet、全屏模态、多个 Tab 的独立路径、业务提示和外部链接跳转。

App 定义页面路由，并提供将路由构建为 View 的方法。NavigationCore 保存导航状态，将这些状态接到系统导航容器。页面的数据、编辑内容、网络请求和结果处理由 App 管理。

## 接入前准备

- **平台：** iOS 26 及以上。
- **工具链：** 本仓库的 Swift Package 使用 Swift tools 6.3。
- **依赖：** 将仓库的 `Sources` 目录作为本地 Swift Package 加入工程，为 App target 添加 `NavigationCore` product，然后 `import NavigationCore`。Package 定义见 [Package.swift](../Package.swift)。
- **执行环境：** Router、Context 和宿主配置在 `MainActor` 上使用。

首次接入需要认识四个名字：

| 类型 | 你用它做什么 |
| --- | --- |
| `NavigationDestination` | 定义页面路由，例如 `.detail(id: 42)` |
| `NavigationHostConfiguration` | 将路由构建为页面，提供提示与离开确认的内容 |
| `NavigationRouter` | 在根部持有导航状态，接收 Deep Link 等外部请求 |
| 两种 Context | 页面通过环境中的 `NavigationContext` 操作当前栈，通过 `NavigationPresentationContext` 打开和关闭模态 |

## 第一个导航界面

下面是一个完整的单栈示例。把 `DemoRoot` 放入 App 的 `WindowGroup` 即可使用。示例文案直接写在代码中便于阅读，实际产品按自己的本地化方式提供文案。

```swift
import NavigationCore
import SwiftUI

// 单栈使用 .primary，不需要定义命名栈。
nonisolated enum AppScope: NavigationScope {}

nonisolated enum AppRoute: NavigationDestination {
    case home
    case detail(id: Int)
}

typealias AppNavigation = NavigationContext<AppScope, AppRoute>
typealias AppPresentation = NavigationPresentationContext<
    AppScope, AppRoute, NoNavigationAlert
>

struct DemoConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = AppScope
    typealias Destination = AppRoute
    typealias AlertRoute = NoNavigationAlert

    @ViewBuilder
    func destination(for route: AppRoute) -> some View {
        switch route {
        case .home:
            DemoPage(title: "首页")
        case let .detail(id):
            DemoPage(title: "资料 \(id)")
        }
    }
}

struct DemoRoot: View {
    @State private var router = NavigationRouter<AppScope, AppRoute, NoNavigationAlert>(
        rootDestination: .home
    )

    var body: some View {
        NavigationRootView(context: router.rootPresentation)
            .navigationHost(
                context: router.rootPresentation,
                configuration: DemoConfiguration()
            )
    }
}

struct DemoPage: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(AppPresentation.self) private var presentation
    let title: String

    var body: some View {
        List {
            NavigationLink("查看资料 1", value: AppRoute.detail(id: 1))
            Button("查看资料 2") { navigation.push(.detail(id: 2)) }
            Button("弹出资料 3") { presentation.present(.sheet(.detail(id: 3))) }
            Button("返回上一页") { navigation.pop() }
                .disabled(navigation.path.isEmpty)
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

`DemoRoot` 用 `@State` 保持 Router 的身份，在导航树根部挂一次 `navigationHost`。配置中的 `destination(for:)` 用于根页面、push 页面和模态页面。

普通页面由库提供 `NavigationStack`，页面直接使用 `NavigationLink(value:)` 或 Context，无需再包栈或注册 `navigationDestination`。`NoNavigationAlert` 表示这棵树不使用业务提示。

## 栈、模态与操作入口

**push 在当前栈中前进；sheet 和全屏模态打开新的导航层。** 每层有自己的栈与模态呈现状态。模态里面继续 push 不改变下面页面的路径，关闭模态后可继续原来的浏览。

```text
根界面
└── 首页栈：首页 → 资料详情
    └── sheet
        └── 独立的栈：编辑页 → 编辑选项
```

每个栈包含一个 `rootDestination` 和一个 `path`。根页面不在 path 中，所以 `path.isEmpty` 表示已经在栈底。

| 操作 | 调用方式 | 作用 |
| --- | --- | --- |
| 前进 | `navigation.push(.detail(id: 42))` | 向当前栈追加页面 |
| 返回 | `navigation.pop()` | 移除当前栈最后一页 |
| 设置路径 | `navigation.setPath([...])` | 替换当前栈的 push 路径 |
| 更换栈根 | `navigation.setRootDestination(.home)` | 更换根页面，并清空该栈 path |
| 打开 sheet | `presentation.present(.sheet(.detail(id: 42)))` | 从所在层打开模态 |
| 打开全屏模态 | `presentation.present(.fullScreen(.detail(id: 42)))` | 从所在层打开全屏模态 |
| 关闭当前模态 | `presentation.dismiss()` | 关闭自己所在的模态及其后代 |
| 关闭自己发起的请求 | `submission.handle?.dismiss()` | 定位该次请求；未展示时取消，已展示时请求关闭 |
| 关闭整棵树中的呈现 | `router.dismissAllPresentations()` | 从根层协调关闭页面模态与提示 |

`presentation.isPresented` 表示这个 Context 是否属于一个有效模态。根页面即使弹出了 sheet，它自己的 `isPresented` 仍为 false。来源页面要关闭自己打开的 sheet，使用返回的 handle；sheet 内部使用自己的 `presentation.dismiss()`。

### 判断操作结果

导航方法可以忽略返回值；业务状态需要随操作结果变化时，应检查它。

| 返回值 | 判断方式 |
| --- | --- |
| 栈操作、换根、切换选中栈：`NavigationMutationResult` | `isApplied` 表示修改已应用 |
| `present`／`presentAlert`：`NavigationPresentationSubmission` | `result.isAccepted` 表示已应用或已排队；接受时提供 `handle` |
| `dismiss`：`NavigationPresentationResult` | `isAccepted` 表示关闭请求已接受 |
| `router.submit`：`NavigationRequestResult` | 区分已应用、等待确认、等待模态关闭或等待提示结束 |

`.applied` 表示导航数据已修改，界面可能仍在更新或播放动画。`.queued` 表示排队，所属层失效后可能被丢弃。两者都不代表页面已经显示或关闭。

`.noChange(reason)` 表示正常无操作，例如在栈底 pop；`.rejected(reason)` 表示操作未被接受，例如 Context 已失效。需要同步业务状态时，可以这样写：

```swift
guard navigation.setRootDestination(newRoot).isApplied else { return }
selectedCategory = newCategory
```

## 模态关闭与业务清理

打开模态时可传入本次关闭回调：

```swift
let submission = presentation.present(
    .sheet(.detail(id: 42)),
    onDismiss: {
        // 清理这一次流程的状态与资源。
    }
)

if submission.result.isAccepted {
    // 按需保存 submission.handle，以便来源页面主动取消或关闭。
} else {
    // 请求未接受，在这里清理刚准备的业务状态。
}
```

页面的 `onDismiss` 来自 SwiftUI 的 sheet／fullScreenCover 原生关闭回调。库先收尾对应的导航状态，再调用业务闭包；同一次回调最多消费一次。

| 场景 | 业务方如何清理 |
| --- | --- |
| 页面正常关闭并收到原生回调 | 在本次 `onDismiss` 中清理 |
| `present` 被拒绝 | 根据同步返回值清理，不会触发 `onDismiss` |
| 尚未展示的请求被取消 | 取消方同步清理，不会触发 `onDismiss` |
| 来源失效、宿主或 Router 销毁 | 由业务 owner 的生命周期负责，不保证收到 `onDismiss` |

主动取消或替换业务流程时，应立即撤销旧结果的使用资格并清理自己的状态。已显示页面之后仍可能收到关闭回调，因此清理方法应可重复调用，并核对是不是同一次流程，避免旧回调清空新流程。

handle 只提供 `dismiss()`，弱引用 Router 与请求；保留 handle 不会保活页面资源，释放 handle 也不会自动取消请求。嵌套模态各自接收系统回调，不应依赖父子回调顺序。普通 `onDisappear`、Tab 切换或子页面覆盖不表示模态已关闭。

## 向页面传参数和 Binding

页面参数放在 Destination 中，由 `destination(for:)` 解包后传给 View。普通参数可以直接使用枚举的关联值，例如 `.detail(id: 42)`。

需要回传编辑结果时，也可以传 Binding 或业务对象。**含 Binding 或引用的路由需要稳定的相等性和哈希，不能用变化中的绑定值计算身份。** 下面是一个独立的编辑路由示例：

```swift
nonisolated enum EditorRoute: NavigationDestination {
    case home
    case editor(id: UUID, title: Binding<String>)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home): true
        case let (.editor(left, _), .editor(right, _)): left == right
        default: false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .home:
            hasher.combine(0)
        case let .editor(id, _):
            hasher.combine(1)
            hasher.combine(id)
        }
    }
}
```

在使用 `EditorRoute` 的页面中，发起方可以把自己的 `@State` Binding 传入：

```swift
presentation.present(.sheet(.editor(id: UUID(), title: $title)))
```

对应配置的 `destination(for:)` 在 `.editor(_, title)` 分支中构建 `EditorView(title: title)`；编辑页用 `@Binding var title: String` 接收。创建时生成一次 ID，后续 Binding 内容变化不会改变这次路由的身份。普通值路由仍应比较全部有意义的关联值。

发起方持有业务状态，路由保留页面使用的参数，页面负责显示和交互。一棵导航树共享根部配置，打开模态时无需另传配置或建立资源查找表。需要“点保存后才生效”的编辑流程，由业务层维护草稿并显式提交，直接绑定会即时写回。

## 每个 Tab 保留独立路径

多 Tab 界面由 App 声明 `TabView`，每个 Tab 放一个 `NavigationScopeView`。以首页和历史两个 Tab 为例，将入门示例中的 Scope 和路由替换为：

```swift
nonisolated enum AppScope: NavigationScope { case home, history }

nonisolated enum AppRoute: NavigationDestination {
    case tabs, home, history
    case detail(id: Int)

    var providesNavigationContainer: Bool { self == .tabs }
}
```

`providesNavigationContainer` 默认为 false，表示库提供单栈。容器入口返回 true 时，App 自己组织其中的栈。配置中为 `.tabs` 返回 `DemoTabs()`，为 `.history` 返回相应页面，保留首页与详情的映射。

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

根 View 中的 Router 改为声明容器入口、初始选中栈和每个栈的根：

```swift
@State private var router = NavigationRouter<AppScope, AppRoute, NoNavigationAlert>(
    rootDestination: .tabs,
    initialStack: .scope(.home),
    rootDestinations: [.scope(.home): .home, .scope(.history): .history]
)
```

两个 Tab 共享所在层的模态呈现状态，各自保留 path。每个栈只挂一个 `NavigationScopeView`，Tab 内无需重复挂 `navigationHost`。

容器也能作为模态打开，传入同样的栈声明即可：

```swift
presentation.present(
    .tabs,
    style: .sheet,
    initialStack: .scope(.history),
    rootDestinations: [.scope(.home): .home, .scope(.history): .history]
)
```

模态中的 `DemoTabs` 从自己的环境读取 Context，拥有独立的选中栈和路径。页面操作应使用所在层的 Context，避免将 `router.rootPresentation` 固定传给所有页面。

## 业务提示与异步按钮

业务提示使用独立的 `NavigationAlertRoute`。启用提示时，将 Router、`AppPresentation` 和配置中使用的 `NoNavigationAlert` 都替换为自己的 `AppAlert`：

```swift
nonisolated enum AppAlert: NavigationAlertRoute {
    case openDetail(id: Int)
}

nonisolated enum OpenDetailAction: Hashable { case open, cancel }
```

在配置中实现 `alert(for:presentation:)`，将提示内容与同类型的按钮动作配对：

```swift
func alert(for route: AppAlert, presentation: AppPresentation) -> NavigationAlertDefinition? {
    switch route {
    case let .openDetail(id):
        NavigationAlertDefinition(
            content: NavigationAlertContent(
                title: "查看资料？",
                message: "将在弹出页面中显示资料。",
                firstButton: NavigationAlertButton("查看", action: OpenDetailAction.open),
                cancelButton: NavigationAlertCancelButton("取消", action: .cancel)
            )
        ) { action in
            switch action {
            case .open: presentation.present(.sheet(.detail(id: id)))
            case .cancel: break
            }
        }
    }
}
```

页面调用 `presentation.presentAlert(.openDetail(id: 42))` 即可。按钮处理闭包支持 `async`，在原生提示关闭后执行；库等待动作返回后再推进排队的呈现和外部导航。提示请求的 `onDismiss` 也在提示关闭及异步按钮处理完成后调用。

每类提示可以使用自己的 Action 类型。内容至少有一个按钮；只有取消按钮时，使用 `NavigationAlertContent(title:message:cancelButton:)`。文案参数使用 `LocalizedStringResource`，可以保留 App 自己的资源表与 bundle。

## Deep Link 与离开确认

URL 解析由 App 完成。需要关闭当前模态后再跳到某个根层页面时，将目标交给 Router：

```swift
router.submit(
    .replacePath([.detail(id: 42)], on: .primary),
    confirmIfPresented: true
)
```

多 Tab 根界面的目标可以改为 `.scope(.history)`。`submit` 操作的是根层栈；模态内部的普通前进继续使用当地的 `navigation.push`。

使用 `confirmIfPresented: true` 时，在配置中提供确认文案：

```swift
func confirmationContent(
    for request: NavigationRequest<AppScope, AppRoute>
) -> NavigationConfirmationContent? {
    NavigationConfirmationContent(
        title: "离开当前页面？",
        message: "将关闭当前弹出页面并打开链接。",
        confirm: "关闭并前往",
        cancel: "留在当前页面"
    )
}
```

没有模态时，目标可以直接应用。有模态时，库显示离开确认；取消保留原页面与路径，批准后等待模态关闭再应用目标。已有业务提示时，先等提示关闭及异步按钮动作完成，再继续处理跳转。

`submit` 返回的 `.awaitingConfirmation`、`.deferredUntilPresentationDismisses` 和 `.deferredUntilAlertDismisses` 都表示尚未应用目标，业务方不能据此提前提交依赖跳转完成的状态。确认文案默认是 nil，要求确认时必须提供；nil 不代表自动批准。

## 使用 NavigationSplitView

两栏或三栏布局由 App 的原生 `NavigationSplitView` 管理。容器路由的 `providesNavigationContainer` 返回 true，最后的详情栏使用 `NavigationScopeView`，前面的列表栏由 App 管理选择。

- 详情为空时，定义一个明确的空态 Destination 作为栈根。
- 选择另一个对象时，用详情 Context 的 `setRootDestination` 同时更换根和清空旧 path；重复选择同一对象时可保留路径。
- `columnVisibility`、`preferredCompactColumn` 和分类筛选属于 App 状态。
- 多个栏目同时可交互时，可给 `NavigationScopeView` 设置 `restrictsPresentationToSelectedStack: false`，使呈现不受选中 Tab 限制。

完整组合示例见 [CalendarDebugSplitView](../ChineseCalendarUI/Debug/CalendarDebugSplitView.swift) 和 [CalendarDebugSplitState](../ChineseCalendarUI/Debug/CalendarDebugSplitState.swift)。

## 常见接入问题

| 现象或疑问 | 检查方式 |
| --- | --- |
| 提示缺少配置，或页面没有内容 | 确认导航树根部挂了 `navigationHost`，配置完整处理 Destination |
| 出现重复导航栏或返回层级 | 普通页面由库提供栈；自带 Tab／分栏的入口应声明 `providesNavigationContainer`，每个栈只有一个宿主 |
| 后台 Tab 发起模态被拒绝 | 默认只有当前选中栈能发起呈现；Tab 公共控件使用层级 Context，同时可见栏目可显式使用 `unscoped()` |
| 模态中再次弹出被拒绝 | 使用模态页面环境中的 Context；父层已有直接子模态时不能再从父层打开另一个 |
| 栈 Context 无法操作 | 先在 `rootDestinations` 中声明栈；获取 Context 不会创建栈，旧 Context 也不会连接后来出现的新栈 |
| 正在确认或关闭时导航未生效 | 检查操作结果中的拒绝原因；等待中的事务会限制局部修改 |
| 需要保存整个导航树，下次启动恢复 | 本库提供运行时导航；持久化与 URL 编码由 App 定义，带 Binding 或临时对象的路由不适合直接保存 |

页面可读取自己的 path、栈根、选中栈和 `isPresented`。内部节点、呈现身份、队列与关闭事务不属于公开接口；业务通过操作结果、关闭 handle 和约定的回调协调流程。

## API 与完整示例

- [NavigationContext](Routing/Contexts/NavigationContext.swift)：当前栈的根、path、push 与 pop。
- [NavigationPresentationContext](Routing/Presentation/NavigationPresentationContext.swift) 与 [呈现方法](SwiftUI/Presentation/NavigationPresentationCommands.swift)：本层呈现、关闭和栈选择。
- [NavigationHostConfiguration](SwiftUI/Hosting/NavigationHostConfiguration.swift)：页面、提示和确认内容的构建协议。
- [CalendarNavigationConfiguration](../ChineseCalendarUI/Home/Navigation/CalendarNavigationConfiguration.swift)：实际 App 的统一页面配置。
- [CalendarYearFeature](../ChineseCalendarUI/Calendar/Year/CalendarYearFeature.swift)：发起方持有状态、通过 Binding 回传结果以及按请求清理的示例。
- [项目导航约定](../../Docs/Conventions/Navigation.md)：在本仓库接入页面、Tab 和分栏时遵循的规则。
