import ChineseCalendarCore
import Foundation

public protocol CalendarDataRepository: Sendable {
    func calendarDate(for gregorianDate: Date) async throws -> ChineseCalendarDate?
}

public struct PlaceholderCalendarDataRepository: CalendarDataRepository {
    public init() {}

    public func calendarDate(for gregorianDate: Date) async throws -> ChineseCalendarDate? {
        ChineseCalendarDate(
            gregorianDate: gregorianDate,
            lunarYear: 2026,
            lunarMonth: 1,
            lunarDay: 1,
            isLeapMonth: false
        )
    }
}
