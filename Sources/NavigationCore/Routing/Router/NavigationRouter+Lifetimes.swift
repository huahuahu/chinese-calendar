extension NavigationRouter: NavigationPresentationCancelling {
    /// 凭据只匹配它创建时的请求；旧凭据不能关闭同路由的新页面。
    func dismiss(lifetime: NavigationPresentationLifetime) -> NavigationPresentationResult {
        withPresentationMutation {
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
                        scheduleFinish(lifetime)
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
}

extension NavigationRouter {
    /// 关闭、外部导航和 FIFO 都先提交状态，再允许完成通知重新进入 Router。
    func withPresentationMutation<Result>(_ mutation: () -> Result) -> Result {
        presentationMutationDepth += 1
        defer {
            presentationMutationDepth -= 1
            deliverPresentationFinishes()
        }
        return mutation()
    }

    func scheduleFinish(_ lifetime: NavigationPresentationLifetime) {
        guard !lifetime.finished, !pendingPresentationFinishes.contains(where: { $0 === lifetime }) else { return }
        pendingPresentationFinishes.append(lifetime)
    }

    /// 删除尚未展示的队列不需要等待页面关闭；它们可能从未创建过 View。
    func discardQueuedPresentations(in layer: NavigationLayer<Scope, Destination, AlertRoute>) {
        let queued = layer.queuedPresentations
        layer.queuedPresentations.removeAll()
        for content in queued {
            finish(content)
        }
    }

    /// 关闭祖先时，尚未交给系统的后代无需先显示；已认领的 alert 仍保留真实完成门。
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
                // 祖先已在关闭时仍可取消尚未交宿主的子请求，但不能代替根层完成外部导航。
                layer.dismissingPresentation = nil
                layer.isAwaitingDismissal = false
                finish(.page(node))
            }
        }
    }

    /// 使用发起层及确切请求身份接收系统 completion，拒绝迟到通知结束后来打开的页面。
    func completePresentationDismissal(
        in layer: NavigationLayer<Scope, Destination, AlertRoute>,
        lifetime: NavigationPresentationLifetime
    ) {
        withPresentationMutation {
            guard lifetimeLayers.contains(where: { $0 === layer }) else { return }
            if let active = layer.presentation, active.lifetime === lifetime {
                // UIKit 可以直接关闭而不先回写 SwiftUI Binding；只有匹配身份的真实通知可补齐这一步。
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
    }

    /// 真实关闭已发生但后代动作尚未完成时，保留原关闭事务；动作完成后再统一释放和导航。
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

    /// 根完成会同时结束其仍在关闭的后代；节点保留到这里，再解除全部内部拥有关系。
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
            if let lifetime = layer.alertSession?.lifetime { scheduleFinish(lifetime) }
            layer.alertSession = nil
        }
        scheduleFinish(content.lifetime)
    }

    /// Router 退出不能伪造系统关闭。已交宿主的请求由宿主持有，等待真实完成通知。
    func finishUnhostedPresentationsForTeardown() {
        preserveDetachedCompletionDependencies(in: rootLayer)
        func finishUnhosted(in layer: NavigationLayer<Scope, Destination, AlertRoute>) {
            let contents = [layer.presentedContent, layer.dismissingPresentation.map(NavigationPresentation.page)]
                .compactMap(\.self) + layer.queuedPresentations
            for content in contents {
                if case let .page(node) = content {
                    finishUnhosted(in: node.layer)
                    if node.didCompletePhysicalDismissal { scheduleFinish(node.lifetime) }
                }
                if !content.lifetime.hostClaimed { scheduleFinish(content.lifetime) }
            }
        }
        withPresentationMutation { finishUnhosted(in: rootLayer) }
    }

    /// 只复制仍在关闭的请求身份关系；Context 和 UIKit completion 不需要保活 Router。
    private func preserveDetachedCompletionDependencies(in layer: NavigationLayer<Scope, Destination, AlertRoute>) {
        for node in [layer.presentation, layer.dismissingPresentation].compactMap(\.self) {
            preserveDetachedCompletionDependencies(in: node.layer)
            let children = [node.layer.presentation, node.layer.dismissingPresentation].compactMap(\.self)
            node.lifetime.preserveDetachedChildren(
                pages: children.map(\.lifetime), alert: node.layer.alertSession?.completionLifetime
            )
        }
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

    private func deliverPresentationFinishes() {
        guard presentationMutationDepth == 0, !isDeliveringPresentationFinishes else { return }
        isDeliveringPresentationFinishes = true
        defer { isDeliveringPresentationFinishes = false }
        while !pendingPresentationFinishes.isEmpty {
            pendingPresentationFinishes.removeFirst().finish()
        }
    }
}
