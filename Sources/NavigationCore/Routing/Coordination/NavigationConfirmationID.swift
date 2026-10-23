import Foundation

// swiftformat:disable modifierOrder
/// 一次导航离开确认的身份，不能用于页面模态或业务提示。
nonisolated public struct NavigationConfirmationID: Hashable, Sendable {
    private let rawValue: UUID

    public init() {
        rawValue = UUID()
    }

    init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}
