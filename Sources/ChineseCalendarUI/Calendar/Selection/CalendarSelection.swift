import Observation

/// 日历功能唯一的共享业务选择；月份或日期都沿真实模型关系推导所属年月。
@MainActor
@Observable
final class CalendarSelection {
    private(set) var value: CalendarSelectionValue?

    var selectedDayIndex: Int? {
        value?.dayIndex
    }

    init(selectedDayIndex: Int? = nil) {
        value = selectedDayIndex.map { .day(index: $0) }
    }

    init(value: CalendarSelectionValue?) {
        self.value = value
    }

    func select(_ value: CalendarSelectionValue?) {
        self.value = value
    }

    func select(dayIndex: Int?) {
        select(dayIndex.map { .day(index: $0) })
    }
}
