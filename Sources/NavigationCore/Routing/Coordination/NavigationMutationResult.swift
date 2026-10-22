// swiftformat:disable modifierOrder

/// 同步导航数据修改的结果，不代表 SwiftUI 已完成更新或动画。
nonisolated public enum NavigationMutationResult: Equatable, Sendable {
    /// 已接受并应用；重复写入相同合法值也属于此结果。
    case applied
    case noChange(NavigationNoChangeReason)
    case rejected(NavigationRejectionReason)

    /// 需要同步修改业务状态时，先确认导航数据已经应用。
    public var isApplied: Bool {
        self == .applied
    }
}
