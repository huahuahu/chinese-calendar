@testable import ChineseCalendarCore
import Testing

@Test func monthTitleIncludesLunarMonthSizeWhenKnown() {
    #expect(LunarCalendarFormatting.monthTitle(monthNumberInYear: 8, isLeapMonth: true, dayCount: 30) == "闰八月大")
    #expect(LunarCalendarFormatting.monthTitle(monthNumberInYear: 8, isLeapMonth: false, dayCount: 29) == "八月小")
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
