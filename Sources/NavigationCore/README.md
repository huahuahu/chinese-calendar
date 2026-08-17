# NavigationCore

`NavigationCore` 是一个不包含具体业务含义的 SwiftUI 导航结构模块。它负责保存多个导航作用域的 root、push path，以及 root 和嵌套 presentation 的结构；具体 destination、页面分发、Tab 名称和 deep link 规则由调用方定义。

## 模块边界

允许依赖：

- Swift 标准库
- Foundation
- Observation
- SwiftUI
- `ChineseCalendarLogging`

不得在此模块中引入具体业务模型、页面或路由规则。日志也只记录 push、present、dismiss 和 path count 等结构事件，不记录或解析 destination 内容。

## 主要类型

- `NavigationRouter<Scope, Destination>`：保存每个 scope 的 root 和独立 push path，并管理 root sheet/full-screen。
- `NavigationPresentationNode<Destination>`：表示一个拥有独立 push path 的 presentation，允许继续嵌套 sheet/full-screen。
- `NavigationPresentationNodeView`：为 presentation 创建独立 `NavigationStack`，使用调用方提供的 destination builder 渲染 root 和 pushed destination，并递归承载子 presentation。
- `navigationFullScreenCover`：iOS 使用 `fullScreenCover`，macOS 退化为 `sheet`。

## 基本用法

业务层定义自己的 scope 和 destination：

```swift
import NavigationCore

enum AppSection: Hashable {
    case primary
    case settings
}

enum AppDestination: Hashable {
    case detail(String)
    case preferences
}

@MainActor
let navigation = NavigationRouter<AppSection, AppDestination>(
    selectedScope: .primary
)

navigation.setRootDestination(.detail("home"), for: .primary)
navigation.push(.detail("next"), on: .primary)
navigation.presentSheet(.preferences)
```

业务 Router 可以组合这个泛型 Router，并提供适合具体 UI 的命名属性和 `Binding`。业务 root `NavigationStack` 仍需在自己的层级注册 destination；root 与 push path 是两种不同状态，设置 root 时只会清空对应 scope 的 push path。

## Presentation host

root presentation 由业务视图绑定，内容仍由业务 destination builder 决定：

```swift
struct PresentationContent: View {
    @Bindable var navigation: NavigationRouter<AppSection, AppDestination>

    var body: some View {
        Color.clear
            .sheet(item: $navigation.sheet) { node in
                NavigationPresentationNodeView(node: node) { destination, dismiss in
                    AppDestinationView(destination: destination)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close", action: dismiss)
                            }
                        }
                }
            }
    }
}
```

`NavigationPresentationNodeView` 会为每个 presented node 创建独立的 `NavigationStack`，并在该层注册调用方的 `Destination` 类型。presented node 的 push path 不会修改任何 root scope 的 path。

## 测试

通用行为由 `NavigationCoreTests` 使用无业务含义的测试枚举覆盖。新增结构能力时，应优先在该 target 测试 scope 隔离、root/path 关系和 presentation 树；具体 Tab、deep link 与页面行为继续留在业务模块测试。
