@testable import ChineseCalendarCore
import Testing

@Test(
    "年份标题将天文学纪年转换为没有公元 0 年的历史纪年",
    arguments: [
        (-220, "公元前 221 年"),
        (-1, "公元前 2 年"),
        (0, "公元前 1 年"),
        (1, "公元 1 年"),
        (2026, "公元 2026 年"),
    ]
)
func yearTitleUsesHistoricalEra(lunarYearNumber: Int, expectedTitle: String) {
    #expect(LunarCalendarFormatting.yearTitle(lunarYearNumber: lunarYearNumber) == expectedTitle)
}

@Test func monthTitleIncludesLunarMonthSizeWhenKnown() {
    #expect(LunarCalendarFormatting.monthTitle(monthNumberInYear: 8, isLeapMonth: true, dayCount: 30) == "闰八月大")
    #expect(LunarCalendarFormatting.monthTitle(monthNumberInYear: 8, isLeapMonth: false, dayCount: 29) == "八月小")
}

@Test func monthTitleUsesPostMonthStyleForZhuanxuIntercalaryMonth() {
    #expect(LunarCalendarFormatting.monthTitle(
        monthNumberInYear: 9,
        isLeapMonth: true,
        intercalaryMonthNameStyle: .post,
        dayCount: 30
    ) == "后九月大")
}

@Test func dayTitleUsesLunarDayNameOnly() {
    #expect(LunarCalendarFormatting.dayTitle(dayNumberInMonth: 1) == "初一")
    #expect(LunarCalendarFormatting.dayTitle(dayNumberInMonth: 31) == "31日")
}

@Test func civilDateTitleIncludesYearOnFirstDayOfCivilYear() {
    #expect(LunarCalendarFormatting.civilDateTitle(
        year: 2026,
        month: 1,
        dayOfMonth: 1,
        isJulianCalendar: false
    ) == "2026/1/1")
    #expect(LunarCalendarFormatting.civilDateTitle(
        year: 2026,
        month: 1,
        dayOfMonth: 1,
        isJulianCalendar: true
    ) == "儒略 2026/1/1")
    #expect(LunarCalendarFormatting.civilDateTitle(
        year: 2026,
        month: 5,
        dayOfMonth: 24,
        isJulianCalendar: false
    ) == "5/24")
}
