import Foundation

// swiftformat:disable modifierOrder
/// 一次页面模态呈现的身份，不能用于业务提示或导航确认。
nonisolated struct NavigationPresentationID: Hashable {
    private let rawValue: UUID

    init() {
        rawValue = UUID()
    }

    init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}
