/// 当前层直接展示的内容。页面可以拥有下一层；alert 是呈现链的末端。
enum NavigationPresentation<
    Scope: NavigationScope,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
> {
    case page(NavigationPresentationNode<Scope, Destination, AlertRoute>)
    case alert(NavigationAlertNode<AlertRoute>)

    var lifetime: NavigationPresentationLifetime {
        switch self {
        case let .page(node): node.lifetime
        case let .alert(node): node.lifetime
        }
    }
}
