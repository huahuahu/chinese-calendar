import Foundation
import SwiftData

@Model
public final class ChineseLunarDay {
    #Unique<ChineseLunarDay>([\.dayIndex], [\.chineseLunarMonth, \.dayNumberInMonth])

    public var dayIndex: Int
    public var dayNumberInMonth: Int
    public var dayStemIndex: Int
    public var dayBranchIndex: Int

    /// 此农历日对应的绝对日期记录，可继续通过它读取民用日期；与 CalendarDay.chineseLunarDay 互为反向关系。
    public var calendarDay: CalendarDay?

    /// 此日所属的农历月，对应 ChineseLunarMonth.days 中的这条日记录。
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
