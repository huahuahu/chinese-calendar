import Foundation

public extension NavigationRouter {
    /// App 根层的 NavigationPresentationContext，供根界面容器和 TabView 附件等控件使用。
    /// 根层命名栈的 push/pop 使用 context(for: scope)；默认栈使用 rootPresentation.context(for: .primary)。
    var rootPresentation: NavigationPresentationContext<Scope, Destination, AlertRoute> {
        presentationContext(in: rootLayer)
    }

    /// 获取 App 根层指定命名栈的 NavigationContext；有效栈多次获取复用同一对象，不切换选中的栈。
    func context(for scope: Scope) -> NavigationContext<Scope, Destination> {
        context(in: rootLayer, stack: .scope(scope))
    }

    /// 获取指定模态默认 primary 栈的 NavigationContext。
    /// 多 Tab 模态需先获取 presentationContext，再调用它的 context(for:) 取得各 Tab 的栈。
    /// 传入已关闭的旧节点时，返回的 Context 失效，不能操作同 ID 新节点。
    func context(
        for node: NavigationPresentationNode<Scope, Destination, AlertRoute>
    ) -> NavigationContext<Scope, Destination> {
        context(in: node.layer, stack: .primary)
    }

    /// 获取指定模态的 NavigationPresentationContext，NavigationScopeView 再为各栈取得带发起栈信息的 Context。
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
    func presentation(id: NavigationPresentationID) -> NavigationPresentationNode<Scope, Destination, AlertRoute>? {
        presentations.first { $0.id == id }
    }

    /// 按 ID 关闭指定模态，以及从它继续打开的所有模态，保留父层各栈的路径。
    /// 根 Router 可以用此方法关闭任意一层模态；页面的 presentation.dismiss() 则关闭自己所在的模态。
    /// - Returns: 已应用、等待 alert 的 queued，或没有匹配模态的 noChange。
    @discardableResult
    func dismissPresentation(id: NavigationPresentationID) -> NavigationPresentationResult {
        let layers = [rootLayer] + presentations.map(\.layer)
        guard let parent = layers.first(where: { $0.presentation?.id == id }) else {
            return NavigationCoreLog.record(
                NavigationPresentationResult.noChange(.presentationNotFound),
                operation: "dismissPresentation", layer: .presentation(id)
            )
        }
        return presentationContext(in: parent).dismissPresented(id: id)
    }

    /// 批准指定的待确认请求，然后交给 submit 处理模态关闭和跳转。
    /// 使用用户看到的那条提示的 ID，避免旧按钮批准后来替换的新目标。
    /// 先清除 pendingConfirmation，让已批准的请求可以继续执行。
    @discardableResult
    func confirmNavigation(id: NavigationConfirmationID) -> NavigationRequestResult {
        guard let request = coordinationState.takeConfirmationRequest(id: id) else {
            return NavigationCoreLog.record(
                NavigationRequestResult.noChange(.staleConfirmation), operation: "confirmNavigation", layer: .root
            )
        }
        return submit(request)
    }

    /// 取消 ID 匹配的待确认请求，保留当前页面，也保留另一条已经批准、正在等待关闭的请求。
    @discardableResult
    func cancelConfirmation(id: NavigationConfirmationID) -> NavigationMutationResult {
        guard coordinationState.takeConfirmationRequest(id: id) != nil else {
            return NavigationCoreLog.record(
                NavigationMutationResult.noChange(.staleConfirmation), operation: "cancelConfirmation", layer: .root
            )
        }
        resumePresentations()
        return NavigationCoreLog.record(NavigationMutationResult.applied, operation: "cancelConfirmation", layer: .root)
    }

    /// 由界面容器在模态关闭动画完成后调用，并清理已经失效的 Context 缓存。
    ///
    /// 根界面打开的模态关闭完成时，isRoot 才能传 true，Router 随后执行等待中的全局跳转。
    /// 子模态的关闭通知不能代替根模态关闭完成。内置容器负责传入正确的值；
    /// 自定义容器还需结束对应层的关闭等待状态，根层的等待状态由本方法处理。
    func presentationDidDismiss(isRoot: Bool) {
        contextStore.removeInactiveContexts()
        if isRoot { _ = applyDeferredRequestIfReady() }
    }
}

extension NavigationRouter {
    /// 只返回判断结果，不在查询过程中输出日志；命令使用同一结果决定修改和诊断。
    func navigationRejection(in layer: NavigationLayer<Scope, Destination, AlertRoute>?) -> NavigationRejectionReason? {
        guard let layer, self.layer(id: layer.id) === layer else { return .inactiveContext }
        if isAwaitingPresentationDismissal { return .awaitingDismissal }
        if pendingConfirmation != nil { return .awaitingConfirmation }
        if hasActiveAlert { return .alertInProgress }
        return nil
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

    /// 通过本树的 Store 获取栈 Context，保持原状态对象的身份约束。
    func context(
        in layer: NavigationLayer<Scope, Destination, AlertRoute>, stack: NavigationStackID<Scope>
    ) -> NavigationContext<Scope, Destination> {
        contextStore.context(in: layer, stack: stack, router: self)
    }

    /// 通过本树的 Store 获取不限制发起栈的层级 Context。
    func presentationContext(
        in layer: NavigationLayer<Scope, Destination, AlertRoute>
    ) -> NavigationPresentationContext<Scope, Destination, AlertRoute> {
        contextStore.presentationContext(in: layer, router: self)
    }
}
