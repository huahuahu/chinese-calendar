import Observation

/// 日历功能唯一的共享业务选择；年月均由这个日序对应的模型关系推导。
@MainActor
@Observable
final class CalendarSelection {
    private(set) var selectedDayIndex: Int?

    init(selectedDayIndex: Int? = nil) {
        self.selectedDayIndex = selectedDayIndex
    }

    func select(dayIndex: Int?) {
        selectedDayIndex = dayIndex
    }
}
