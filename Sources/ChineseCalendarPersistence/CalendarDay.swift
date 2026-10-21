import Foundation
import SwiftData

@Model
public final class CalendarDay {
    #Unique<CalendarDay>([\.dayIndex], [\.julianDayNumber])

    public var dayIndex: Int
    public var julianDayNumber: Int

    /// 同一天的民用日期表示，与 CivilDate.calendarDay 互为一对一关系；删除此 CalendarDay 时级联删除它。
    @Relationship(deleteRule: .cascade, inverse: \CivilDate.calendarDay)
    public var civilDate: CivilDate?

    /// 同一天的农历日期表示，与 ChineseLunarDay.calendarDay 互为一对一关系；删除此 CalendarDay 时级联删除它。
    @Relationship(deleteRule: .cascade, inverse: \ChineseLunarDay.calendarDay)
    public var chineseLunarDay: ChineseLunarDay?

    public init(
        dayIndex: Int,
        julianDayNumber: Int,
        civilDate: CivilDate? = nil,
        chineseLunarDay: ChineseLunarDay? = nil
    ) {
        self.dayIndex = dayIndex
        self.julianDayNumber = julianDayNumber
        self.civilDate = civilDate
        self.chineseLunarDay = chineseLunarDay
    }
}
