import Foundation
import SwiftData

@Model
public final class CivilDateRecord {
    #Unique<CivilDateRecord>([\.dayIndex])

    public var dayIndex: Int
    public var year: Int
    public var month: Int
    public var day: Int
    public var calendarStyle: CivilCalendarStyle

    public var chineseCalendarDay: ChineseCalendarDay?

    public init(
        dayIndex: Int,
        year: Int,
        month: Int,
        day: Int,
        calendarStyle: CivilCalendarStyle,
        chineseCalendarDay: ChineseCalendarDay? = nil
    ) {
        self.dayIndex = dayIndex
        self.year = year
        self.month = month
        self.day = day
        self.calendarStyle = calendarStyle
        self.chineseCalendarDay = chineseCalendarDay
    }
}
