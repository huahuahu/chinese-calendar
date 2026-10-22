import Foundation

extension NavigationPresentationContext {
    /// 宿主准备展示时占用本层提示，后续提示等待它真正关闭。
    /// - Parameter isConfirmation: 仅导航离开确认为 true，此时 id 必须匹配待处理的 NavigationConfirmation。
    ///   业务 alert 即使包含确认按钮也传 false，并使用业务提示的 ID。
    func alertWillPresent(id: UUID, isConfirmation: Bool) -> Bool {
        guard isActive, let layer, layer.alertSession == nil else { return false }
        let expectedID = isConfirmation ? confirmation?.id : presentedAlert?.id
        guard expectedID == id else { return false }
        layer.alertSession = NavigationAlertSession(id: id, isConfirmation: isConfirmation)
        return true
    }

    func alertWillDismiss(id: UUID) {
        guard isActive, let layer, let session = layer.alertSession,
              session.id == id, session.state == .presented else { return }
        layer.alertSession?.state = .dismissing
        if layer.alert?.id == id { layer.presentedContent = nil }
    }

    /// 仅从 handlingCompletion 释放会话；宿主须等待业务动作结束后调用。
    /// 提前、重复或过期回调不能推进后续提示与导航。
    func alertDidDismiss(id: UUID) {
        guard isActive, let layer, let session = layer.alertSession,
              session.id == id, session.state == .handlingCompletion else { return }
        if layer.alert?.id == id { layer.presentedContent = nil }
        layer.alertSession = nil
        router?.resumePresentations()
    }

    /// UIKit 关闭完成后，仅从 dismissing 取得一次处理权，避免重复执行业务动作。
    func beginAlertCompletion(id: UUID) -> Bool {
        guard isActive, let layer, let session = layer.alertSession,
              session.id == id, session.state == .dismissing else { return false }
        layer.alertSession?.state = .handlingCompletion
        return true
    }
}
