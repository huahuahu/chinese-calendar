import Foundation
import SwiftData

@Model
public final class CivilDate {
    #Unique<CivilDate>([\.dayIndex], [\.year, \.month, \.dayOfMonth, \.calendarStyle])

    public var dayIndex: Int
    public var year: Int
    public var month: Int
    public var dayOfMonth: Int
    public var calendarStyle: CivilCalendarStyle

    /// Inverse side of CalendarDay.civilDate.
    public var calendarDay: CalendarDay?

    public init(
        dayIndex: Int,
        year: Int,
        month: Int,
        dayOfMonth: Int,
        calendarStyle: CivilCalendarStyle,
        calendarDay: CalendarDay? = nil
    ) {
        self.dayIndex = dayIndex
        self.year = year
        self.month = month
        self.dayOfMonth = dayOfMonth
        self.calendarStyle = calendarStyle
        self.calendarDay = calendarDay
    }
}
