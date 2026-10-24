import Foundation

extension NavigationRouter {
    /// 从当前最上层页面展示业务提示；页面自己的操作应优先使用环境中的 NavigationPresentationContext。
    @discardableResult
    func submitAlert(_ destination: AlertRoute) -> NavigationPresentationResult {
        let context = frontmostPresentationNode.map { presentationContext(for: $0) } ?? rootPresentation
        return context.submitAlert(destination)
    }

    /// 是否有业务提示、导航提示或尚未结束的提示关闭／动作处理。
    var hasActiveAlert: Bool {
        lifetimeLayers.contains { $0.alert != nil || $0.alertSession != nil }
    }
}

extension NavigationRouter {
    var layers: [NavigationLayer<Scope, Destination, AlertRoute>] {
        [rootLayer] + presentations.map(\.layer)
    }

    var hasBusinessAlert: Bool {
        lifetimeLayers.contains { layer in
            if layer.alert != nil { return true }
            if case .business = layer.alertSession?.id { return true }
            return false
        }
    }

    /// 同层已有 alert 时保存数据，待系统关闭及业务动作完成后继续；已有页面模态时拒绝。
    func enqueue(
        _ content: NavigationPresentation<Scope, Destination, AlertRoute>,
        in layer: NavigationLayer<Scope, Destination, AlertRoute>
    ) -> NavigationPresentationResult {
        guard self.layer(id: layer.id) === layer else {
            return .rejected(.inactiveContext)
        }
        guard layer.presentation == nil else {
            return .rejected(.presentationAlreadyExists)
        }
        let mustWait = layer.alert != nil || layer.alertSession != nil || layer.isAwaitingDismissal ||
            isAwaitingPresentationDismissal || pendingConfirmation != nil
        if mustWait {
            layer.queuedPresentations.append(content)
            return .queued
        }
        guard !hasActiveAlert else {
            return .rejected(.alertInProgress)
        }
        layer.presentedContent = content
        return .applied
    }

    /// 尝试继续排队的操作；只要还有活动 alert（包括关闭动画和按钮动作）就返回。
    /// 先执行延后的模态关闭，再展示排队内容，最后重新提交等待 alert 的导航请求。
    func resumePresentations() {
        resumeQueuedPresentations()
    }

    private func resumeQueuedPresentations() {
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
        if pendingConfirmation == nil {
            for layer in layers.reversed() where layer.presentedContent == nil && !layer.isAwaitingDismissal {
                if !layer.queuedPresentations.isEmpty {
                    layer.presentedContent = layer.queuedPresentations.removeFirst()
                    NavigationCoreLog.record(
                        NavigationPresentationResult.applied, operation: "resumePresentation", layer: layer.id
                    )
                    return
                }
            }
        }
        guard let request = coordinationState.takeRequestAfterAlert() else { return }
        _ = submit(request.request, confirmIfPresented: request.confirmIfPresented)
    }
}
