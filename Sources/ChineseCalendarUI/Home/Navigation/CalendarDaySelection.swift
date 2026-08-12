import Observation

/// 将日期选择隔离成可单独观察的状态，避免日期变化使整个日历导航容器失效。
@MainActor
@Observable
final class CalendarDaySelection {
    var dayIndex: Int?

    init(dayIndex: Int? = nil) {
        self.dayIndex = dayIndex
    }
}
