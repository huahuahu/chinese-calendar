// swiftformat:disable modifierOrder

/// 页面／alert 的呈现或关闭结果，区分立即修改数据与排队等待。
nonisolated public enum NavigationPresentationResult: Equatable, Sendable {
    /// 数据已经应用，界面呈现或关闭动画可能仍未完成。
    case applied
    /// 请求已排队；所属层失效时可能丢弃，不保证最终展示或关闭。
    case queued
    case noChange(NavigationNoChangeReason)
    case rejected(NavigationRejectionReason)

    /// 表示立即应用或已排队，不表示界面已经完成操作。
    public var isAccepted: Bool {
        switch self {
        case .applied, .queued: true
        case .noChange, .rejected: false
        }
    }
}
