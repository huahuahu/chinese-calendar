@testable import ChineseCalendarCore
import Foundation
import Testing

@Test(
    "年份标题将天文学纪年转换为没有公元 0 年的历史纪年",
    arguments: [
        (-220, "公元前 221 年"),
        (-1, "公元前 2 年"),
        (0, "公元前 1 年"),
        (1, "公元 1 年"),
        (2026, "公元 2026 年")
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

@Test func civilDateTitleFollowsLocaleAndIncludesYearOnFirstDayOfCivilYear() {
    #expect(LunarCalendarFormatting.civilDateTitle(
        julianDayNumber: 2_461_042,
        locale: Locale(identifier: "zh_CN")
    ) == "2026/1/1")
    #expect(LunarCalendarFormatting.civilDateTitle(
        julianDayNumber: 2_461_185,
        locale: Locale(identifier: "zh_CN")
    ) == "5/24")
    #expect(LunarCalendarFormatting.civilDateTitle(
        julianDayNumber: 2_461_185,
        locale: Locale(identifier: "en_GB")
    ) == "24/05")
}

@Test func fullCivilDateTitleFollowsLocale() {
    let julianDayNumber = 2_460_000

    #expect(LunarCalendarFormatting.fullCivilDateTitle(
        julianDayNumber: julianDayNumber,
        locale: Locale(identifier: "zh_CN")
    ) == "2023/2/24")
    #expect(LunarCalendarFormatting.fullCivilDateTitle(
        julianDayNumber: julianDayNumber,
        locale: Locale(identifier: "en_US")
    ) == "2/24/2023")
    #expect(LunarCalendarFormatting.fullCivilDateTitle(
        julianDayNumber: julianDayNumber,
        locale: Locale(identifier: "en_US@calendar=islamic")
    ) == "2/24/2023")
}

@Test func gregorianCalendarPreservesThe1582ReformBoundary() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt

    let lastJulianDay = LunarCalendarFormatting.civilDate(fromJulianDayNumber: 2_299_160)
    let firstGregorianDay = LunarCalendarFormatting.civilDate(fromJulianDayNumber: 2_299_161)
    let lastJulianDayComponents = calendar.dateComponents([.year, .month, .day], from: lastJulianDay)
    let firstGregorianDayComponents = calendar.dateComponents([.year, .month, .day], from: firstGregorianDay)

    #expect(lastJulianDayComponents.year == 1582)
    #expect(lastJulianDayComponents.month == 10)
    #expect(lastJulianDayComponents.day == 4)
    #expect(firstGregorianDayComponents.year == 1582)
    #expect(firstGregorianDayComponents.month == 10)
    #expect(firstGregorianDayComponents.day == 15)
}

@Test func civilDateRangeUsesLocalizedIntervalFormatting() {
    let zhTitle = LunarCalendarFormatting.civilDateRangeTitle(
        fromJulianDayNumber: 2_299_160,
        throughJulianDayNumber: 2_299_161,
        locale: Locale(identifier: "zh_CN")
    )
    let enTitle = LunarCalendarFormatting.civilDateRangeTitle(
        fromJulianDayNumber: 2_299_160,
        throughJulianDayNumber: 2_299_161,
        locale: Locale(identifier: "en_US")
    )

    #expect(zhTitle.contains("1582/10/4"))
    #expect(zhTitle.contains("1582/10/15"))
    #expect(enTitle.contains("10/4/1582"))
    #expect(enTitle.contains("10/15/1582"))
    #expect(!zhTitle.contains("儒略"))
    #expect(!zhTitle.contains("公历"))
}

@Test func civilDatesBeforeCommonEraIncludeTheEra() {
    let title = LunarCalendarFormatting.fullCivilDateTitle(
        julianDayNumber: 1_640_703,
        locale: Locale(identifier: "zh_CN")
    )
    let rangeTitle = LunarCalendarFormatting.civilDateRangeTitle(
        fromJulianDayNumber: 1_640_703,
        throughJulianDayNumber: 1_640_730,
        locale: Locale(identifier: "zh_CN")
    )

    #expect(title.contains("公元前"))
    #expect(rangeTitle.contains("公元前"))
}

@Test func civilDateFormattingAlwaysUsesUTC() {
    let date = LunarCalendarFormatting.civilDate(fromJulianDayNumber: 2_440_588)
    var utcCalendar = Calendar(identifier: .gregorian)
    utcCalendar.timeZone = .gmt
    let components = utcCalendar.dateComponents([.hour, .day, .month, .year], from: date)

    #expect(components.year == 1970)
    #expect(components.month == 1)
    #expect(components.day == 1)
    #expect(components.hour == 12)
    #expect(LunarCalendarFormatting.fullCivilDateTitle(
        julianDayNumber: 2_440_588,
        locale: Locale(identifier: "en_US")
    ) == "1/1/1970")
}
