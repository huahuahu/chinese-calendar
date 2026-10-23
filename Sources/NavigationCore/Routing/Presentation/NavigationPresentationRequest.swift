// swiftformat:disable modifierOrder

/// 用强类型数据描述一次页面模态或业务 alert 的呈现请求；只有页面模态需要配置导航栈。
nonisolated public enum NavigationPresentationRequest<
    Scope: NavigationScope,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
> {
    case sheet(
        Destination,
        initialStack: NavigationStackID<Scope> = .primary,
        rootDestinations: [NavigationStackID<Scope>: Destination] = [:],
        paths: [NavigationStackID<Scope>: [Destination]] = [:]
    )
    case fullScreen(
        Destination,
        initialStack: NavigationStackID<Scope> = .primary,
        rootDestinations: [NavigationStackID<Scope>: Destination] = [:],
        paths: [NavigationStackID<Scope>: [Destination]] = [:]
    )
    case alert(AlertRoute)
}

extension NavigationPresentationContext {
    /// 根据数据请求呈现页面或业务提示。已有 alert 时返回 queued，applied 也不代表显示动画完成。
    @discardableResult
    func present(
        _ request: NavigationPresentationRequest<Scope, Destination, AlertRoute>,
        lifetime: NavigationPresentationLifetime
    ) -> NavigationPresentationResult {
        switch request {
        case let .sheet(destination, stack, roots, paths):
            present(
                destination,
                style: .sheet,
                initialStack: stack,
                rootDestinations: roots,
                paths: paths,
                lifetime: lifetime
            )
        case let .fullScreen(destination, stack, roots, paths):
            present(
                destination,
                style: .fullScreen,
                initialStack: stack,
                rootDestinations: roots,
                paths: paths,
                lifetime: lifetime
            )
        case let .alert(destination): submitAlert(destination, lifetime: lifetime)
        }
    }
}
