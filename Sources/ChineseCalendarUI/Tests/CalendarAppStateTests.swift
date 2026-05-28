@testable import ChineseCalendarUI
import Testing

@MainActor
@Suite("Calendar app state")
struct CalendarAppStateTests {
    @Test("route selection updates lunar child state")
    func routeSelectionUpdatesLunarChildState() {
        let state = CalendarAppState(
            route: .lunarYear(2024),
            selectedMonthIndex: 12,
            selectedDayIndex: 345
        )

        state.route = .lunarYear(2025)

        #expect(state.selectedYearNumber == 2025)
        #expect(state.lunarSelection.selectedYearNumber == 2025)
        #expect(state.selectedMonthIndex == nil)
        #expect(state.selectedDayIndex == nil)
    }

    @Test("lunar selection updates route")
    func lunarSelectionUpdatesRoute() {
        let state = CalendarAppState()

        state.selectLunarYear(number: 2025)

        #expect(state.route == .lunarYear(2025))
        #expect(state.lunarSelection.selectedYearNumber == 2025)
    }

    @Test("dynasty selection updates dynasty child state and route")
    func dynastySelectionUpdatesDynastyChildStateAndRoute() {
        let state = CalendarAppState()

        state.selectDynasty(id: "ming")

        #expect(state.route == .dynasty("ming"))
        #expect(state.selectedDynastyID == "ming")
        #expect(state.dynastySelection.selectedDynastyID == "ming")
    }

    @Test("default year selection keeps app route synchronized")
    func defaultYearSelectionKeepsAppRouteSynchronized() {
        let state = CalendarAppState()

        let selectedYearNumber = state.selectDefaultYearIfNeeded(
            from: [2024, 2025, 2026],
            fallbackYearNumber: 2025
        )

        #expect(selectedYearNumber == 2025)
        #expect(state.route == .lunarYear(2025))
        #expect(state.lunarSelection.selectedYearNumber == 2025)
    }

    @Test("default year selection preserves dynasty route")
    func defaultYearSelectionPreservesDynastyRoute() {
        let state = CalendarAppState(route: .dynasty("ming"))

        let selectedYearNumber = state.selectDefaultYearIfNeeded(
            from: [2024, 2025, 2026],
            fallbackYearNumber: 2025
        )

        #expect(selectedYearNumber == 2025)
        #expect(state.route == .dynasty("ming"))
        #expect(state.lunarSelection.selectedYearNumber == 2025)
    }
}
