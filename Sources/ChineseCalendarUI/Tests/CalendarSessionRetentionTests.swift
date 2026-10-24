@testable import ChineseCalendarUI
import Foundation
import NavigationCore
import SwiftData
import Testing

@MainActor
@Suite("路由参数跟随页面释放", .serialized)
struct CalendarSessionRetentionTests {
    @Test func oldContextDoesNotRetainBindingAfterDismissal() async throws {
        let coordinator = CalendarHomeCoordinator()
        let host = try await NavigationTestHost.show(coordinator: coordinator)
        defer { host.removeFromWindow() }
        let container = try PreviewSampleData.makeModelContainer()
        let resources = try presentDetachedFeature(
            from: coordinator.router.navigation.rootPresentation, modelContext: container.mainContext
        )
        let context = try await host.pickerContext(id: resources.id)
        _ = try await host.waitForPresentation()
        #expect(resources.feature != nil)
        #expect(context.dismiss().isAccepted)
        #expect(resources.feature != nil)
        try await host.waitUntil { resources.feature == nil }
        #expect(context.dismiss() == .rejected(.inactiveContext))
        await host.close()
    }

    @Test func ancestorDismissalReleasesNestedBindingCaptures() async throws {
        let coordinator = CalendarHomeCoordinator()
        let host = try await NavigationTestHost.show(coordinator: coordinator)
        defer { host.removeFromWindow() }
        let container = try PreviewSampleData.makeModelContainer()
        let parent = try presentDetachedFeature(
            from: coordinator.router.navigation.rootPresentation, modelContext: container.mainContext
        )
        let parentContext = try await host.pickerContext(id: parent.id)
        _ = try await host.waitForPresentation()
        let child = try presentDetachedFeature(from: parentContext, modelContext: container.mainContext)
        let childContext = try await host.pickerContext(id: child.id)
        _ = try await host.waitForPresentation()
        #expect(parentContext.dismiss().isAccepted)
        try await host.waitUntil { parent.feature == nil && child.feature == nil }
        #expect(childContext.dismiss() == .rejected(.inactiveContext))
        await host.close()
    }

    @Test func queuedCancellationReleasesBindingWithoutBuildingPage() async throws {
        let coordinator = CalendarHomeCoordinator()
        let host = try await NavigationTestHost.show(coordinator: coordinator)
        defer { host.removeFromWindow() }
        let root = coordinator.router.navigation.rootPresentation
        #expect(root.presentAlert(.clearDataSucceeded).result == .applied)
        _ = try await host.waitForAlert()
        let first = try PreviewSampleData.makeModelContainer()
        let second = try PreviewSampleData.makeModelContainer()
        let resources = try presentDetachedFeature(from: root, modelContext: first.mainContext)
        #expect(resources.feature != nil)
        resources.feature?.connect(modelContext: second.mainContext, storeCoordinator: nil)
        #expect(resources.feature == nil)
        #expect(host.contexts["year-picker-\(resources.id)"] == nil)
        await host.close()
    }

    private func presentDetachedFeature(
        from presentation: CalendarPresentationContext, modelContext: ModelContext
    ) throws -> YearResources {
        let feature = CalendarYearFeature(selection: CalendarSelection(selectedDayIndex: 315))
        feature.connect(modelContext: modelContext, storeCoordinator: nil)
        feature.presentYearPicker(presentation: presentation)
        return try YearResources(id: #require(feature.yearPickerID), feature: feature)
    }
}

@MainActor
private final class YearResources {
    let id: UUID
    weak var feature: CalendarYearFeature?

    init(id: UUID, feature: CalendarYearFeature) {
        self.id = id
        self.feature = feature
    }
}
