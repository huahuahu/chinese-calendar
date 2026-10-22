import Foundation

/// 提示临时文案的身份，与承载该文案的 alert 节点身份相互独立。
nonisolated struct CalendarAlertMessageID: Hashable {
    private let rawValue: UUID

    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}
