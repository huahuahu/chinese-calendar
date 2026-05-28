@testable import ChineseCalendarUI
import SwiftUI
import Testing

@MainActor
@Suite("Calendar navigation state")
struct CalendarNavigationStateTests {
    @Test("stores route and column visibility independently")
    func storesRouteAndColumnVisibilityIndependently() {
        let state = CalendarNavigationState(
            route: .lunarYear(2025),
            columnVisibility: .detailOnly
        )

        #expect(state.route == .lunarYear(2025))
        #expect(state.columnVisibility == .detailOnly)

        state.route = .dynasty("ming")
        state.columnVisibility = .all

        #expect(state.route == .dynasty("ming"))
        #expect(state.columnVisibility == .all)
    }
}
