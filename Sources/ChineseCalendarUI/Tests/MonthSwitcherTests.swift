@testable import ChineseCalendarUI
import Testing

@Test func julianDayRangeUsesAvailableExtremesRegardlessOfOrder() {
    let range = MonthSwitcher.julianDayRange(
        in: [nil, 2_460_900, 2_460_898, nil, 2_460_899]
    )

    #expect(range == 2_460_898 ... 2_460_900)
}

@Test func julianDayRangeIsAbsentWithoutCivilDates() {
    #expect(MonthSwitcher.julianDayRange(in: [nil, nil]) == nil)
}

@Test func monthNavigationSubtitleShowsOnlyCivilDateRangeWhenAvailable() {
    let dateRange = "公元前 221-01-01 – 221-01-28"

    let subtitle = MonthSwitcher.monthNavigationSubtitle(
        civilDateRangeTitle: dateRange,
        fallback: "27天 · 丙寅月"
    )

    #expect(subtitle == dateRange)
    #expect(!subtitle.contains("今天优先选中"))
    #expect(!subtitle.contains("默认选中初一"))
}

@Test func monthNavigationSubtitleUsesMonthSummaryWithoutCivilDates() {
    let subtitle = MonthSwitcher.monthNavigationSubtitle(
        civilDateRangeTitle: nil,
        fallback: "27天 · 丙寅月"
    )

    #expect(subtitle == "27天 · 丙寅月")
}
