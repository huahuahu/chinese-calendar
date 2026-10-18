/// 页面和 alert 共用的数据入口；只有页面模态需要选择初始导航栈。
public enum NavigationPresentationRequest<Scope: Hashable, Destination: Hashable, AlertRoute: NavigationAlertRoute> {
    case sheet(Destination, initialStack: NavigationStackID<Scope> = .primary)
    case fullScreen(Destination, initialStack: NavigationStackID<Scope> = .primary)
    case alert(AlertRoute)
}

public extension NavigationPresentationContext {
    /// 根据数据请求呈现页面或业务提示。已有 alert 时接受排队，返回 true 不代表已经显示。
    @discardableResult
    func present(_ request: NavigationPresentationRequest<Scope, Destination, AlertRoute>) -> Bool {
        switch request {
        case let .sheet(destination, stack): present(destination, style: .sheet, initialStack: stack)
        case let .fullScreen(destination, stack): present(destination, style: .fullScreen, initialStack: stack)
        case let .alert(destination): presentAlert(destination)
        }
    }
}
