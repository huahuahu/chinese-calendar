@testable import ChineseCalendarUI
import NavigationCore
import SwiftData
import Testing

@MainActor
@Suite("年份选择器使用根配置与原生关闭回调", .serialized)
struct CalendarYearPresentationTests {
    @Test func rejectedSubmissionClearsItsPreparedState() throws {
        let router = NavigationTestHost.Router(rootDestination: .calendarHome)
        #expect(router.rootPresentation.present(.sheet(.settings)).result == .applied)
        let container = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(container.mainContext)
        feature.presentYearPicker(presentation: router.rootPresentation)
        #expect(feature.yearPickerID == nil)
        #expect(feature.selection.selectedDayIndex == 315)
    }

    @Test func normalDismissalClearsOnlyTheCurrentPicker() async throws {
        let coordinator = CalendarHomeCoordinator()
        let host = try await NavigationTestHost.show(coordinator: coordinator)
        defer { host.removeFromWindow() }
        let container = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(container.mainContext)
        feature.presentYearPicker(presentation: coordinator.router.navigation.rootPresentation)
        let id = try #require(feature.yearPickerID)
        let context = try await host.pickerContext(id: id)
        _ = try await host.waitForPresentation()
        feature.presentYearPicker(presentation: coordinator.router.navigation.rootPresentation)
        #expect(feature.yearPickerID == id)
        #expect(context.dismiss().isAccepted)
        #expect(feature.yearPickerID == id)
        #expect(!context.dismiss().isAccepted)
        try await host.waitUntil { feature.yearPickerID == nil }
        await host.close()
    }

    @Test func nestedPickersKeepIndependentOwners() async throws {
        let coordinator = CalendarHomeCoordinator()
        let host = try await NavigationTestHost.show(coordinator: coordinator)
        defer { host.removeFromWindow() }
        let firstContainer = try PreviewSampleData.makeModelContainer()
        let secondContainer = try PreviewSampleData.makeModelContainer()
        let first = makeFeature(firstContainer.mainContext)
        let second = makeFeature(secondContainer.mainContext)
        first.presentYearPicker(presentation: coordinator.router.navigation.rootPresentation)
        let firstID = try #require(first.yearPickerID)
        let parent = try await host.pickerContext(id: firstID)
        _ = try await host.waitForPresentation()
        second.presentYearPicker(presentation: parent)
        let child = try await host.pickerContext(id: #require(second.yearPickerID))
        _ = try await host.waitForPresentation()
        #expect(child.dismiss().isAccepted)
        try await host.waitUntil { second.yearPickerID == nil }
        #expect(first.yearPickerID == firstID)
        #expect(parent.dismiss().isAccepted)
        try await host.waitUntil { first.yearPickerID == nil }
        await host.close()
    }

    @Test func replacingContextDismissesItsPickerAndAllowsReopening() async throws {
        let coordinator = CalendarHomeCoordinator()
        let host = try await NavigationTestHost.show(coordinator: coordinator)
        defer { host.removeFromWindow() }
        let first = try PreviewSampleData.makeModelContainer()
        let second = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(first.mainContext)
        feature.presentYearPicker(presentation: coordinator.router.navigation.rootPresentation)
        _ = try await host.pickerContext(id: #require(feature.yearPickerID))
        _ = try await host.waitForPresentation()
        feature.connect(modelContext: second.mainContext, storeCoordinator: nil)
        #expect(feature.yearPickerID == nil)
        try await host.waitUntil { host.presentedViewController() == nil }
        feature.presentYearPicker(presentation: coordinator.router.navigation.rootPresentation)
        _ = try await host.pickerContext(id: #require(feature.yearPickerID))
        _ = try await host.waitForPresentation()
        await host.close()
    }

    @Test func invalidatingQueuedPickerClearsOwnerWithoutDismissalCallback() async throws {
        let coordinator = CalendarHomeCoordinator()
        let host = try await NavigationTestHost.show(coordinator: coordinator)
        defer { host.removeFromWindow() }
        let root = coordinator.router.navigation.rootPresentation
        #expect(root.presentAlert(.clearDataSucceeded).result == .applied)
        _ = try await host.waitForAlert()
        let first = try PreviewSampleData.makeModelContainer()
        let second = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(first.mainContext)
        feature.presentYearPicker(presentation: root)
        let id = try #require(feature.yearPickerID)
        feature.connect(modelContext: second.mainContext, storeCoordinator: nil)
        #expect(feature.yearPickerID == nil)
        #expect(host.contexts["year-picker-\(id)"] == nil)
        await host.close()
    }

    private func makeFeature(_ context: ModelContext) -> CalendarYearFeature {
        let feature = CalendarYearFeature(selection: CalendarSelection(selectedDayIndex: 315))
        feature.connect(modelContext: context, storeCoordinator: nil)
        return feature
    }
}
