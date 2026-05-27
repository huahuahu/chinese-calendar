import Testing
@testable import ChineseCalendarUI

@MainActor
@Suite("Calendar app state")
struct CalendarAppStateTests {
    @Test("selects fallback year when available")
    func selectsFallbackYearWhenAvailable() {
        let state = CalendarAppState()

        let selectedYearNumber = state.selectDefaultYearIfNeeded(
            from: [2024, 2025, 2026],
            fallbackYearNumber: 2025
        )

        #expect(selectedYearNumber == 2025)
        #expect(state.selectedYearNumber == 2025)
        #expect(state.route == .lunarYear(2025))
    }

    @Test("selects last year when fallback is unavailable")
    func selectsLastYearWhenFallbackIsUnavailable() {
        let state = CalendarAppState()

        let selectedYearNumber = state.selectDefaultYearIfNeeded(
            from: [2024, 2025, 2026],
            fallbackYearNumber: 2030
        )

        #expect(selectedYearNumber == 2026)
        #expect(state.selectedYearNumber == 2026)
    }

    @Test("keeps existing valid year")
    func keepsExistingValidYear() {
        let state = CalendarAppState(route: .lunarYear(2024))

        let selectedYearNumber = state.selectDefaultYearIfNeeded(
            from: [2024, 2025, 2026],
            fallbackYearNumber: 2025
        )

        #expect(selectedYearNumber == nil)
        #expect(state.selectedYearNumber == 2024)
    }

    @Test("clears selected month when route changes")
    func clearsSelectedMonthWhenRouteChanges() {
        let state = CalendarAppState(route: .lunarYear(2024), selectedMonthIndex: 12)

        state.route = .lunarYear(2025)

        #expect(state.selectedYearNumber == 2025)
        #expect(state.selectedMonthIndex == nil)
    }

    @Test("keeps selected month when route is unchanged")
    func keepsSelectedMonthWhenRouteIsUnchanged() {
        let state = CalendarAppState(route: .lunarYear(2024), selectedMonthIndex: 12)

        state.route = .lunarYear(2024)

        #expect(state.selectedMonthIndex == 12)
    }

    @Test("selects adjacent years within bounds")
    func selectsAdjacentYearsWithinBounds() {
        let state = CalendarAppState(route: .lunarYear(2025))
        let yearNumbers = [2024, 2025, 2026]

        #expect(state.canSelectPreviousYear(in: yearNumbers))
        #expect(state.canSelectNextYear(in: yearNumbers))

        state.selectPreviousYear(in: yearNumbers)
        #expect(state.selectedYearNumber == 2024)
        #expect(!state.canSelectPreviousYear(in: yearNumbers))

        state.selectNextYear(in: yearNumbers)
        state.selectNextYear(in: yearNumbers)
        #expect(state.selectedYearNumber == 2026)
        #expect(!state.canSelectNextYear(in: yearNumbers))
    }

    @Test("selects default month and adjacent months")
    func selectsDefaultMonthAndAdjacentMonths() {
        let state = CalendarAppState()
        let monthIndexes = [101, 102, 103]

        state.selectDefaultMonthIfNeeded(from: monthIndexes)
        #expect(state.selectedMonthIndex == 101)

        state.selectNextMonth(in: monthIndexes)
        #expect(state.selectedMonthIndex == 102)

        state.selectPreviousMonth(in: monthIndexes)
        #expect(state.selectedMonthIndex == 101)
        #expect(!state.canSelectPreviousMonth(in: monthIndexes))
    }
}
