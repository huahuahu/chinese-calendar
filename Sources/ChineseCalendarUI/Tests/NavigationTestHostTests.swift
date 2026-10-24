@testable import ChineseCalendarUI
import NavigationCore
import Testing

@MainActor
@Suite("App 公开导航宿主完成通知", .serialized)
struct NavigationTestHostTests {
    @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
    func physicalDismissalFinishesTheAcceptedRequestOnce(style: NavigationPresentationStyle) async throws {
        let router = NavigationTestHost.Router(rootDestination: .settings)
        let host = try await NavigationTestHost.show(router: router)
        defer { host.removeFromWindow() }
        var finishCount = 0
        let submission = router.rootPresentation.present(.settings, style: style) { finishCount += 1 }
        #expect(submission.result == .applied)
        let handle = try #require(submission.handle)
        let modal = try await host.context(for: .settings)
        _ = try await host.waitForPresentation()
        #expect(finishCount == 0)
        #expect(handle.dismiss().isAccepted)
        try await host.waitUntil { finishCount == 1 }
        #expect(modal.dismiss() == .rejected(.inactiveContext))
        #expect(!handle.dismiss().isAccepted)
        #expect(finishCount == 1)
        await host.close()
    }

    @Test func cancellingAQueuedRequestFinishesWithoutInventingADismissalCallback() async throws {
        let router = NavigationTestHost.Router(rootDestination: .settings)
        let host = try await NavigationTestHost.show(router: router)
        defer { host.removeFromWindow() }
        #expect(router.rootPresentation.presentAlert(.clearDataSucceeded).result == .applied)
        var finishCount = 0
        let submission = router.rootPresentation.present(.settings) { finishCount += 1 }
        #expect(submission.result == .queued)
        #expect(try #require(submission.handle).dismiss().isAccepted)
        #expect(finishCount == 0)
        #expect(host.contexts[CalendarDestination.settings.id] == nil)
        await host.close()
        #expect(finishCount == 0)
    }
}
