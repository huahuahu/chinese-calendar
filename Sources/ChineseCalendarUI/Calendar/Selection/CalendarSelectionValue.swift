/// 日历当前浏览位置；月份与日期互斥，避免维护彼此可能矛盾的年月日状态。
enum CalendarSelectionValue: Equatable {
    case month(index: Int)
    case day(index: Int)

    var dayIndex: Int? {
        guard case let .day(index) = self else { return nil }
        return index
    }
}
