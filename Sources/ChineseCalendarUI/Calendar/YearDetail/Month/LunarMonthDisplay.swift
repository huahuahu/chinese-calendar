import ChineseCalendarCore
import ChineseCalendarPersistence

enum LunarMonthDisplay {
    static func title(for month: ChineseLunarMonth) -> String {
        LunarCalendarFormatting.monthTitle(
            monthNumberInYear: month.monthNumberInYear,
            isLeapMonth: month.isLeapMonth,
            intercalaryMonthNameStyle: month.intercalaryMonthNameStyle,
            dayCount: month.dayCount
        )
    }
}
