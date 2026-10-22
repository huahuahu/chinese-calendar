import Foundation

public extension NavigationRouter {
    /// 从当前最上层页面展示业务提示；页面自己的操作应优先使用环境中的 NavigationPresentationContext。
    @discardableResult
    func presentAlert(_ destination: AlertRoute) -> NavigationPresentationResult {
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
            if layer.alert != nil { return true }
            if case .business = layer.alertSession?.id { return true }
            return false
        }
    }

    /// 同层已有 alert 时保存数据，待系统关闭及业务动作完成后继续；已有页面模态时拒绝。
    func enqueue(
        _ content: NavigationPresentation<Scope, Destination, AlertRoute>,
        in layer: NavigationLayer<Scope, Destination, AlertRoute>,
        operation: String = "present"
    ) -> NavigationPresentationResult {
        guard self.layer(id: layer.id) === layer else {
            return NavigationCoreLog.record(
                NavigationPresentationResult.rejected(.inactiveContext), operation: operation, layer: layer.id
            )
        }
        guard layer.presentation == nil else {
            return NavigationCoreLog.record(
                NavigationPresentationResult.rejected(.presentationAlreadyExists), operation: operation, layer: layer.id
            )
        }
        let mustWait = layer.alert != nil || layer.alertSession != nil || layer.isAwaitingDismissal ||
            isAwaitingPresentationDismissal || pendingConfirmation != nil
        if mustWait {
            layer.queuedPresentations.append(content)
            return NavigationCoreLog.record(
                NavigationPresentationResult.queued, operation: operation, layer: layer.id
            )
        }
        guard !hasActiveAlert else {
            return NavigationCoreLog.record(
                NavigationPresentationResult.rejected(.alertInProgress), operation: operation, layer: layer.id
            )
        }
        layer.presentedContent = content
        return NavigationCoreLog.record(NavigationPresentationResult.applied, operation: operation, layer: layer.id)
    }

    /// 尝试继续排队的操作；只要还有活动 alert（包括关闭动画和按钮动作）就返回。
    /// 先执行延后的模态关闭，再展示排队内容，最后重新提交等待 alert 的导航请求。
    func resumePresentations() {
        guard !hasActiveAlert else { return }
        switch coordinationState.takeDismissalAfterAlert() {
        case .none:
            break
        case .all:
            dismissAllPresentations()
        case let .presentations(ids):
            for id in ids {
                dismissPresentation(id: id)
            }
        }
        guard !layers.contains(where: \.isAwaitingDismissal) else { return }
        for layer in layers.reversed() where layer.presentedContent == nil && !layer.isAwaitingDismissal {
            if !layer.queuedPresentations.isEmpty {
                layer.presentedContent = layer.queuedPresentations.removeFirst()
                NavigationCoreLog.record(
                    NavigationPresentationResult.applied, operation: "resumePresentation", layer: layer.id
                )
                return
            }
        }
        guard let request = coordinationState.takeRequestAfterAlert() else { return }
        _ = submit(request.request, confirmIfPresented: request.confirmIfPresented)
    }
}
