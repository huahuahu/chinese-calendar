// swiftformat:disable modifierOrder

/// 用强类型数据描述一次 presentation request，可选择 sheet、fullScreen 或 alert；只有前两者需要配置导航栈。
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
    /// 根据 presentation request 打开页面或业务 alert；已有 alert 时返回 queued，applied 也不代表显示动画完成。
    @discardableResult
    func submitPresentation(
        _ request: NavigationPresentationRequest<Scope, Destination, AlertRoute>,
        lifetime: NavigationPresentationLifetime
    ) -> NavigationPresentationResult {
        switch request {
        case let .sheet(destination, stack, roots, paths):
            submitPresentation(
                destination,
                style: .sheet,
                initialStack: stack,
                rootDestinations: roots,
                paths: paths,
                lifetime: lifetime
            )
        case let .fullScreen(destination, stack, roots, paths):
            submitPresentation(
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
