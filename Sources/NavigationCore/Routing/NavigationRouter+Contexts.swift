import Foundation

public extension NavigationRouter {
    /// App 根层的呈现 Context，供根界面容器和 TabView 附件等控件使用。
    /// 根 Tab 的 push/pop 使用 context(for: scope)。
    var rootPresentation: NavigationPresentationContext<Scope, Destination, AlertRoute> {
        presentationContext(in: rootLayer)
    }

    /// 获取指定根 Tab 的 NavigationContext；多次获取复用同一个对象，不切换当前 Tab。
    func context(for scope: Scope) -> NavigationContext<Scope, Destination> {
        context(in: rootLayer, stack: .scope(scope))
    }

    /// 获取指定模态默认 primary 栈的 NavigationContext。
    /// 多 Tab 模态需先获取 presentationContext，再调用它的 context(for:) 取得各 Tab 的栈。
    /// 传入已关闭的旧节点时，返回的 Context 失效，不能操作恢复后的同 ID 新节点。
    func context(
        for node: NavigationPresentationNode<Scope, Destination, AlertRoute>
    ) -> NavigationContext<Scope, Destination> {
        context(in: node.layer, stack: .primary)
    }

    /// 获取指定模态的呈现 Context，NavigationScopeView 再为各栈取得带发起栈信息的 Context。
    func presentationContext(
        for node: NavigationPresentationNode<Scope, Destination, AlertRoute>
    ) -> NavigationPresentationContext<Scope, Destination, AlertRoute> {
        presentationContext(in: node.layer)
    }

    /// 当前所有模态，按从最底层到最上层的顺序排列，不包含 App 根界面。
    var presentations: [NavigationPresentationNode<Scope, Destination, AlertRoute>] {
        presentedNode?.descendantsIncludingSelf ?? []
    }

    /// 按 ID 查找仍在 Router 中的模态。已关闭的模态即使仍被其他对象持有，也不会返回。
    func presentation(id: UUID) -> NavigationPresentationNode<Scope, Destination, AlertRoute>? {
        presentations.first { $0.id == id }
    }

    /// 按 ID 关闭指定模态，以及从它继续打开的所有模态，保留父层各栈的路径。
    /// 根 Router 可以用此方法关闭任意一层模态；页面的 presentation.dismiss() 则关闭自己所在的模态。
    /// - Returns: 找到并移除指定模态时返回 true，否则返回 false。
    @discardableResult
    func dismissPresentation(id: UUID) -> Bool {
        let layers = [rootLayer] + presentations.map(\.layer)
        guard let parent = layers.first(where: { $0.presentation?.id == id }) else { return false }
        return presentationContext(in: parent).dismissPresented(id: id)
    }

    /// 批准指定的待确认请求，然后交给 submit 处理模态关闭和跳转。
    /// 使用用户看到的那条提示的 ID，避免旧按钮批准后来替换的新目标。
    /// 先清除 pendingConfirmation，让已批准的请求可以继续执行。
    func confirmNavigation(id: UUID) {
        guard let pendingConfirmation, pendingConfirmation.id == id else { return }
        self.pendingConfirmation = nil
        _ = submit(pendingConfirmation.request)
    }

    /// 取消 ID 匹配的待确认请求，保留当前页面，也保留另一条已经批准、正在等待关闭的请求。
    func cancelConfirmation(id: UUID) {
        guard pendingConfirmation?.id == id else { return }
        pendingConfirmation = nil
        resumePresentations()
    }

    /// 由界面容器在模态关闭动画完成后调用，并清理已经失效的 Context 缓存。
    ///
    /// 根界面打开的模态关闭完成时，isRoot 才能传 true，Router 随后执行等待中的全局跳转。
    /// 子模态的关闭通知不能代替根模态关闭完成。内置容器负责传入正确的值；
    /// 自定义容器还需结束对应层的关闭等待状态，根层的等待状态由本方法处理。
    func presentationDidDismiss(isRoot: Bool) {
        contexts = contexts.filter(\.value.isActive)
        presentationContexts = presentationContexts.filter(\.value.isActive)
        if isRoot { _ = applyDeferredRequestIfReady() }
    }
}

extension NavigationRouter {
    /// 检查这一层是否仍有效，以及当前是否允许导航操作。
    /// 等待用户确认或等待根模态关闭时，暂不允许操作。
    func canNavigate(in layer: NavigationLayer<Scope, Destination, AlertRoute>?) -> Bool {
        guard let layer, self.layer(id: layer.id) === layer else { return false }
        return !isAwaitingPresentationDismissal && pendingConfirmation == nil && !hasActiveAlert
    }

    /// 决定在哪一层显示待确认请求：优先最上层模态，没有模态时使用根层。
    /// 根模态正在关闭时暂不显示，关闭完成后再根据新的页面状态决定。
    var confirmationLayerID: NavigationLayerID? {
        guard pendingConfirmation != nil, !layers.contains(where: \.isAwaitingDismissal),
              !hasBusinessAlert else { return nil }
        return frontmostPresentationNode.map { .presentation($0.id) } ?? .root
    }

    func layer(id: NavigationLayerID) -> NavigationLayer<Scope, Destination, AlertRoute>? {
        switch id {
        case .root: rootLayer
        case let .presentation(nodeID): presentation(id: nodeID)?.layer
        }
    }

    /// 按层 ID 和栈 ID 查找 Context；只有它仍关联同一个有效栈对象时才复用。
    /// 恢复出来的新栈即使 ID 相同，也会得到新的 Context。
    func context(
        in layer: NavigationLayer<Scope, Destination, AlertRoute>, stack: NavigationStackID<Scope>
    ) -> NavigationContext<Scope, Destination> {
        guard layer.route.destination.providesNavigationContainer || stack == .primary else {
            return NavigationContext(id: stack, state: nil, access: .inactive)
        }
        let id = NavigationContextID(layer: layer.id, stack: stack)
        let state = layer.stack(for: stack)
        if let existing = contexts[id], existing.state === state, existing.isActive { return existing }
        let access = NavigationStackAccess(
            isActive: { [weak self, weak layer, weak state] in
                guard let self, let layer, let state else { return false }
                return self.layer(id: layer.id) === layer && layer.stacks[stack] === state
            },
            canMutate: { [weak self, weak layer] in
                guard let self, let layer else { return false }
                return (layer.route.destination.providesNavigationContainer || stack == .primary) &&
                    !isAwaitingPresentationDismissal && pendingConfirmation == nil && !hasActiveAlert
            }
        )
        let context = NavigationContext(id: stack, state: state, access: access)
        // 只缓存有效 Context，避免旧页面覆盖恢复后的新栈缓存。
        if context.isActive { contexts[id] = context }
        return context
    }

    /// 每个有效层复用一个呈现 Context。检查原层对象，避免把旧模态的 Context 交给新模态。
    func presentationContext(
        in layer: NavigationLayer<Scope, Destination, AlertRoute>
    ) -> NavigationPresentationContext<Scope, Destination, AlertRoute> {
        if let existing = presentationContexts[layer.id], existing.layer === layer,
           existing.isActive { return existing }
        let context = NavigationPresentationContext(router: self, layer: layer)
        if context.isActive { presentationContexts[layer.id] = context }
        return context
    }
}
