@testable import ChineseCalendarUI
import Testing

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
