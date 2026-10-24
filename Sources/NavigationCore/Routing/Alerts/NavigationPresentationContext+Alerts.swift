extension NavigationPresentationContext {
    /// 显示 alert 前，检查 ID 是否匹配当前 layer 的业务 alert 或 confirmation，并创建 NavigationAlertSession。
    /// context 已失效、ID 不匹配或已有 session 时，返回 nil。
    /// 调用方保留返回的 session，等 alert 关闭且按钮的异步操作完成后，再调用 completeAlertSession。
    /// 即使原 layer 已被移除，仍可通过该 session 完成本次 presentation 的结束通知。
    func claimAlertSession(id: NavigationSystemAlertID) -> NavigationAlertSession? {
        guard isActive, let layer, layer.alertSession == nil else { return nil }
        let lifetime: NavigationPresentationLifetime?
        switch id {
        case let .business(alertID):
            guard let alert = presentedAlert, alert.id == alertID else { return nil }
            lifetime = alert.lifetime
        case let .confirmation(confirmationID):
            guard confirmation?.id == confirmationID else { return nil }
            lifetime = nil
        }
        lifetime?.claimHost()
        let session = NavigationAlertSession(id: id, lifetime: lifetime)
        layer.alertSession = session
        return session
    }

    func alertWillDismiss(id: NavigationSystemAlertID) {
        guard let layer, let session = layer.alertSession, session.id == id else { return }
        session.beginDismissal()
        if case let .business(alertID) = id, layer.alert?.id == alertID { layer.presentedContent = nil }
    }

    /// alert 关闭且按钮的异步操作完成后调用；只结束传入的 session，不清除后来创建的新 session。
    func completeAlertSession(_ session: NavigationAlertSession) {
        guard session.endCompletion() else { return }
        let completion = session.lifetime?.takeOnDismiss()
        defer { completion?() }
        guard let router, let layer, layer.alertSession === session else {
            session.lifetime?.finish()
            return
        }
        if case let .business(alertID) = session.id, layer.alert?.id == alertID { layer.presentedContent = nil }
        layer.alertSession = nil
        session.lifetime?.finish()
        if !router.completePendingPresentationDismissals() { router.resumePresentations() }
    }

    /// 保留给按 ID 通知关闭的内部调用；NavigationSystemAlert 直接将保存的 session 传给 completeAlertSession。
    func alertDidDismiss(id: NavigationSystemAlertID) {
        guard let session = layer?.alertSession, session.id == id else { return }
        completeAlertSession(session)
    }

    func beginAlertCompletion(id: NavigationSystemAlertID) -> Bool {
        guard let session = layer?.alertSession, session.id == id else { return false }
        return session.beginCompletion()
    }
}
