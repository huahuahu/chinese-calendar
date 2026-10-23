import Foundation

// swiftformat:disable modifierOrder
/// 一次导航离开确认的身份，不能用于页面模态或业务提示。
nonisolated struct NavigationConfirmationID: Hashable {
    private let rawValue: UUID

    init() {
        rawValue = UUID()
    }

    init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}
