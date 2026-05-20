import Foundation
import SwiftData

@Model
public final class ChineseLunarDay {
    #Unique<ChineseLunarDay>([\.dayIndex], [\.lunarMonthIndex, \.dayNumberInMonth])

    public var dayIndex: Int
    public var lunarMonthIndex: Int
    public var dayNumberInMonth: Int
    public var dayStemIndex: Int
    public var dayBranchIndex: Int

    // Inverse side of CalendarDay.chineseLunarDay.
    public var calendarDay: CalendarDay?

    // Inverse side of ChineseLunarMonth.days.
    public var chineseLunarMonth: ChineseLunarMonth?

    public init(
        dayIndex: Int,
        lunarMonthIndex: Int,
        dayNumberInMonth: Int,
        dayStemIndex: Int,
        dayBranchIndex: Int,
        calendarDay: CalendarDay? = nil,
        chineseLunarMonth: ChineseLunarMonth? = nil
    ) {
        self.dayIndex = dayIndex
        self.lunarMonthIndex = lunarMonthIndex
        self.dayNumberInMonth = dayNumberInMonth
        self.dayStemIndex = dayStemIndex
        self.dayBranchIndex = dayBranchIndex
        self.calendarDay = calendarDay
        self.chineseLunarMonth = chineseLunarMonth
    }
}
