@testable import ChineseCalendarUI
import Testing

@Test func monthNavigationSubtitleShowsOnlyCivilDateRangeWhenAvailable() {
    let dateRange = "公元前 221-01-01 – 221-01-28"

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
        in: [
            (dayIndex: 101, julianDayNumber: 2_461_041),
            (dayIndex: 102, julianDayNumber: 2_461_042),
            (dayIndex: 103, julianDayNumber: 2_461_043)
        ],
        todayJulianDayNumber: 2_461_042
    )

    #expect(selectedDayIndex == 102)
}

@Test func defaultDaySelectionUsesFirstDayWhenTodayIsOutsideTheMonth() {
    let selectedDayIndex = LunarMonthGrid.defaultDayIndex(
        in: [
            (dayIndex: 101, julianDayNumber: 2_461_041),
            (dayIndex: 102, julianDayNumber: 2_461_042),
            (dayIndex: 103, julianDayNumber: 2_461_043)
        ],
        todayJulianDayNumber: 2_461_099
    )

    #expect(selectedDayIndex == 101)
}

@Test func defaultDaySelectionIsNilForAnEmptyMonth() {
    let selectedDayIndex = LunarMonthGrid.defaultDayIndex(
        in: [],
        todayJulianDayNumber: 2_461_042
    )

    #expect(selectedDayIndex == nil)
}
