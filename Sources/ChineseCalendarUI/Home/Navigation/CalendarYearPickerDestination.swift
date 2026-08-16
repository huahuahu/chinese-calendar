import Foundation

/// 年份选择页面的初始输入与选择结果回调。
struct CalendarYearPickerDestination: Hashable, Identifiable {
    let id: UUID
    let initialYearNumber: Int?
    private let onSelect: (Int) -> Void

    init(
        id: UUID = UUID(),
        initialYearNumber: Int?,
        onSelect: @escaping (Int) -> Void
    ) {
        self.id = id
        self.initialYearNumber = initialYearNumber
        self.onSelect = onSelect
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func select(_ yearNumber: Int) {
        onSelect(yearNumber)
    }
}
