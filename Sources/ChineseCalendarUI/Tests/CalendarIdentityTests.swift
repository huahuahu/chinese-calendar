@testable import ChineseCalendarUI
import SwiftUI
import Testing

@Suite("业务路由保持值语义")
struct CalendarIdentityTests {
    @Test func errorRoutesKeepValueSemanticsWithoutMessageIdentity() {
        let first = CalendarAlert.downloadFailed(failure: .server(status: 503))
        let same = CalendarAlert.downloadFailed(failure: .server(status: 503))
        let different = CalendarAlert.downloadFailed(failure: .server(status: 404))
        #expect(first == same)
        #expect(first != different)
        #expect(first != .clearDataFailed(failure: .server(status: 503)))
        #expect(Set([first, same, different]).count == 2)
    }

    @Test @MainActor func bindingChangesDoNotChangeRouteIdentityOrHash() throws {
        let container = try PreviewSampleData.makeModelContainer()
        let id = UUID()
        var year: Int? = 2026
        let binding = Binding(get: { year }, set: { year = $0 })
        let route = CalendarDestination.yearPicker(id: id, selection: binding, modelContext: container.mainContext)
        let routes: Set<CalendarDestination> = [route]
        let hash = route.hashValue
        binding.wrappedValue = 2025
        #expect(route.hashValue == hash)
        #expect(routes.contains(route))
        #expect(route == .yearPicker(id: id, selection: .constant(2000), modelContext: container.mainContext))
        #expect(route != .yearPicker(id: UUID(), selection: binding, modelContext: container.mainContext))
    }

    @Test @MainActor func ordinaryRoutesContinueComparingEveryAssociatedValue() {
        #expect(CalendarDestination.lunarYear(2025, monthIndex: 1) != .lunarYear(2025, monthIndex: 2))
        #expect(CalendarDestination.historyEmperor(orthodoxPeriodID: "a-b", emperorID: "c") !=
            .historyEmperor(orthodoxPeriodID: "a", emperorID: "b-c"))
    }

    #if DEBUG
        @Test @MainActor func downloadRoutesShareStateWithoutHashingItsMutableContents() {
            let state = FullStoreDownloadPreviewState()
            let route = CalendarDestination.downloadPreview(id: state.id, state: state)
            let routes: Set<CalendarDestination> = [route]
            state.stage = .completed
            #expect(routes.contains(route))
            #expect(route != .downloadPreviewScenarios(id: state.id, state: state))
            #expect(route != .downloadPreview(id: UUID(), state: state))
        }
    #endif
}
