import Foundation

public extension NavigationRouter {
    /// 从当前最上层页面展示业务提示；页面自己的操作应优先使用环境中的呈现 Context。
    @discardableResult
    func presentAlert(_ destination: AlertRoute) -> Bool {
        let context = frontmostPresentationNode.map { presentationContext(for: $0) } ?? rootPresentation
        return context.presentAlert(destination)
    }

    /// 是否有业务提示、导航提示或尚未结束的提示关闭／动作处理。
    var hasActiveAlert: Bool {
        layers.contains { $0.alert != nil || $0.alertSession != nil }
    }

    /// 当前及排队中的业务提示，供业务层保留或释放对应的临时数据，不包含导航确认。
    var alertRoutes: [AlertRoute] {
        layers.flatMap { layer in
            let queued = layer.queuedPresentations.compactMap { content -> AlertRoute? in
                guard case let .alert(node) = content else { return nil }
                return node.destination
            }
            return layer.alert.map { [$0.destination] + queued } ?? queued
        }
    }
}

extension NavigationRouter {
    var layers: [NavigationLayer<Scope, Destination, AlertRoute>] {
        [rootLayer] + presentations.map(\.layer)
    }

    var hasBusinessAlert: Bool {
        layers.contains { layer in
            layer.alert != nil || layer.alertSession?.isConfirmation == false
        }
    }

    /// 同层已有 alert 时保存数据，待系统关闭及业务动作完成后继续；已有页面模态时拒绝。
    func enqueue(
        _ content: NavigationPresentation<Scope, Destination, AlertRoute>,
        in layer: NavigationLayer<Scope, Destination, AlertRoute>
    ) -> Bool {
        guard self.layer(id: layer.id) === layer, layer.presentation == nil else { return false }
        let mustWait = layer.alert != nil || layer.alertSession != nil || layer.isAwaitingDismissal ||
            isAwaitingPresentationDismissal || pendingConfirmation != nil
        if mustWait {
            layer.queuedPresentations.append(content)
            return true
        }
        guard pendingConfirmation == nil, !hasActiveAlert else { return false }
        layer.presentedContent = content
        return true
    }

    /// 只有真实关闭完成后才能调用；业务提示先排完，再重新评估外部导航。
    func resumePresentations() {
        guard !hasActiveAlert else { return }
        if dismissAllWaitingForAlert {
            dismissAllWaitingForAlert = false
            dismissAllPresentations()
        }
        let dismissals = dismissalsWaitingForAlert
        dismissalsWaitingForAlert.removeAll()
        for id in dismissals {
            dismissPresentation(id: id)
        }
        guard !layers.contains(where: \.isAwaitingDismissal) else { return }
        for layer in layers.reversed() where layer.presentedContent == nil && !layer.isAwaitingDismissal {
            if !layer.queuedPresentations.isEmpty {
                layer.presentedContent = layer.queuedPresentations.removeFirst()
                return
            }
        }
        guard let request = requestWaitingForAlert else { return }
        let needsConfirmation = waitingRequestNeedsConfirmation
        requestWaitingForAlert = nil
        waitingRequestNeedsConfirmation = false
        _ = submit(request, confirmIfPresented: needsConfirmation)
    }
}
