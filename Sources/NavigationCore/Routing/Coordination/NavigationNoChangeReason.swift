// swiftformat:disable modifierOrder

/// 命令没有需要执行的动作，不表示导航状态损坏。
nonisolated public enum NavigationNoChangeReason: String, Equatable, Sendable {
    case alreadyAtRoot
    case notPresented
    case presentationNotFound
    case staleConfirmation
    case noSelection
}
