import Foundation
import SwiftData

@Model
public final class CivilDate {
    #Unique<CivilDate>([\.dayIndex], [\.year, \.month, \.dayOfMonth, \.calendarStyleRawValue])

    public var dayIndex: Int
    public var year: Int
    public var month: Int
    public var dayOfMonth: Int
    public var calendarStyleRawValue: String

    public var calendarStyle: CivilCalendarStyle {
        get { CivilCalendarStyle(rawValue: calendarStyleRawValue) ?? .gregorian }
        set { calendarStyleRawValue = newValue.rawValue }
    }

    /// 此民用日期对应的绝对日期记录，可继续通过它读取农历日期；与 CalendarDay.civilDate 互为反向关系。
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
        calendarStyleRawValue = calendarStyle.rawValue
        self.calendarDay = calendarDay
    }
}
