import Foundation

// swiftformat:disable modifierOrder
/// 一次页面模态呈现的身份，不能用于业务提示或导航确认。
nonisolated public struct NavigationPresentationID: Hashable, Sendable {
    private let rawValue: UUID

    public init() {
        rawValue = UUID()
    }

    init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}
