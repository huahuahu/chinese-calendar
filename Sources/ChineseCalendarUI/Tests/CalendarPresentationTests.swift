@testable import ChineseCalendarUI
import NavigationCore
import SwiftUI
import Testing

@MainActor
@Suite("页面呈现与下载资源所有权", .serialized)
struct CalendarPresentationTests {
    @Test(.timeLimit(.minutes(1)))
    func rejectedAndSynchronouslyCancelledDetailsAllowANewRequest() async throws {
        let feature = CalendarDownloadDetailsFeature()
        let router = CalendarRouter().navigation
        let root = router.rootPresentation
        feature.present(from: root)
        #expect(feature.request == nil)

        let host = try await NavigationTestHost.show(router: router)
        defer { host.removeFromWindow() }
        feature.present(from: root)
        let first = try #require(feature.request)
        feature.progressDidDisappear()
        #expect(feature.request == nil)
        #expect(host.presentedViewController() == nil)

        feature.present(from: root)
        let replacement = try #require(feature.request)
        #expect(replacement !== first)
        #expect(!first.dismiss().isAccepted)
        #expect(feature.request === replacement)
        feature.progressDidDisappear()
        #expect(feature.request == nil)
        await host.close()
    }

    @Test(.timeLimit(.minutes(1)))
    func disappearingDownloadOnlyClosesItsOwnDetails() async throws {
        let coordinator = CalendarHomeCoordinator()
        let router = coordinator.router.navigation
        let host = try await NavigationTestHost.show(router: router)
        defer { host.removeFromWindow() }
        let parent = router.rootPresentation.present(.sheet(.lunarYear(2025)))
        let parentContext = try await host.context(for: .lunarYear(2025))
        _ = try await host.waitForPresentation()
        coordinator.downloadDetails.progressDidDisappear()
        #expect(parentContext.isPresented)

        coordinator.downloadDetails.present(from: parentContext)
        let request = try #require(coordinator.downloadDetails.request)
        coordinator.downloadDetails.present(from: parentContext)
        #expect(coordinator.downloadDetails.request === request)
        _ = try await host.context(for: .downloadDetails)
        _ = try await host.waitForPresentation()
        coordinator.downloadDetails.progressDidDisappear()
        #expect(coordinator.downloadDetails.request === request)
        try await host.waitUntil { coordinator.downloadDetails.request == nil }
        #expect(parentContext.isPresented)
        parent.handle?.dismiss()
        try await host.waitUntil { host.presentedViewController() == nil }
        await host.close()
    }

    @Test(.timeLimit(.minutes(1)))
    func disappearingProgressCancelsAnUnshownRequest() async throws {
        let coordinator = CalendarHomeCoordinator()
        let host = try await NavigationTestHost.show(router: coordinator.router.navigation)
        defer { host.removeFromWindow() }
        coordinator.downloadDetails.present(from: coordinator.router.navigation.rootPresentation)
        #expect(coordinator.downloadDetails.request != nil)
        coordinator.downloadDetails.progressDidDisappear()
        #expect(coordinator.downloadDetails.request == nil)
        #expect(host.presentedViewController() == nil)
        await host.close()
    }

    @Test func rebuildingDataPagesDoesNotReplayColdLaunchLink() {
        let coordinator = CalendarHomeCoordinator()
        coordinator.openColdLaunchDeepLink(.lunarYear(2025, monthIndex: nil))
        coordinator.openDeepLink(.emperor("ming-taizu"))
        coordinator.openColdLaunchDeepLink(.lunarYear(2025, monthIndex: nil))
        #expect(coordinator.router.selectedTab == .history)
        #expect(coordinator.router.navigation.rootPresentation.context(for: .scope(.history)).rootDestination
            == .emperor("ming-taizu"))
        #expect(coordinator.router.historyPath.isEmpty)
    }

    #if DEBUG
        @Test(.timeLimit(.minutes(1)))
        func previewOwnerReleasesAfterActualFullscreenDismissalAndCanReopen() async throws {
            let coordinator = CalendarHomeCoordinator()
            let feature = FullStoreDownloadPreviewFeature()
            let host = try await NavigationTestHost.show(router: coordinator.router.navigation)
            defer { host.removeFromWindow() }
            let root = coordinator.router.navigation.rootPresentation
            feature.present(from: root, coordinator: coordinator)
            weak var original = feature.session
            #expect(original != nil)
            feature.present(from: root, coordinator: coordinator)
            #expect(feature.session === original)
            original?.stage = .downloading
            _ = try await host.waitForPresentation()
            #expect(original?.stage.progress.downloadFraction == 0.5)
            await host.dismissPresentedViewController()
            try await host.waitUntil { feature.session == nil }
            try await host.waitUntil { original == nil }
            feature.present(from: root, coordinator: coordinator)
            #expect(feature.session?.stage == .preparing)
            _ = try await host.waitForPresentation()
            await host.dismissPresentedViewController()
            try await host.waitUntil { feature.session == nil }
            await host.close()
        }
    #endif
}
