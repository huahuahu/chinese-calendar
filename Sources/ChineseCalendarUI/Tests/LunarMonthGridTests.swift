@testable import ChineseCalendarUI
import Testing

@Test func monthNavigationSubtitleShowsOnlyCivilDateRangeWhenAvailable() {
    let dateRange = "儒略 -220年1月1日 - 儒略 -220年1月27日"

    let subtitle = LunarMonthGrid.monthNavigationSubtitle(
        civilDateRangeTitle: dateRange,
        fallback: "27天 · 丙寅月"
    )

    #expect(subtitle == dateRange)
    #expect(!subtitle.contains("今天优先选中"))
    #expect(!subtitle.contains("默认选中初一"))
}

@Test func monthNavigationSubtitleUsesMonthSummaryWithoutCivilDates() {
    let subtitle = LunarMonthGrid.monthNavigationSubtitle(
        civilDateRangeTitle: nil,
        fallback: "27天 · 丙寅月"
    )

    #expect(subtitle == "27天 · 丙寅月")
}

@Test func defaultDaySelectionPrefersTodayWhenItBelongsToTheMonth() {
    let selectedDayIndex = LunarMonthGrid.defaultDayIndex(
        in: [101, 102, 103],
        todayDayIndex: 102
    )

    #expect(selectedDayIndex == 102)
}

@Test func defaultDaySelectionUsesFirstDayWhenTodayIsOutsideTheMonth() {
    let selectedDayIndex = LunarMonthGrid.defaultDayIndex(
        in: [101, 102, 103],
        todayDayIndex: 999
    )

    #expect(selectedDayIndex == 101)
}

@Test func defaultDaySelectionIsNilForAnEmptyMonth() {
    let selectedDayIndex = LunarMonthGrid.defaultDayIndex(
        in: [],
        todayDayIndex: 102
    )

    #expect(selectedDayIndex == nil)
}
