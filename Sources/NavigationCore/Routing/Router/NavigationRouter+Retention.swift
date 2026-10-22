public extension NavigationRouter {
    /// 仍需保留业务会话的模态路由，包括活动、排队及正在关闭的节点和后代。
    /// 正在关闭的子树在宿主确认实际关闭后移除；被丢弃的队列随所属层一起释放。
    /// 此投影用于业务数据清理，不代表这些页面仍可导航或已经显示。
    var retainedPresentationRoutes: [NavigationLayerRoute<Destination>] {
        rootLayer.retainedPresentations.map(\.layer.route)
    }

    /// 原栈是否仍由本树保留，包括关闭动画期间。外部持有的旧节点不影响判断。
    /// 业务缓存可据此延后释放；是否允许导航仍使用 Context.isActive。
    func retains(_ context: NavigationContext<Scope, Destination>) -> Bool {
        guard let state = context.state else { return false }
        return retainedLayers.contains { $0.stacks[context.id] === state }
    }
}

extension NavigationRouter {
    var retainedLayers: [NavigationLayer<Scope, Destination, AlertRoute>] {
        [rootLayer] + rootLayer.retainedPresentations.map(\.layer)
    }
}

private extension NavigationLayer {
    var retainedPresentations: [NavigationPresentationNode<Scope, Destination, AlertRoute>] {
        let queued = queuedPresentations.compactMap { content -> NavigationPresentationNode<
            Scope,
            Destination,
            AlertRoute
        >? in
            guard case let .page(node) = content else { return nil }
            return node
        }
        let nodes = [presentation, dismissingPresentation].compactMap(\.self) + queued
        return nodes.flatMap { [$0] + $0.layer.retainedPresentations }
    }
}
