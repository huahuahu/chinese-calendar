@testable import ChineseCalendarUI
import NavigationCore
import SwiftUI
import Testing

@MainActor
@Suite("宿主结束与业务资源释放", .serialized)
struct CalendarSessionCleanupHostTests {
    @Test(.timeLimit(.minutes(1)))
    func hostKeepsRenderedResourceUntilActualDismissal() async throws {
        let router = CalendarRouter().navigation
        let host = try await NavigationTestHost.show(router: router)
        defer { host.removeFromWindow() }
        var resource: Resource? = Resource()
        weak var retained = resource
        var finishes = 0
        let submission = try router.rootPresentation.present(
            .sheet(.downloadDetails), configuration: Configuration(resource: #require(resource))
        ) { finishes += 1 }
        resource = nil
        _ = try await host.waitForPresentation()
        #expect(retained != nil)
        submission.handle?.dismiss()
        #expect(finishes == 0)
        #expect(retained != nil)
        try await host.waitUntil { finishes == 1 }
        try await host.waitUntil { retained == nil }
        submission.handle?.dismiss()
        #expect(finishes == 1)
        await host.close()
    }

    @Test(.timeLimit(.minutes(1)))
    func hostCompletesSameTurnCancellationWithoutAView() async throws {
        let router = CalendarRouter().navigation
        let host = try await NavigationTestHost.show(router: router)
        defer { host.removeFromWindow() }
        var resource: Resource? = Resource()
        weak var retained = resource
        var finishes = 0
        let submission = try router.rootPresentation.present(
            .sheet(.downloadDetails), configuration: Configuration(resource: #require(resource))
        ) { finishes += 1 }
        resource = nil
        submission.handle?.dismiss()
        #expect(finishes == 1)
        #expect(retained == nil)
        #expect(host.presentedViewController() == nil)
        await host.close()
    }
}

@MainActor
private final class Resource {}

private struct Configuration: @MainActor NavigationHostConfiguration {
    typealias Scope = CalendarTab
    typealias Destination = CalendarDestination
    typealias AlertRoute = CalendarAlert
    let resource: Resource

    func destination(for destination: CalendarDestination) -> some View {
        Text("Resource page").onAppear { withExtendedLifetime(resource) {} }
    }
}
