import ChineseCalendarCore
import Foundation
import Observation

/// 向日历功能子树提供随本地民用日期更新的“今天”。
@MainActor
@Observable
final class CalendarToday {
    private(set) var julianDayNumber: Int

    init(date: Date = .now) {
        julianDayNumber = JulianDayNumber.forLocalGregorianDate(containing: date)
    }

    func refresh(date: Date = .now) {
        julianDayNumber = JulianDayNumber.forLocalGregorianDate(containing: date)
    }
}
