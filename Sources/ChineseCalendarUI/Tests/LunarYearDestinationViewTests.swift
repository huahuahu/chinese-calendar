@testable import ChineseCalendarUI
import Testing

@MainActor
@Test func ordinaryYearEntryStartsWithoutMonthOrDayLanding() {
    let browseState = LunarCalendarBrowseState(displayedYearNumber: 2026)

    browseState.applyInitialLanding(monthIndex: nil, dayIndex: nil)

    #expect(browseState.displayedYearNumber == 2026)
    #expect(browseState.selectedMonthIndex == nil)
    #expect(browseState.daySelection.dayIndex == nil)
}

@MainActor
@Test func monthDeepLinkAppliesItsInitialLanding() {
    let browseState = LunarCalendarBrowseState(displayedYearNumber: 2026)

    browseState.applyInitialLanding(monthIndex: 26005, dayIndex: nil)

    #expect(browseState.displayedYearNumber == 2026)
    #expect(browseState.selectedMonthIndex == 26005)
    #expect(browseState.daySelection.dayIndex == nil)
}

@MainActor
@Test func dayDeepLinkAppliesItsMonthAndDayLanding() {
    let browseState = LunarCalendarBrowseState(displayedYearNumber: 2026)

    browseState.applyInitialLanding(
        monthIndex: 26005,
        dayIndex: 2_600_512
    )

    #expect(browseState.displayedYearNumber == 2026)
    #expect(browseState.selectedMonthIndex == 26005)
    #expect(browseState.daySelection.dayIndex == 2_600_512)
}

@MainActor
@Test func rebuildingDestinationDoesNotReapplyItsInitialLanding() {
    let browseState = LunarCalendarBrowseState(displayedYearNumber: 2026)
    browseState.applyInitialLanding(
        monthIndex: 26005,
        dayIndex: 2_600_512
    )
    browseState.select(
        monthIndex: 26006,
        dayIndex: 2_600_603
    )

    browseState.applyInitialLanding(
        monthIndex: 26005,
        dayIndex: 2_600_512
    )

    #expect(browseState.selectedMonthIndex == 26006)
    #expect(browseState.daySelection.dayIndex == 2_600_603)
}
