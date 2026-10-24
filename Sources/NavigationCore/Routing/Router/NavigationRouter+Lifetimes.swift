extension NavigationRouter: NavigationPresentationCancelling {
    /// 根据 handle 保存的 lifetime 取消或关闭那一次 presentation request；即使路由相同，也不会关闭新 request。
    func dismiss(lifetime: NavigationPresentationLifetime) -> NavigationPresentationResult {
        guard !lifetime.finished else { return .noChange(.notPresented) }
        for layer in lifetimeLayers {
            if let index = layer.queuedPresentations.firstIndex(where: { $0.lifetime === lifetime }) {
                finish(layer.queuedPresentations.remove(at: index))
                resumePresentations()
                return .applied
            }
            if let node = layer.presentation, node.lifetime === lifetime {
                discardUnhostedDescendants(in: node.layer)
                if node.lifetime.hostClaimed, hasActiveAlert {
                    coordinationState.deferDismissalUntilAlertEnds(id: node.id)
                    return .queued
                }
                beginPresentationDismissal(in: layer)
                return .applied
            }
            if let alert = layer.alert, alert.lifetime === lifetime {
                layer.presentedContent = nil
                if !lifetime.hostClaimed {
                    lifetime.finish()
                    resumePresentations()
                }
                return .applied
            }
            if layer.dismissingPresentation?.lifetime === lifetime || layer.alertSession?.lifetime === lifetime {
                return .queued
            }
        }
        return .noChange(.notPresented)
    }
}

extension NavigationRouter {
    /// 取消本 layer 仍在排队的 presentation request 并释放路由参数；这些 request 尚未显示，无需等待关闭动画。
    func discardQueuedPresentations(in layer: NavigationLayer<Scope, Destination, AlertRoute>) {
        let queued = layer.queuedPresentations
        layer.queuedPresentations.removeAll()
        for content in queued {
            finish(content)
        }
    }

    /// 父模态关闭时，直接取消 host 尚未开始处理的子 presentation request。
    /// 已创建 session 的 alert 继续等待关闭动画和按钮操作完成。
    func discardUnhostedDescendants(in layer: NavigationLayer<Scope, Destination, AlertRoute>) {
        discardQueuedPresentations(in: layer)
        if let content = layer.presentedContent {
            if !content.lifetime.hostClaimed {
                layer.presentedContent = nil
                finish(content)
            } else if case let .page(node) = content {
                discardUnhostedDescendants(in: node.layer)
            }
        }
        if let node = layer.dismissingPresentation { discardUnhostedDescendants(in: node.layer) }
    }

    func beginPresentationDismissal(in layer: NavigationLayer<Scope, Destination, AlertRoute>) {
        guard let node = layer.presentation else { return }
        layer.presentation = nil
        discardQueues(in: node.layer)
        if !node.lifetime.hostClaimed {
            if self.layer(id: layer.id) === layer {
                completePresentationDismissal(in: layer, lifetime: node.lifetime)
            } else {
                // 父模态已在关闭，只结束这个 host 尚未开始处理的子 request；全局跳转仍等根模态关闭完成。
                layer.dismissingPresentation = nil
                layer.isAwaitingDismissal = false
                finish(.page(node))
            }
        }
    }

    /// 系统报告关闭完成时，同时核对发起 layer 和 request 的 lifetime，避免迟到回调关闭后来打开的页面。
    func completePresentationDismissal(
        in layer: NavigationLayer<Scope, Destination, AlertRoute>,
        lifetime: NavigationPresentationLifetime
    ) {
        guard lifetimeLayers.contains(where: { $0 === layer }) else { return }
        if let active = layer.presentation, active.lifetime === lifetime {
            // UIKit 直接关闭时可能还未更新 SwiftUI Binding；确认是同一次 request 后，清除 layer.presentation。
            layer.presentation = nil
            discardUnhostedDescendants(in: active.layer)
        }
        guard let node = layer.dismissingPresentation, node.lifetime === lifetime else { return }
        node.didCompletePhysicalDismissal = true
        guard self.layer(id: layer.id) === layer, !hasUnfinishedAlertSession(in: node.layer) else { return }
        if layer === rootLayer {
            _ = applyDeferredRequestIfReady()
        } else {
            layer.dismissingPresentation = nil
            layer.isAwaitingDismissal = false
            finish(.page(node))
            contextStore.removeInactiveContexts()
            resumePresentations()
        }
    }

    /// 重新检查已关闭的模态；子页面中的 alert 操作也完成后，才释放资源并继续等待中的导航。
    @discardableResult
    func completePendingPresentationDismissals() -> Bool {
        var didComplete = false
        for layer in lifetimeLayers {
            guard let node = layer.dismissingPresentation, node.didCompletePhysicalDismissal else { continue }
            completePresentationDismissal(in: layer, lifetime: node.lifetime)
            if layer.dismissingPresentation?.lifetime !== node.lifetime { didComplete = true }
        }
        return didComplete
    }

    private func hasUnfinishedAlertSession(in layer: NavigationLayer<Scope, Destination, AlertRoute>) -> Bool {
        if let session = layer.alertSession, session.state != .finished { return true }
        return [layer.presentation, layer.dismissingPresentation].compactMap(\.self)
            .contains { hasUnfinishedAlertSession(in: $0.layer) }
    }

    /// 结束本次 presentation 及其子 request，清除 node 引用，结束各 request 的内部身份。
    func finish(_ content: NavigationPresentation<Scope, Destination, AlertRoute>) {
        if case let .page(node) = content {
            let layer = node.layer
            let children: [NavigationPresentation<Scope, Destination, AlertRoute>] =
                [layer.presentedContent, layer.dismissingPresentation.map(NavigationPresentation.page)]
                    .compactMap(\.self)
            layer.presentedContent = nil
            layer.dismissingPresentation = nil
            layer.isAwaitingDismissal = false
            for child in children {
                finish(child)
            }
            discardQueuedPresentations(in: layer)
            if let lifetime = layer.alertSession?.lifetime { lifetime.finish() }
            layer.alertSession = nil
        }
        content.lifetime.finish()
    }

    private func discardQueues(in layer: NavigationLayer<Scope, Destination, AlertRoute>) {
        discardQueuedPresentations(in: layer)
        if let child = layer.presentation { discardQueues(in: child.layer) }
        if let child = layer.dismissingPresentation { discardQueues(in: child.layer) }
    }

    var lifetimeLayers: [NavigationLayer<Scope, Destination, AlertRoute>] {
        func collect(_ layer: NavigationLayer<Scope, Destination, AlertRoute>) -> [NavigationLayer<
            Scope,
            Destination,
            AlertRoute
        >] {
            let children = [layer.presentation, layer.dismissingPresentation].compactMap(\.self)
            return [layer] + children.flatMap { collect($0.layer) }
        }
        return collect(rootLayer)
    }
}
