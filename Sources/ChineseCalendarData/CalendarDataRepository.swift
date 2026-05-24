import ChineseCalendarCore
import ChineseCalendarLogging
import Foundation

public protocol CalendarDataRepository: Sendable {
    func calendarDate(for gregorianDate: Date) async throws -> ChineseCalendarDate?
}

public struct PlaceholderCalendarDataRepository: CalendarDataRepository {
    public init() {}

    public func calendarDate(for gregorianDate: Date) async throws -> ChineseCalendarDate? {
        ChineseCalendarLog.data.debug("Resolving placeholder calendar date for \(gregorianDate, privacy: .private)")

        return ChineseCalendarDate(
            gregorianDate: gregorianDate,
            lunarYear: 2026,
            lunarMonth: LunarMonth(number: .one),
            lunarDay: .one
        )
    }
}
