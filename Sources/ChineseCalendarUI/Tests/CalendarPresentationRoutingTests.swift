@testable import ChineseCalendarUI
import NavigationCore
import Testing

@MainActor
@Test func manualDismissalDefersTheLatestDeepLinkUntilTheHostFinishes() async throws {
    let router = CalendarRouter(yearsPath: [.lunarYear(2024)])
    let root = router.navigation.rootPresentation
    let host = try await NavigationTestHost.show(router: router.navigation)
    defer { host.removeFromWindow() }
    var finishCount = 0
    let submission = root.present(.lunarYear(2025), onDismiss: { finishCount += 1 })
    #expect(submission.result == .applied)
    _ = try await host.waitForPresentation()
    #expect(try #require(submission.handle).dismiss() == .applied)

    #expect(router.openDeepLink(.lunarYear(2026, monthIndex: nil)) == .deferredUntilPresentationDismisses)
    #expect(router.openDeepLink(.emperor("ming-taizu")) == .deferredUntilPresentationDismisses)
    #expect(root.present(.downloadDetails, style: .fullScreen).result == .rejected(.awaitingDismissal))
    #expect(router.yearsPath == [.lunarYear(2024)])
    #expect(router.historyPath.isEmpty)
    #expect(finishCount == 0)

    let history = root.context(for: .scope(.history))
    try await host.waitUntil { history.rootDestination == .emperor("ming-taizu") }
    #expect(router.historyPath.isEmpty)
    #expect(router.yearsPath == [.lunarYear(2024)])
    #expect(router.selectedTab == .history)
    #expect(finishCount == 1)
    #expect(host.presentedViewController() == nil)
    await host.close()
}

@MainActor
@Test func dismissalWithoutARequestAllowsReopening() async throws {
    let router = CalendarRouter()
    let root = router.navigation.rootPresentation
    let host = try await NavigationTestHost.show(router: router.navigation)
    defer { host.removeFromWindow() }
    var finishCount = 0
    let original = root.present(.downloadDetails, style: .fullScreen) { finishCount += 1 }
    #expect(original.result == .applied)
    let context = try await host.context(for: .downloadDetails)
    _ = try await host.waitForPresentation()
    #expect(try #require(original.handle).dismiss() == .applied)
    #expect(finishCount == 0)
    try await host.waitUntil { finishCount == 1 }

    #expect(root.present(.downloadDetails, style: .fullScreen).result == .applied)
    let reopened = try await host.context(for: .downloadDetails, differentFrom: context)
    #expect(reopened !== context)
    #expect(context.dismiss() == .rejected(.inactiveContext))
    #expect(reopened.context(for: .primary).rootDestination == .downloadDetails)
    _ = try await host.waitForPresentation()
    await host.close()
}

@MainActor
@Test func targetedDismissalPreservesTheParentAndTabPaths() async throws {
    let router = CalendarRouter(yearsPath: [.lunarYear(2024)])
    let root = router.navigation.rootPresentation
    let host = try await NavigationTestHost.show(router: router.navigation)
    defer { host.removeFromWindow() }
    #expect(root.present(.lunarYear(2025), style: .fullScreen).result == .applied)
    let parent = try await host.context(for: .lunarYear(2025))
    let parentController = try await host.waitForPresentation()
    #expect(parent.context(for: .primary).push(.lunarYear(2026)) == .applied)
    var childFinishes = 0
    var descendantFinishes = 0
    let childSubmission = parent.present(.downloadDetails, onDismiss: { childFinishes += 1 })
    #expect(childSubmission.result == .applied)
    let child = try await host.context(for: .downloadDetails)
    _ = try await host.waitForPresentation()
    #expect(child.present(.lunarYear(2027), style: .fullScreen, onDismiss: { descendantFinishes += 1 })
        .result == .applied)
    let descendant = try await host.context(for: .lunarYear(2027))
    _ = try await host.waitForPresentation()

    let handle = try #require(childSubmission.handle)
    #expect(handle.dismiss() == .applied)
    #expect(parent.context(for: .primary).path == [.lunarYear(2026)])
    #expect(router.yearsPath == [.lunarYear(2024)])
    #expect(!child.dismiss().isAccepted)
    #expect(!descendant.dismiss().isAccepted)
    try await host.waitUntil { childFinishes == 1 && descendantFinishes == 1 }
    #expect(host.presentedViewController() === parentController)
    #expect(!handle.dismiss().isAccepted)
    #expect(parent.context(for: .primary).push(.lunarYear(2028)) == .applied)
    #expect(router.yearsPath == [.lunarYear(2024)])
    await host.close()
}
