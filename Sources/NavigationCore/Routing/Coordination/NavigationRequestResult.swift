// swiftformat:disable modifierOrder

/// 说明 Router.submit 如何处理这次请求。数据更新完成后，SwiftUI 可能仍在更新界面或播放动画。
nonisolated public enum NavigationRequestResult: Equatable, Sendable {
    /// 请求与根层的栈配置不兼容，原状态保持不变。
    /// 例如 Core 自动提供的单栈只接受 primary 目标，其他请求须指向已经声明的栈。
    case rejected(NavigationRejectionReason)
    /// 确认已过期或已处理，不会影响后来的请求。
    case noChange(NavigationNoChangeReason)
    /// 等待用户确认，当前页面和路径保持原样；NavigationAlertHost 根据 pendingConfirmation 显示确认提示。
    case awaitingConfirmation
    /// 请求已写入根层导航数据，SwiftUI 会据此更新界面。
    case applied
    /// 请求已被接受，正在等待根模态关闭完成后执行。
    /// 等待期间收到新的已批准请求时，会改为执行最新的一条。
    case deferredUntilPresentationDismisses
    /// 当前 alert 或它的业务动作尚未结束，暂存导航，之后重新检查是否需要离开确认。
    case deferredUntilAlertDismisses
}
