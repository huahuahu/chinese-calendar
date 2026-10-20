/// 说明 Router.submit 如何处理这次请求。数据更新完成后，SwiftUI 可能仍在更新界面或播放动画。
public enum NavigationRequestResult: Equatable, Sendable {
    /// 目标不允许出现在该入口，或请求了尚未支持的容器；原状态保持不变。
    case rejected
    /// 等待用户确认，当前页面和路径保持原样。提示容器或业务代码需处理 pendingConfirmation。
    case awaitingConfirmation
    /// 请求已写入根层导航数据，SwiftUI 会据此更新界面。
    case applied
    /// 请求已被接受，正在等待根模态关闭完成后执行。
    /// 等待期间收到新的已批准请求时，会改为执行最新的一条。
    case deferredUntilPresentationDismisses
    /// 当前 alert 或它的业务动作尚未结束，暂存导航，之后重新检查是否需要离开确认。
    case deferredUntilAlertDismisses
}
