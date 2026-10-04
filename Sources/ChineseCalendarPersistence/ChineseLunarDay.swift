import Foundation
import SwiftData

@Model
public final class ChineseLunarDay {
    #Unique<ChineseLunarDay>([\.dayIndex], [\.chineseLunarMonth, \.dayNumberInMonth])

    public var dayIndex: Int
    public var dayNumberInMonth: Int
    public var dayStemIndex: Int
    public var dayBranchIndex: Int

    /// Inverse side of CalendarDay.chineseLunarDay.
    public var calendarDay: CalendarDay?

    /// Inverse side of ChineseLunarMonth.days.
    public var chineseLunarMonth: ChineseLunarMonth?

    public init(
        dayIndex: Int,
        dayNumberInMonth: Int,
        dayStemIndex: Int,
        dayBranchIndex: Int,
        calendarDay: CalendarDay? = nil,
        chineseLunarMonth: ChineseLunarMonth
    ) {
        self.dayIndex = dayIndex
        self.dayNumberInMonth = dayNumberInMonth
        self.dayStemIndex = dayStemIndex
        self.dayBranchIndex = dayBranchIndex
        self.calendarDay = calendarDay
        self.chineseLunarMonth = chineseLunarMonth
    }
}
