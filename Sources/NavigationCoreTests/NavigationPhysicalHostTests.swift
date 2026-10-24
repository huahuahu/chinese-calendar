#if canImport(UIKit)
    @testable import NavigationCore
    import SwiftUI
    import Testing
    import UIKit

    @MainActor
    @Suite("根配置与 SwiftUI 原生关闭回调", .serialized)
    struct NavigationPhysicalHostTests {
        enum Scope: NavigationScope { case main }
        enum Destination: NavigationDestination { case home, first, second, target }
        enum Notice: NavigationAlertRoute { case work }
        typealias Router = NavigationRouter<Scope, Destination, Notice>
        typealias Presentation = NavigationPresentationContext<Scope, Destination, Notice>
        typealias Request = NavigationPresentationRequest<Scope, Destination, Notice>

        @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
        func nativeDismissalNotifiesOnceAndReleasesCallbackCapture(style: NavigationPresentationStyle) async throws {
            let router = Router(rootDestination: .home)
            let ledger = PhysicalHostLedger()
            let host = try await PhysicalNavigationHost.show(router: router, ledger: ledger)
            defer { host.removeFromWindow() }
            let observation = PhysicalDismissObservation()
            var resource: PhysicalHostResource? = PhysicalHostResource()
            weak var retained = resource
            let submission = router.rootPresentation.present(.first, style: style, onDismiss: { [capture = resource] in
                withExtendedLifetime(capture) { observation.recordFinish() }
            })
            resource = nil
            observation.controller = try await host.waitForPresentation()
            #expect(retained != nil)
            #expect(submission.handle?.dismiss() == .applied)
            #expect(observation.finishes == 0)
            try await host.waitUntil { observation.finishes == 1 }
            #expect(observation.completedAfterPhysicalDismissal)
            try await host.waitUntil { retained == nil }
            #expect(submission.handle?.dismiss() == .noChange(.notPresented))
            #expect(observation.finishes == 1)
            await host.close()
        }

        @Test func sameTurnCancellationDoesNotNotifyDismissalOrBlockNextPresentation() async throws {
            let router = Router(rootDestination: .home)
            let host = try await PhysicalNavigationHost.show(router: router, ledger: PhysicalHostLedger())
            defer { host.removeFromWindow() }
            var dismissals = 0
            let cancelled = router.rootPresentation.present(.sheet(.first)) { dismissals += 1 }
            #expect(cancelled.handle?.dismiss() == .applied)
            #expect(dismissals == 0)
            #expect(!router.isAwaitingPresentationDismissal)
            let next = router.rootPresentation.present(.sheet(.second)) { dismissals += 1 }
            #expect(next.result == .applied)
            _ = try await host.waitForPresentation()
            #expect(cancelled.handle?.dismiss() == .noChange(.notPresented))
            #expect(next.handle?.dismiss() == .applied)
            try await host.waitUntil { dismissals == 1 }
            await host.close()
        }

        @Test func rootPushAndNestedPresentationsUseTheRootConfiguration() async throws {
            let router = Router(rootDestination: .home)
            let ledger = PhysicalHostLedger()
            let host = try await PhysicalNavigationHost.show(router: router, ledger: ledger)
            defer { host.removeFromWindow() }
            var parentDismissals = 0
            var childDismissals = 0
            let parent = router.rootPresentation.present(.sheet(.first)) { parentDismissals += 1 }
            _ = try await host.waitForPresentation()
            let context = try #require(ledger.contexts[.first])
            #expect(context.context(for: .primary).push(.target).isApplied)
            try await host.waitUntil { ledger.rendered.contains("root:target") }
            let child = context.present(.sheet(.second)) { childDismissals += 1 }
            _ = try await host.waitForPresentation(depth: 2)
            #expect(ledger.rendered.isSuperset(of: ["root:home", "root:first", "root:second", "root:target"]))
            #expect(child.handle?.dismiss() == .applied)
            try await host.waitUntil { childDismissals == 1 }
            #expect(parentDismissals == 0)
            #expect(parent.handle?.dismiss() == .applied)
            try await host.waitUntil { parentDismissals == 1 }
            await host.close()
        }

        @Test func dismissCallbackCanPresentAgainAfterDeferredNavigationHasApplied() async throws {
            let router = Router(rootDestination: .home)
            let host = try await PhysicalNavigationHost.show(router: router, ledger: PhysicalHostLedger())
            defer { host.removeFromWindow() }
            var observedPath: [Destination] = []
            var next: NavigationPresentationSubmission?
            let first = router.rootPresentation.present(.sheet(.first)) {
                observedPath = router.rootPresentation.context(for: .primary).path
                next = router.rootPresentation.present(.sheet(.second))
            }
            _ = try await host.waitForPresentation()
            #expect(router.submit(.push(.target, on: .primary)) == .deferredUntilPresentationDismisses)
            try await host.waitUntil { next != nil }
            #expect(observedPath == [.target])
            #expect(next?.result == .applied)
            #expect(first.handle?.dismiss() == .noChange(.notPresented))
            _ = try await host.waitForPresentation()
            next?.handle?.dismiss()
            try await host.waitUntil { host.presentedController == nil }
            await host.close()
        }

        @Test func alertActionStillWaitsForPhysicalDismissalAndCompletesBeforeQueuedPage() async throws {
            let router = Router(rootDestination: .home)
            let ledger = PhysicalHostLedger()
            let gate = PhysicalActionGate()
            let host = try await PhysicalNavigationHost.show(router: router, ledger: ledger, gate: gate)
            defer { gate.release(); host.removeFromWindow() }
            var dismissals = 0
            #expect(router.rootPresentation.present(.alert(.work), onDismiss: { dismissals += 1 }).result == .applied)
            _ = try await host.waitForAlert()
            #expect(router.rootPresentation.present(.sheet(.second)).result == .queued)
            let presenter = try #require(host.alertPresenter)
            presenter.dismissCurrent(selection: 0)
            try await host.waitUntil { gate.started }
            #expect(dismissals == 0)
            #expect(router.presentedNode == nil)
            gate.release()
            try await host.waitUntil { dismissals == 1 }
            _ = try await host.waitForPresentation()
            #expect(ledger.actions == ["root:work"])
            #expect(router.presentedNode?.destination == .second)
            await host.close()
        }
    }
#endif
