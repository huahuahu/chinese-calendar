@testable import ChineseCalendarUI
import NavigationCore
import SwiftData
import Testing

@MainActor
@Suite("业务资源跟随真实呈现完成释放", .serialized)
struct CalendarSessionRetentionTests {
    @Test func acceptedPickerKeepsItsOriginatingFeatureUntilPhysicalDismissal() async throws {
        let coordinator = CalendarHomeCoordinator()
        let host = try await NavigationTestHost.show(router: coordinator.router.navigation)
        defer { host.removeFromWindow() }
        let container = try PreviewSampleData.makeModelContainer()
        let resources = presentDetachedFeature(
            from: coordinator.router.navigation.rootPresentation,
            host: host, coordinator: coordinator, modelContext: container.mainContext
        )
        let context = try await host.context(for: .yearPicker)
        _ = try await host.waitForPresentation()
        #expect(resources.feature != nil)
        #expect(resources.session != nil)
        #expect(resources.feature?.yearPickerSession === resources.session)

        #expect(context.dismiss().isAccepted)
        // 关闭命令同步返回时仍需为退出动画保留 feature 和 SwiftData 会话。
        #expect(resources.feature != nil)
        #expect(resources.session != nil)
        try await host.waitUntil { resources.feature == nil && resources.session == nil }
        #expect(context.dismiss() == .rejected(.inactiveContext))
        await host.close()
    }

    @Test func ancestorDismissalReleasesBothDetachedFeaturesAfterTheirRealPresentationsEnd() async throws {
        let coordinator = CalendarHomeCoordinator()
        let host = try await NavigationTestHost.show(router: coordinator.router.navigation)
        defer { host.removeFromWindow() }
        let container = try PreviewSampleData.makeModelContainer()
        let parent = presentDetachedFeature(
            from: coordinator.router.navigation.rootPresentation,
            host: host, coordinator: coordinator, modelContext: container.mainContext
        )
        let parentContext = try await host.context(for: .yearPicker)
        _ = try await host.waitForPresentation()
        let child = presentDetachedFeature(
            from: parentContext, host: host, coordinator: coordinator, modelContext: container.mainContext
        )
        let childContext = try await host.context(for: .yearPicker, differentFrom: parentContext)
        _ = try await host.waitForPresentation()
        #expect(parent.feature !== child.feature)
        #expect(parent.session !== child.session)

        #expect(parentContext.dismiss().isAccepted)
        #expect(parent.feature != nil)
        #expect(child.feature != nil)
        #expect(parent.session != nil)
        #expect(child.session != nil)
        try await host.waitUntil {
            parent.feature == nil && child.feature == nil && parent.session == nil && child.session == nil
        }
        #expect(parentContext.dismiss() == .rejected(.inactiveContext))
        #expect(childContext.dismiss() == .rejected(.inactiveContext))
        #expect(host.presentedViewController() == nil)
        await host.close()
    }

    @Test func cancellingAQueuedPickerReleasesItsDetachedFeatureWithoutBuildingThePage() async throws {
        let coordinator = CalendarHomeCoordinator()
        let root = coordinator.router.navigation.rootPresentation
        let host = try await NavigationTestHost.show(router: coordinator.router.navigation)
        defer { host.removeFromWindow() }
        #expect(root.presentAlert(.clearDataSucceeded).result == .applied)
        let alert = try await host.waitForAlert()
        let firstContainer = try PreviewSampleData.makeModelContainer()
        let secondContainer = try PreviewSampleData.makeModelContainer()
        let resources = presentDetachedFeature(
            from: root, host: host, coordinator: coordinator, modelContext: firstContainer.mainContext
        )
        #expect(resources.feature != nil)
        #expect(resources.session != nil)
        #expect(host.contexts[.yearPicker] == nil)

        resources.feature?.connect(modelContext: secondContainer.mainContext, storeCoordinator: nil)

        #expect(resources.feature == nil)
        #expect(resources.session == nil)
        #expect(host.contexts[.yearPicker] == nil)
        #expect(host.presentedViewController() === alert)
        await host.close()
    }

    /// 返回的探针只持有 weak 引用；业务对象唯一的剩余 owner 是真实 builder 配置。
    private func presentDetachedFeature(
        from presentation: CalendarPresentationContext,
        host: NavigationTestHost, coordinator: CalendarHomeCoordinator, modelContext: ModelContext
    ) -> YearResources {
        let feature = CalendarYearFeature(selection: CalendarSelection(selectedDayIndex: 315))
        feature.connect(modelContext: modelContext, storeCoordinator: nil)
        let resources = YearResources(feature: feature)
        feature.presentYearPicker(presentation: presentation) { session in
            resources.session = session
            return host.recording(configuration: coordinator.yearPickerConfiguration(
                feature: feature, session: session, storeCoordinator: nil
            ))
        }
        return resources
    }
}

@MainActor
private final class YearResources {
    weak var feature: CalendarYearFeature?
    weak var session: CalendarYearPickerSession?

    init(feature: CalendarYearFeature) {
        self.feature = feature
    }
}
