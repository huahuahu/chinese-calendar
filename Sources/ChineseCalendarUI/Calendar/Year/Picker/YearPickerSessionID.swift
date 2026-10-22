import Foundation

/// 一次年份选择会话的身份，不与页面模态或其他业务会话共用。
nonisolated struct YearPickerSessionID: Hashable, CustomStringConvertible {
    private let rawValue: UUID

    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }

    var description: String {
        rawValue.uuidString
    }
}
