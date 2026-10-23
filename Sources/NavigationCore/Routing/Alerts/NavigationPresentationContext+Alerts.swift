extension NavigationPresentationContext {
    /// UIKit 接手时认领会话；来源及 ID 必须匹配本层业务提示或导航确认。
    /// 宿主强持返回对象后，原层离树不会丢失这次系统关闭和业务动作的完成权限。
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

    func alertWillPresent(id: NavigationSystemAlertID) -> Bool {
        claimAlertSession(id: id) != nil
    }

    func alertWillDismiss(id: NavigationSystemAlertID) {
        guard let layer, let session = layer.alertSession, session.id == id else { return }
        session.beginDismissal()
        if case let .business(alertID) = id, layer.alert?.id == alertID { layer.presentedContent = nil }
    }

    /// 必须等 UIKit 关闭和业务异步动作完成；旧会话不会释放后来创建的新会话。
    func completeAlertSession(_ session: NavigationAlertSession) {
        guard session.endCompletion() else { return }
        guard let router, let layer, layer.alertSession === session else {
            session.completionLifetime.finish()
            return
        }
        router.withPresentationMutation {
            if case let .business(alertID) = session.id, layer.alert?.id == alertID { layer.presentedContent = nil }
            layer.alertSession = nil
            router.scheduleFinish(session.completionLifetime)
            if !router.completePendingPresentationDismissals() { router.resumePresentations() }
        }
    }

    /// 内部兼容入口；真实宿主持有明确的 session，不依赖 Context 再查找完成权限。
    func alertDidDismiss(id: NavigationSystemAlertID) {
        guard let session = layer?.alertSession, session.id == id else { return }
        completeAlertSession(session)
    }

    func beginAlertCompletion(id: NavigationSystemAlertID) -> Bool {
        guard let session = layer?.alertSession, session.id == id else { return false }
        return session.beginCompletion()
    }
}
