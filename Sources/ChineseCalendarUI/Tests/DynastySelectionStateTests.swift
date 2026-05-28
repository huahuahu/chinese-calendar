@testable import ChineseCalendarUI
import Testing

@MainActor
@Suite("Dynasty selection state")
struct DynastySelectionStateTests {
    @Test("selects dynasty, tradition, and orthodox period independently")
    func selectsDynastyTraditionAndOrthodoxPeriodIndependently() {
        let state = DynastySelectionState()

        state.selectDynasty(id: "han")
        state.selectOrthodoxTradition(id: "mainstream")
        state.selectOrthodoxPeriod(id: "mainstream_han")

        #expect(state.selectedDynastyID == "han")
        #expect(state.selectedOrthodoxTraditionID == "mainstream")
        #expect(state.selectedOrthodoxPeriodID == "mainstream_han")
    }

    @Test("clears dynasty selection group")
    func clearsDynastySelectionGroup() {
        let state = DynastySelectionState(
            selectedDynastyID: "han",
            selectedOrthodoxTraditionID: "mainstream",
            selectedOrthodoxPeriodID: "mainstream_han"
        )

        state.clearSelection()

        #expect(state.selectedDynastyID == nil)
        #expect(state.selectedOrthodoxTraditionID == nil)
        #expect(state.selectedOrthodoxPeriodID == nil)
    }
}
