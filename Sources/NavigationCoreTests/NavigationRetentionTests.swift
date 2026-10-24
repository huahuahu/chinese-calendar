@testable import NavigationCore
import Testing

// swiftformat:disable:next modifierOrder
nonisolated private enum RetentionTestAlert: NavigationAlertRoute {
    case first, second, third
}

@MainActor
@Suite("每次呈现的完成身份与资源生命周期")
struct NavigationRetentionTests {
    private enum Tab: NavigationScope { case home }
    private enum Route: NavigationDestination { case home, parent, child, queued }
    private typealias Router = NavigationRouter<Tab, Route, RetentionTestAlert>

    @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
    func unclaimedPageCancellationFinishesImmediately(style: NavigationPresentationStyle) {
        let router = Router(rootDestination: .home)
        let lifetime = NavigationPresentationLifetime()
        let observer = lifetime
        let handle = NavigationPresentationHandle(router: router, lifetime: lifetime)
        #expect(router.rootPresentation.submitPresentation(.parent, style: style, lifetime: lifetime) == .applied)
        #expect(handle.dismiss() == .applied)
        #expect(router.presentedNode == nil)
        #expect(!router.isAwaitingPresentationDismissal)
        #expect(observer.finished)
        #expect(handle.dismiss() == .noChange(.notPresented))
        router.rootPresentation.presentationDidDismiss(lifetime: lifetime)
        #expect(observer.finished)
    }

    @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
    func claimedPageWaitsForExactCompletionAndOldHandleCannotCloseNewPage(style: NavigationPresentationStyle) throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        let first = NavigationPresentationLifetime()
        let observer = first
        let handle = NavigationPresentationHandle(router: router, lifetime: first)
        root.submitPresentation(.parent, style: style, lifetime: first)
        first.claimHost()
        #expect(handle.dismiss() == .applied)
        #expect(router.isAwaitingPresentationDismissal)
        #expect(!observer.finished)
        #expect(handle.dismiss() == .queued)
        root.presentationDidDismiss(lifetime: NavigationPresentationLifetime())
        #expect(!observer.finished)
        #expect(router.isAwaitingPresentationDismissal)
        root.presentationDidDismiss(lifetime: first)
        #expect(observer.finished)
        #expect(!router.isAwaitingPresentationDismissal)

        root.submitPresentation(.parent, style: style)
        let newNode = try #require(router.presentedNode)
        newNode.lifetime.claimHost()
        #expect(handle.dismiss() == .noChange(.notPresented))
        root.presentationDidDismiss(lifetime: first)
        #expect(router.presentedNode === newNode)
        #expect(!newNode.lifetime.finished)
        #expect(observer.finished)
    }

    @Test func queuedCancellationFinishesOnceWithoutChangingRemainingFIFO() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        root.submitAlert(.first)
        let first = try #require(root.presentedAlert)
        let session = try #require(root.claimAlertSession(id: .business(first.id)))
        let cancelled = NavigationPresentationLifetime()
        let observer = cancelled
        let next = NavigationPresentationLifetime()
        #expect(root.submitAlert(.second, lifetime: cancelled) == .queued)
        #expect(root.submitPresentation(.queued, lifetime: next) == .queued)
        let handle = NavigationPresentationHandle(router: router, lifetime: cancelled)
        #expect(handle.dismiss() == .applied)
        #expect(observer.finished)
        #expect(root.layer?.queuedPresentations.count == 1)
        #expect(root.layer?.queuedPresentations.first?.lifetime === next)
        #expect(handle.dismiss() == .noChange(.notPresented))
        root.alertWillDismiss(id: session.id)
        #expect(session.beginCompletion())
        root.completeAlertSession(session)
        #expect(root.presentedNode?.destination == .queued)
        #expect(root.presentedNode?.lifetime === next)
        #expect(observer.finished)
    }

    @Test func ancestorCompletionFinishesSubtreeAndRejectsChildCompletionForRootRequest() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        root.submitPresentation(.parent)
        let parent = try #require(router.presentedNode)
        parent.lifetime.claimHost()
        let parentProbe = parent.lifetime
        let context = router.presentationContext(for: parent)
        context.submitPresentation(.child)
        let child = try #require(parent.presentation)
        child.lifetime.claimHost()
        let childProbe = child.lifetime
        router.dismissPresentation(id: child.id)
        #expect(router.submit(.push(.queued, on: .primary)) == .deferredUntilPresentationDismisses)
        context.presentationDidDismiss(lifetime: child.lifetime)
        #expect(!parentProbe.finished && !childProbe.finished)
        #expect(root.context(for: .primary).path.isEmpty)
        root.presentationDidDismiss(lifetime: parent.lifetime)
        #expect(parentProbe.finished && childProbe.finished)
        #expect(root.context(for: .primary).path == [.queued])
        root.presentationDidDismiss(lifetime: parent.lifetime)
        #expect(parentProbe.finished && childProbe.finished)
    }

    @Test func ancestorDismissalCancelsUnhostedQueueBeforeItsOwnCompletion() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        root.submitPresentation(.parent)
        let parent = try #require(router.presentedNode)
        parent.lifetime.claimHost()
        let parentProbe = parent.lifetime
        let context = router.presentationContext(for: parent)
        context.submitAlert(.first)
        let alert = try #require(context.presentedAlert)
        let session = try #require(context.claimAlertSession(id: .business(alert.id)))
        let queued = NavigationPresentationLifetime()
        let queuedProbe = queued
        #expect(context.submitPresentation(.queued, lifetime: queued) == .queued)
        #expect(context.dismiss() == .queued)
        context.alertWillDismiss(id: session.id)
        #expect(session.beginCompletion())
        context.completeAlertSession(session)
        #expect(queuedProbe.finished)
        #expect(!parentProbe.finished)
        #expect(router.isAwaitingPresentationDismissal)
        root.presentationDidDismiss(lifetime: parent.lifetime)
        #expect(parentProbe.finished)
        #expect(queuedProbe.finished)
    }

    @Test func closingClaimedParentCancelsUnclaimedAlertWithoutShowingIt() throws {
        let router = Router(rootDestination: .home)
        router.rootPresentation.submitPresentation(.parent)
        let parent = try #require(router.presentedNode)
        parent.lifetime.claimHost()
        let context = router.presentationContext(for: parent)
        let alert = NavigationPresentationLifetime()
        let observer = alert
        context.submitAlert(.first, lifetime: alert)
        #expect(context.dismiss() == .applied)
        #expect(observer.finished)
        #expect(!router.hasActiveAlert)
        #expect(router.isAwaitingPresentationDismissal)
        router.rootPresentation.presentationDidDismiss(lifetime: parent.lifetime)
        #expect(observer.finished)
    }
}

extension NavigationRetentionTests {
    @Test func alertHandleWaitsForSystemCompletionAndBusinessAction() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        let lifetime = NavigationPresentationLifetime()
        let observer = lifetime
        root.submitAlert(.first, lifetime: lifetime)
        let alert = try #require(root.presentedAlert)
        let session = try #require(root.claimAlertSession(id: .business(alert.id)))
        let handle = NavigationPresentationHandle(router: router, lifetime: lifetime)
        #expect(handle.dismiss() == .applied)
        #expect(root.presentedAlert == nil)
        #expect(router.hasActiveAlert)
        #expect(!observer.finished)
        root.completeAlertSession(session)
        #expect(!observer.finished)
        session.beginDismissal()
        #expect(session.beginCompletion())
        #expect(!session.beginCompletion())
        #expect(!observer.finished)
        root.completeAlertSession(session)
        #expect(observer.finished)
        #expect(!router.hasActiveAlert)
        root.completeAlertSession(session)
        #expect(observer.finished)
    }

    @Test func physicalAncestorCompletionStillWaitsForDescendantAlertAction() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        root.submitPresentation(.parent)
        let parent = try #require(router.presentedNode)
        parent.lifetime.claimHost()
        let parentProbe = parent.lifetime
        let context = router.presentationContext(for: parent)
        context.submitAlert(.first)
        let alert = try #require(context.presentedAlert)
        let alertProbe = alert.lifetime
        let session = try #require(context.claimAlertSession(id: .business(alert.id)))
        context.alertWillDismiss(id: session.id)
        #expect(session.beginCompletion())
        #expect(router.submit(.push(.queued, on: .primary)) == .deferredUntilAlertDismisses)
        root.presentationDidDismiss(lifetime: parent.lifetime)
        #expect(!parentProbe.finished && !alertProbe.finished)
        #expect(router.isAwaitingPresentationDismissal)
        #expect(root.context(for: .primary).path.isEmpty)
        context.completeAlertSession(session)
        #expect(parentProbe.finished && alertProbe.finished)
        #expect(root.context(for: .primary).path == [.queued])
        #expect(!router.isAwaitingPresentationDismissal)
    }

    @Test func unclaimedAlertCancellationDoesNotNeedSystemCallback() {
        let router = Router(rootDestination: .home)
        let lifetime = NavigationPresentationLifetime()
        let observer = lifetime
        router.rootPresentation.submitAlert(.first, lifetime: lifetime)
        let handle = NavigationPresentationHandle(router: router, lifetime: lifetime)
        #expect(handle.dismiss() == .applied)
        #expect(observer.finished)
        #expect(!router.hasActiveAlert)
        #expect(router.rootPresentation.submitAlert(.first) == .applied)
        #expect(handle.dismiss() == .noChange(.notPresented))
        #expect(router.rootPresentation.presentedAlert?.destination == .first)
    }
}

extension NavigationRetentionTests {
    @Test func handleDoesNotKeepRouterAliveOrRequireTeardownNotification() {
        var router: Router? = Router(rootDestination: .home)
        weak var weakRouter = router
        let lifetime = NavigationPresentationLifetime()
        let observer = lifetime
        let handle = router.map { NavigationPresentationHandle(router: $0, lifetime: lifetime) }
        router?.rootPresentation.submitPresentation(.parent, lifetime: lifetime)
        router = nil
        #expect(weakRouter == nil)
        #expect(!observer.finished)
        #expect(handle?.dismiss() == .noChange(.notPresented))
    }

    @Test func routerTeardownDoesNotPretendClaimedPageHasPhysicallyClosed() throws {
        var router: Router? = Router(rootDestination: .home)
        let root = try #require(router?.rootPresentation)
        let lifetime = NavigationPresentationLifetime()
        let observer = lifetime
        root.submitPresentation(.parent, lifetime: lifetime)
        lifetime.claimHost()
        router = nil
        #expect(!observer.finished)
        root.presentationDidDismiss(lifetime: lifetime)
        #expect(observer.finished)
    }

    @Test func claimedAlertCompletionSurvivesRouterTeardown() throws {
        var router: Router? = Router(rootDestination: .home)
        let root = try #require(router?.rootPresentation)
        let lifetime = NavigationPresentationLifetime()
        let observer = lifetime
        root.submitAlert(.first, lifetime: lifetime)
        let alert = try #require(root.presentedAlert)
        let session = try #require(root.claimAlertSession(id: .business(alert.id)))
        router = nil
        #expect(!observer.finished)
        session.beginDismissal()
        #expect(session.beginCompletion())
        #expect(!session.beginCompletion())
        root.completeAlertSession(session)
        #expect(observer.finished)
        root.completeAlertSession(session)
        #expect(observer.finished)
    }

    @Test func rejectedCoreSubmissionsNeverCompleteTheirLifetime() throws {
        var router: Router? = Router(rootDestination: .home)
        let root = try #require(router?.rootPresentation)
        let lifetime = NavigationPresentationLifetime()
        let observer = lifetime
        #expect(root.submitPresentation(.parent, initialStack: .scope(.home), lifetime: lifetime)
            == .rejected(.incompatibleContainer))
        #expect(!observer.finished)
        #expect(!lifetime.finished)
        #expect(root.submitPresentation(.parent) == .applied)
        #expect(root.submitPresentation(.child, lifetime: lifetime) == .rejected(.presentationAlreadyExists))
        #expect(root.submitAlert(.first, lifetime: lifetime) == .rejected(.presentationAlreadyExists))
        #expect(!observer.finished)
        router = nil
        #expect(root.submitPresentation(.child, lifetime: lifetime) == .rejected(.inactiveContext))
        #expect(root.submitAlert(.first, lifetime: lifetime) == .rejected(.inactiveContext))
        #expect(!observer.finished)
        #expect(!lifetime.finished)
    }
}
