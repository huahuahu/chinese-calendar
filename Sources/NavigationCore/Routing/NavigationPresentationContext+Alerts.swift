import Foundation

extension NavigationPresentationContext {
    /// 宿主准备展示时占用本层提示，后续提示等待它真正关闭。
    func alertWillPresent(id: UUID, isConfirmation: Bool) -> Bool {
        guard isActive, let layer, layer.alertSession == nil else { return false }
        let expectedID = isConfirmation ? confirmation?.id : presentedAlert?.id
        guard expectedID == id else { return false }
        layer.alertSession = NavigationAlertSession(id: id, isConfirmation: isConfirmation)
        return true
    }

    func alertWillDismiss(id: UUID) {
        guard isActive, let layer, layer.alertSession?.id == id else { return }
        layer.alertSession?.isClosing = true
        if layer.alert?.id == id { layer.presentedContent = nil }
    }

    /// 关闭回调和业务动作都结束后，释放本次提示。过期回调不能推进新提示。
    func alertDidDismiss(id: UUID) {
        guard isActive, let layer, layer.alertSession?.id == id else { return }
        if layer.alert?.id == id { layer.presentedContent = nil }
        layer.alertSession = nil
        router?.resumePresentations()
    }

    /// 关闭回调只能处理一次，避免异步按钮动作尚未完成时被重复执行。
    func beginAlertCompletion(id: UUID) -> Bool {
        guard isActive, let layer, let session = layer.alertSession,
              session.id == id, session.isClosing, !session.isHandlingCompletion else { return false }
        layer.alertSession?.isHandlingCompletion = true
        return true
    }
}
