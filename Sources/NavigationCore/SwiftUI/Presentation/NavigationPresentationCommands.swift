public extension NavigationPresentationContext {
    /// 提交一次呈现。配置省略时继承本层宿主；已接受的请求真正结束后执行一次 onFinish。
    @discardableResult
    func present(
        _ request: NavigationPresentationRequest<Scope, Destination, AlertRoute>,
        configuration: (any NavigationHostConfiguration<Scope, Destination, AlertRoute>)? = nil,
        onFinish: @escaping @MainActor () -> Void = {}
    ) -> NavigationPresentationSubmission {
        guard isActive else { return NavigationPresentationSubmission(result: .rejected(.inactiveContext)) }
        guard let presentationEndpoint else {
            return NavigationPresentationSubmission(result: .rejected(.hostUnavailable))
        }
        return presentationEndpoint.submit(request, from: self, configuration: configuration, onFinish: onFinish)
    }

    /// 单页面的便利入口，与值请求入口使用同一套生命周期。
    @discardableResult
    func present(
        _ destination: Destination,
        style: NavigationPresentationStyle = .sheet,
        initialStack: NavigationStackID<Scope> = .primary,
        rootDestinations: [NavigationStackID<Scope>: Destination] = [:],
        paths: [NavigationStackID<Scope>: [Destination]] = [:],
        configuration: (any NavigationHostConfiguration<Scope, Destination, AlertRoute>)? = nil,
        onFinish: @escaping @MainActor () -> Void = {}
    ) -> NavigationPresentationSubmission {
        let request: NavigationPresentationRequest<Scope, Destination, AlertRoute> = switch style {
        case .sheet: .sheet(destination, initialStack: initialStack, rootDestinations: rootDestinations, paths: paths)
        case .fullScreen: .fullScreen(
                destination,
                initialStack: initialStack,
                rootDestinations: rootDestinations,
                paths: paths
            )
        }
        return present(request, configuration: configuration, onFinish: onFinish)
    }

    @discardableResult
    func presentAlert(
        _ route: AlertRoute, onFinish: @escaping @MainActor () -> Void = {}
    ) -> NavigationPresentationSubmission {
        present(.alert(route), onFinish: onFinish)
    }
}

public extension NavigationRouter {
    /// 全局业务事件交由库内选择前台层；业务无需读取模态树。
    @discardableResult
    func presentAlert(
        _ route: AlertRoute, onFinish: @escaping @MainActor () -> Void = {}
    ) -> NavigationPresentationSubmission {
        let context = frontmostPresentationNode.map { presentationContext(for: $0) } ?? rootPresentation
        return context.present(.alert(route), onFinish: onFinish)
    }
}
