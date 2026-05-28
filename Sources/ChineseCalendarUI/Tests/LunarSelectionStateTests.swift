@testable import ChineseCalendarUI
import Testing

@MainActor
@Suite("Lunar selection state")
struct LunarSelectionStateTests {
    @Test("selects fallback year when available")
    func selectsFallbackYearWhenAvailable() {
        let state = LunarSelectionState()

        let selectedYearNumber = state.selectDefaultYearIfNeeded(
            from: [2024, 2025, 2026],
            fallbackYearNumber: 2025
        )

        #expect(selectedYearNumber == 2025)
        #expect(state.selectedYearNumber == 2025)
    }

    @Test("selects last year when fallback is unavailable")
    func selectsLastYearWhenFallbackIsUnavailable() {
        let state = LunarSelectionState()

        let selectedYearNumber = state.selectDefaultYearIfNeeded(
            from: [2024, 2025, 2026],
            fallbackYearNumber: 2030
        )

        #expect(selectedYearNumber == 2026)
        #expect(state.selectedYearNumber == 2026)
    }

    @Test("keeps existing valid year")
    func keepsExistingValidYear() {
        let state = LunarSelectionState(selectedYearNumber: 2024)

        let selectedYearNumber = state.selectDefaultYearIfNeeded(
            from: [2024, 2025, 2026],
            fallbackYearNumber: 2025
        )

        #expect(selectedYearNumber == nil)
        #expect(state.selectedYearNumber == 2024)
    }

    @Test("clears month and day when year changes")
    func clearsMonthAndDayWhenYearChanges() {
        let state = LunarSelectionState(
            selectedYearNumber: 2024,
            selectedMonthIndex: 12,
            selectedDayIndex: 345
        )

        state.selectYear(number: 2025)

        #expect(state.selectedYearNumber == 2025)
        #expect(state.selectedMonthIndex == nil)
        #expect(state.selectedDayIndex == nil)
    }

    @Test("keeps month and day when year is unchanged")
    func keepsMonthAndDayWhenYearIsUnchanged() {
        let state = LunarSelectionState(
            selectedYearNumber: 2024,
            selectedMonthIndex: 12,
            selectedDayIndex: 345
        )

        state.selectYear(number: 2024)

        #expect(state.selectedMonthIndex == 12)
        #expect(state.selectedDayIndex == 345)
    }

    @Test("clears selected day when month changes")
    func clearsSelectedDayWhenMonthChanges() {
        let state = LunarSelectionState(selectedMonthIndex: 101, selectedDayIndex: 345)

        state.selectMonth(index: 102)

        #expect(state.selectedMonthIndex == 102)
        #expect(state.selectedDayIndex == nil)
    }

    @Test("selects adjacent years within bounds")
    func selectsAdjacentYearsWithinBounds() {
        let state = LunarSelectionState(selectedYearNumber: 2025)
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
        let state = LunarSelectionState()
        let monthIndexes = [101, 102, 103]

        state.selectDefaultMonthIfNeeded(from: monthIndexes)
        #expect(state.selectedMonthIndex == 101)

        state.selectNextMonth(in: monthIndexes)
        #expect(state.selectedMonthIndex == 102)

        state.selectPreviousMonth(in: monthIndexes)
        #expect(state.selectedMonthIndex == 101)
        #expect(!state.canSelectPreviousMonth(in: monthIndexes))
    }

    @Test("selects default day when selected day is missing")
    func selectsDefaultDayWhenSelectedDayIsMissing() {
        let state = LunarSelectionState(selectedDayIndex: 999)

        state.selectDefaultDayIfNeeded(from: [201, 202, 203])

        #expect(state.selectedDayIndex == 201)
    }
}
