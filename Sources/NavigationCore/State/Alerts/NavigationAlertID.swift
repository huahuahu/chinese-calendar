import Foundation

// swiftformat:disable modifierOrder
/// 一次业务提示的身份，不能用于页面模态或导航确认。
nonisolated public struct NavigationAlertID: Hashable, Sendable {
    private let rawValue: UUID

    public init() {
        rawValue = UUID()
    }

    init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}
