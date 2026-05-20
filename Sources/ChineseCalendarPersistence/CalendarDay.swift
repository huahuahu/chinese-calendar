import Foundation
import SwiftData

@Model
public final class CalendarDay {
    #Unique<CalendarDay>([\.dayIndex], [\.julianDayNumber])

    public var dayIndex: Int
    public var julianDayNumber: Int

    /// One-to-one owner side for the civil expression of this absolute day.
    @Relationship(deleteRule: .cascade, inverse: \CivilDate.calendarDay)
    public var civilDate: CivilDate?

    /// One-to-one owner side for the lunar expression of this absolute day.
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
