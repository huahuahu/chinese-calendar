public extension NavigationPresentationContext {
    /// 页面沿用根宿主配置。onDismiss 由 SwiftUI 关闭回调触发；拒绝、未展示取消或宿主销毁不补发。
    /// alert 继续等待原生关闭及按钮异步动作完成后通知。
    @discardableResult
    func present(
        _ request: NavigationPresentationRequest<Scope, Destination, AlertRoute>,
        onDismiss: @escaping @MainActor () -> Void = {}
    ) -> NavigationPresentationSubmission {
        guard isActive, let router else {
            return NavigationPresentationSubmission(result: .rejected(.inactiveContext))
        }
        let lifetime = NavigationPresentationLifetime(onDismiss: onDismiss)
        let result = submitPresentation(request, lifetime: lifetime)
        guard result.isAccepted else { return NavigationPresentationSubmission(result: result) }
        return NavigationPresentationSubmission(
            result: result, handle: NavigationPresentationHandle(router: router, lifetime: lifetime)
        )
    }

    /// 直接指定页面和展示方式，内部转换为 NavigationPresentationRequest 后交给上面的 present 方法。
    @discardableResult
    func present(
        _ destination: Destination,
        style: NavigationPresentationStyle = .sheet,
        initialStack: NavigationStackID<Scope> = .primary,
        rootDestinations: [NavigationStackID<Scope>: Destination] = [:],
        paths: [NavigationStackID<Scope>: [Destination]] = [:],
        onDismiss: @escaping @MainActor () -> Void = {}
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
        return present(request, onDismiss: onDismiss)
    }

    @discardableResult
    func presentAlert(
        _ route: AlertRoute, onDismiss: @escaping @MainActor () -> Void = {}
    ) -> NavigationPresentationSubmission {
        present(.alert(route), onDismiss: onDismiss)
    }
}

public extension NavigationRouter {
    /// 在最上层模态中显示业务提示；没有模态时使用根层，当前已有提示时按该层的规则排队。
    @discardableResult
    func presentAlert(
        _ route: AlertRoute, onDismiss: @escaping @MainActor () -> Void = {}
    ) -> NavigationPresentationSubmission {
        let context = frontmostPresentationNode.map { presentationContext(for: $0) } ?? rootPresentation
        return context.present(.alert(route), onDismiss: onDismiss)
    }
}
