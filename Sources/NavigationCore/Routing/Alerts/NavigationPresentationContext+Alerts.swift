extension NavigationPresentationContext {
    /// 宿主准备展示时占用本层提示，后续提示等待它真正关闭。
    /// 来源和 ID 必须同时匹配本层业务提示或待处理的导航确认。
    func alertWillPresent(id: NavigationSystemAlertID) -> Bool {
        guard isActive, let layer, layer.alertSession == nil else { return false }
        switch id {
        case let .business(alertID):
            guard presentedAlert?.id == alertID else { return false }
        case let .confirmation(confirmationID):
            guard confirmation?.id == confirmationID else { return false }
        }
        layer.alertSession = NavigationAlertSession(id: id)
        return true
    }

    func alertWillDismiss(id: NavigationSystemAlertID) {
        guard isActive, let layer, let session = layer.alertSession,
              session.id == id, session.state == .presented else { return }
        layer.alertSession?.state = .dismissing
        if case let .business(alertID) = id, layer.alert?.id == alertID { layer.presentedContent = nil }
    }

    /// 仅从 handlingCompletion 释放会话；宿主须等待业务动作结束后调用。
    /// 提前、重复或过期回调不能推进后续提示与导航。
    func alertDidDismiss(id: NavigationSystemAlertID) {
        guard isActive, let layer, let session = layer.alertSession,
              session.id == id, session.state == .handlingCompletion else { return }
        if case let .business(alertID) = id, layer.alert?.id == alertID { layer.presentedContent = nil }
        layer.alertSession = nil
        router?.resumePresentations()
    }

    /// UIKit 关闭完成后，仅从 dismissing 取得一次处理权，避免重复执行业务动作。
    func beginAlertCompletion(id: NavigationSystemAlertID) -> Bool {
        guard isActive, let layer, let session = layer.alertSession,
              session.id == id, session.state == .dismissing else { return false }
        layer.alertSession?.state = .handlingCompletion
        return true
    }
}
