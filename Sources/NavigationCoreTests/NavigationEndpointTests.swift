@testable import NavigationCore
import Testing

@MainActor
@Suite("呈现参数与原生关闭边界")
struct NavigationEndpointTests {
    private enum Tab: NavigationScope { case home }
    private enum Route: NavigationDestination { case home, detail }
    private typealias Router = NavigationRouter<Tab, Route, NoNavigationAlert>
    private final class Resource {}

    @Test func repeatedFinishPreservesClaimedCallbackUntilSystemDismissal() throws {
        var dismissals = 0
        let lifetime = NavigationPresentationLifetime(onDismiss: { dismissals += 1 })
        lifetime.claimHost()
        lifetime.finish()
        lifetime.finish()
        lifetime.claimHost()

        #expect(lifetime.finished)
        #expect(!lifetime.hostClaimed)
        #expect(dismissals == 0)
        let completion = try #require(lifetime.takeOnDismiss())
        completion()
        #expect(dismissals == 1)
        #expect(lifetime.takeOnDismiss() == nil)
    }

    @Test func lateHostClaimCannotReviveCancelledRequest() {
        var resource: Resource? = Resource()
        weak var retained = resource
        var dismissals = 0
        let lifetime = NavigationPresentationLifetime(onDismiss: { [captured = resource] in
            withExtendedLifetime(captured) { dismissals += 1 }
        })
        resource = nil
        lifetime.finish()
        lifetime.claimHost()
        lifetime.finish()

        #expect(lifetime.finished)
        #expect(!lifetime.hostClaimed)
        #expect(retained == nil)
        #expect(lifetime.takeOnDismiss() == nil)
        #expect(dismissals == 0)
    }

    @Test func cancellationReleasesCallbackCaptureWithoutInvokingIt() {
        let router = Router(rootDestination: .home)
        var resource: Resource? = Resource()
        weak var retained = resource
        var dismissals = 0
        let submission = router.rootPresentation.present(.sheet(.detail), onDismiss: { [captured = resource] in
            withExtendedLifetime(captured) { dismissals += 1 }
        })
        resource = nil
        #expect(retained != nil)
        #expect(submission.handle?.dismiss() == .applied)
        #expect(retained == nil)
        #expect(dismissals == 0)
        #expect(!router.isAwaitingPresentationDismissal)
        #expect(submission.handle?.dismiss() == .noChange(.notPresented))
    }

    @Test func routerDestructionReleasesResourcesEvenWhileCallerKeepsHandleAndContext() throws {
        var router: Router? = Router(rootDestination: .home)
        let context = try #require(router?.rootPresentation)
        var resource: Resource? = Resource()
        weak var retained = resource
        var dismissals = 0
        let submission = context.present(.sheet(.detail), onDismiss: { [captured = resource] in
            withExtendedLifetime(captured) { dismissals += 1 }
        })
        resource = nil
        router = nil
        #expect(retained == nil)
        #expect(dismissals == 0)
        #expect(context.destination == nil)
        #expect(submission.handle?.dismiss() == .noChange(.notPresented))
    }
}
