/// 当前层直接展示的内容。页面可以拥有下一层；alert 是呈现链的末端。
public enum NavigationPresentation<
    Scope: NavigationScope,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
> {
    case page(NavigationPresentationNode<Scope, Destination, AlertRoute>)
    case alert(NavigationAlertNode<AlertRoute>)
}
