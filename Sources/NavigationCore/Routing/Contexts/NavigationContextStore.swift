/// 统一持有一棵导航树的三类 Context；缓存本身不属于界面观察状态。
/// Context 及其访问闭包只弱引用 Router、层和栈，Store 不反向持有导航状态。
@MainActor
final class NavigationContextStore<
    Scope: NavigationScope,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
> {
    private var contexts: [NavigationContextID<Scope>: NavigationContext<Scope, Destination>] = [:]
    private var presentationContexts:
        [NavigationLayerID: NavigationPresentationContext<Scope, Destination, AlertRoute>] = [:]
    private var scopedPresentationContexts:
        [NavigationContextID<Scope>: NavigationPresentationContext<Scope, Destination, AlertRoute>] = [:]

    func context(
        in layer: NavigationLayer<Scope, Destination, AlertRoute>,
        stack: NavigationStackID<Scope>,
        router: NavigationRouter<Scope, Destination, AlertRoute>
    ) -> NavigationContext<Scope, Destination> {
        guard layer.route.destination.providesNavigationContainer || stack == .primary,
              let state = layer.stacks[stack]
        else {
            return NavigationContext(id: stack, state: nil, access: .inactive)
        }
        let id = NavigationContextID(layer: layer.id, stack: stack)
        if let existing = contexts[id], existing.state === state, existing.isActive { return existing }
        let access = NavigationStackAccess(
            isActive: { [weak router, weak layer, weak state] in
                guard let router, let layer, let state else { return false }
                return router.layer(id: layer.id) === layer && layer.stacks[stack] === state
            },
            canMutate: { [weak router, weak layer] in
                guard let router, let layer else { return false }
                return (layer.route.destination.providesNavigationContainer || stack == .primary) &&
                    router.canNavigate(in: layer)
            }
        )
        let context = NavigationContext(id: stack, state: state, access: access)
        // 旧节点仍可能被页面持有；失效入口不能覆盖同 ID 新状态的有效缓存。
        if context.isActive { contexts[id] = context }
        return context
    }

    func presentationContext(
        in layer: NavigationLayer<Scope, Destination, AlertRoute>,
        sourceStack: NavigationStackID<Scope>? = nil,
        router: NavigationRouter<Scope, Destination, AlertRoute>
    ) -> NavigationPresentationContext<Scope, Destination, AlertRoute> {
        let existing: NavigationPresentationContext<Scope, Destination, AlertRoute>? = if let sourceStack {
            scopedPresentationContexts[NavigationContextID(layer: layer.id, stack: sourceStack)]
        } else {
            presentationContexts[layer.id]
        }
        if let existing, existing.layer === layer, existing.isActive { return existing }
        let context = NavigationPresentationContext(router: router, layer: layer, sourceStack: sourceStack)
        guard context.isActive else { return context }
        if let sourceStack {
            scopedPresentationContexts[NavigationContextID(layer: layer.id, stack: sourceStack)] = context
        } else {
            presentationContexts[layer.id] = context
        }
        return context
    }

    /// 真实 dismiss 完成后释放失效缓存；从树中移除状态时，Context 已立即失效。
    func removeInactiveContexts() {
        contexts = contexts.filter(\.value.isActive)
        presentationContexts = presentationContexts.filter(\.value.isActive)
        scopedPresentationContexts = scopedPresentationContexts.filter(\.value.isActive)
    }
}
