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
        let observer = FinishProbe(lifetime)
        let handle = NavigationPresentationHandle(router: router, lifetime: lifetime)
        #expect(router.rootPresentation.present(.parent, style: style, lifetime: lifetime) == .applied)
        #expect(handle.dismiss() == .applied)
        #expect(router.presentedNode == nil)
        #expect(!router.isAwaitingPresentationDismissal)
        #expect(observer.finishes == 1)
        #expect(handle.dismiss() == .noChange(.notPresented))
        router.rootPresentation.presentationDidDismiss(lifetime: lifetime)
        #expect(observer.finishes == 1)
    }

    @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
    func claimedPageWaitsForExactCompletionAndOldHandleCannotCloseNewPage(style: NavigationPresentationStyle) throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        let first = NavigationPresentationLifetime()
        let observer = FinishProbe(first)
        let handle = NavigationPresentationHandle(router: router, lifetime: first)
        root.present(.parent, style: style, lifetime: first)
        first.claimHost()
        #expect(handle.dismiss() == .applied)
        #expect(router.isAwaitingPresentationDismissal)
        #expect(observer.finishes == 0)
        #expect(handle.dismiss() == .queued)
        root.presentationDidDismiss(lifetime: NavigationPresentationLifetime())
        #expect(observer.finishes == 0)
        #expect(router.isAwaitingPresentationDismissal)
        root.presentationDidDismiss(lifetime: first)
        #expect(observer.finishes == 1)
        #expect(!router.isAwaitingPresentationDismissal)

        root.present(.parent, style: style)
        let newNode = try #require(router.presentedNode)
        newNode.lifetime.claimHost()
        #expect(handle.dismiss() == .noChange(.notPresented))
        root.presentationDidDismiss(lifetime: first)
        #expect(router.presentedNode === newNode)
        #expect(!newNode.lifetime.finished)
        #expect(observer.finishes == 1)
    }

    @Test func queuedCancellationFinishesOnceWithoutChangingRemainingFIFO() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        root.submitAlert(.first)
        let first = try #require(root.presentedAlert)
        let session = try #require(root.claimAlertSession(id: .business(first.id)))
        let cancelled = NavigationPresentationLifetime()
        let observer = FinishProbe(cancelled)
        let next = NavigationPresentationLifetime()
        #expect(root.submitAlert(.second, lifetime: cancelled) == .queued)
        #expect(root.present(.queued, lifetime: next) == .queued)
        let handle = NavigationPresentationHandle(router: router, lifetime: cancelled)
        #expect(handle.dismiss() == .applied)
        #expect(observer.finishes == 1)
        #expect(root.layer?.queuedPresentations.count == 1)
        #expect(root.layer?.queuedPresentations.first?.lifetime === next)
        #expect(handle.dismiss() == .noChange(.notPresented))
        root.alertWillDismiss(id: session.id)
        #expect(session.beginCompletion())
        root.completeAlertSession(session)
        #expect(root.presentedNode?.destination == .queued)
        #expect(root.presentedNode?.lifetime === next)
        #expect(observer.finishes == 1)
    }

    @Test func ancestorCompletionFinishesSubtreeAndRejectsChildCompletionForRootRequest() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        root.present(.parent)
        let parent = try #require(router.presentedNode)
        parent.lifetime.claimHost()
        let parentProbe = FinishProbe(parent.lifetime)
        let context = router.presentationContext(for: parent)
        context.present(.child)
        let child = try #require(parent.presentation)
        child.lifetime.claimHost()
        let childProbe = FinishProbe(child.lifetime)
        router.dismissPresentation(id: child.id)
        #expect(router.submit(.push(.queued, on: .primary)) == .deferredUntilPresentationDismisses)
        context.presentationDidDismiss(lifetime: child.lifetime)
        #expect(parentProbe.finishes == 0 && childProbe.finishes == 0)
        #expect(root.context(for: .primary).path.isEmpty)
        root.presentationDidDismiss(lifetime: parent.lifetime)
        #expect(parentProbe.finishes == 1 && childProbe.finishes == 1)
        #expect(root.context(for: .primary).path == [.queued])
        root.presentationDidDismiss(lifetime: parent.lifetime)
        #expect(parentProbe.finishes == 1 && childProbe.finishes == 1)
    }

    @Test func ancestorDismissalCancelsUnhostedQueueBeforeItsOwnCompletion() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        root.present(.parent)
        let parent = try #require(router.presentedNode)
        parent.lifetime.claimHost()
        let parentProbe = FinishProbe(parent.lifetime)
        let context = router.presentationContext(for: parent)
        context.submitAlert(.first)
        let alert = try #require(context.presentedAlert)
        let session = try #require(context.claimAlertSession(id: .business(alert.id)))
        let queued = NavigationPresentationLifetime()
        let queuedProbe = FinishProbe(queued)
        #expect(context.present(.queued, lifetime: queued) == .queued)
        #expect(context.dismiss() == .queued)
        context.alertWillDismiss(id: session.id)
        #expect(session.beginCompletion())
        context.completeAlertSession(session)
        #expect(queuedProbe.finishes == 1)
        #expect(parentProbe.finishes == 0)
        #expect(router.isAwaitingPresentationDismissal)
        root.presentationDidDismiss(lifetime: parent.lifetime)
        #expect(parentProbe.finishes == 1)
        #expect(queuedProbe.finishes == 1)
    }

    @Test func closingClaimedParentCancelsUnclaimedAlertWithoutShowingIt() throws {
        let router = Router(rootDestination: .home)
        router.rootPresentation.present(.parent)
        let parent = try #require(router.presentedNode)
        parent.lifetime.claimHost()
        let context = router.presentationContext(for: parent)
        let alert = NavigationPresentationLifetime()
        let observer = FinishProbe(alert)
        context.submitAlert(.first, lifetime: alert)
        #expect(context.dismiss() == .applied)
        #expect(observer.finishes == 1)
        #expect(!router.hasActiveAlert)
        #expect(router.isAwaitingPresentationDismissal)
        router.rootPresentation.presentationDidDismiss(lifetime: parent.lifetime)
        #expect(observer.finishes == 1)
    }
}

extension NavigationRetentionTests {
    @Test func finishCallbackRunsAfterExistingQueueHasAdvanced() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        let lifetime = NavigationPresentationLifetime()
        let observer = FinishProbe(lifetime)
        var reentrantResult: NavigationPresentationResult?
        observer.onFinish = { reentrantResult = root.present(.child) }
        root.submitAlert(.first, lifetime: lifetime)
        let alert = try #require(root.presentedAlert)
        let session = try #require(root.claimAlertSession(id: .business(alert.id)))
        #expect(root.present(.queued) == .queued)
        root.alertWillDismiss(id: session.id)
        #expect(session.beginCompletion())
        #expect(observer.finishes == 0)
        root.completeAlertSession(session)
        #expect(root.presentedNode?.destination == .queued)
        #expect(reentrantResult == .rejected(.presentationAlreadyExists))
        #expect(observer.finishes == 1)
    }

    @Test func finishCallbackSeesDeferredNavigationAlreadyApplied() {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        let lifetime = NavigationPresentationLifetime()
        let observer = FinishProbe(lifetime)
        var pathAtFinish: [Route] = []
        observer.onFinish = { pathAtFinish = root.context(for: .primary).path }
        root.present(.parent, lifetime: lifetime)
        lifetime.claimHost()
        #expect(router.submit(.push(.queued, on: .primary)) == .deferredUntilPresentationDismisses)
        #expect(observer.finishes == 0)
        root.presentationDidDismiss(lifetime: lifetime)
        #expect(pathAtFinish == [.queued])
        #expect(observer.finishes == 1)
    }

    @Test func alertHandleWaitsForSystemCompletionAndBusinessAction() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        let lifetime = NavigationPresentationLifetime()
        let observer = FinishProbe(lifetime)
        root.submitAlert(.first, lifetime: lifetime)
        let alert = try #require(root.presentedAlert)
        let session = try #require(root.claimAlertSession(id: .business(alert.id)))
        let handle = NavigationPresentationHandle(router: router, lifetime: lifetime)
        #expect(handle.dismiss() == .applied)
        #expect(root.presentedAlert == nil)
        #expect(router.hasActiveAlert)
        #expect(observer.finishes == 0)
        root.completeAlertSession(session)
        #expect(observer.finishes == 0)
        session.beginDismissal()
        #expect(session.beginCompletion())
        #expect(!session.beginCompletion())
        #expect(observer.finishes == 0)
        root.completeAlertSession(session)
        #expect(observer.finishes == 1)
        #expect(!router.hasActiveAlert)
        root.completeAlertSession(session)
        #expect(observer.finishes == 1)
    }

    @Test func physicalAncestorCompletionStillWaitsForDescendantAlertAction() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        root.present(.parent)
        let parent = try #require(router.presentedNode)
        parent.lifetime.claimHost()
        let parentProbe = FinishProbe(parent.lifetime)
        let context = router.presentationContext(for: parent)
        context.submitAlert(.first)
        let alert = try #require(context.presentedAlert)
        let alertProbe = FinishProbe(alert.lifetime)
        let session = try #require(context.claimAlertSession(id: .business(alert.id)))
        context.alertWillDismiss(id: session.id)
        #expect(session.beginCompletion())
        #expect(router.submit(.push(.queued, on: .primary)) == .deferredUntilAlertDismisses)
        root.presentationDidDismiss(lifetime: parent.lifetime)
        #expect(parentProbe.finishes == 0 && alertProbe.finishes == 0)
        #expect(router.isAwaitingPresentationDismissal)
        #expect(root.context(for: .primary).path.isEmpty)
        context.completeAlertSession(session)
        #expect(parentProbe.finishes == 1 && alertProbe.finishes == 1)
        #expect(root.context(for: .primary).path == [.queued])
        #expect(!router.isAwaitingPresentationDismissal)
    }

    @Test func unclaimedAlertCancellationDoesNotNeedSystemCallback() {
        let router = Router(rootDestination: .home)
        let lifetime = NavigationPresentationLifetime()
        let observer = FinishProbe(lifetime)
        router.rootPresentation.submitAlert(.first, lifetime: lifetime)
        let handle = NavigationPresentationHandle(router: router, lifetime: lifetime)
        #expect(handle.dismiss() == .applied)
        #expect(observer.finishes == 1)
        #expect(!router.hasActiveAlert)
        #expect(router.rootPresentation.submitAlert(.first) == .applied)
        #expect(handle.dismiss() == .noChange(.notPresented))
        #expect(router.rootPresentation.presentedAlert?.destination == .first)
    }
}

extension NavigationRetentionTests {
    @Test func handleDoesNotKeepRouterAliveAndTeardownFinishesUnclaimedRequests() {
        var router: Router? = Router(rootDestination: .home)
        weak var weakRouter = router
        let lifetime = NavigationPresentationLifetime()
        let observer = FinishProbe(lifetime)
        let handle = router.map { NavigationPresentationHandle(router: $0, lifetime: lifetime) }
        router?.rootPresentation.present(.parent, lifetime: lifetime)
        router = nil
        #expect(weakRouter == nil)
        #expect(observer.finishes == 1)
        #expect(handle?.dismiss() == .noChange(.notPresented))
    }

    @Test func routerTeardownDoesNotPretendClaimedPageHasPhysicallyClosed() throws {
        var router: Router? = Router(rootDestination: .home)
        let root = try #require(router?.rootPresentation)
        let lifetime = NavigationPresentationLifetime()
        let observer = FinishProbe(lifetime)
        root.present(.parent, lifetime: lifetime)
        lifetime.claimHost()
        router = nil
        #expect(observer.finishes == 0)
        root.presentationDidDismiss(lifetime: lifetime)
        #expect(observer.finishes == 1)
    }

    @Test func claimedAlertCompletionSurvivesRouterTeardown() throws {
        var router: Router? = Router(rootDestination: .home)
        let root = try #require(router?.rootPresentation)
        let lifetime = NavigationPresentationLifetime()
        let observer = FinishProbe(lifetime)
        root.submitAlert(.first, lifetime: lifetime)
        let alert = try #require(root.presentedAlert)
        let session = try #require(root.claimAlertSession(id: .business(alert.id)))
        router = nil
        #expect(observer.finishes == 0)
        session.beginDismissal()
        #expect(session.beginCompletion())
        #expect(!session.beginCompletion())
        root.completeAlertSession(session)
        #expect(observer.finishes == 1)
        root.completeAlertSession(session)
        #expect(observer.finishes == 1)
    }

    @Test func lifetimeDoesNotOwnItsHostObserver() {
        let lifetime = NavigationPresentationLifetime()
        var observer: FinishProbe? = FinishProbe(lifetime)
        weak var weakObserver = observer
        observer = nil
        #expect(weakObserver == nil)
        lifetime.finish()
        #expect(lifetime.finished)
    }

    @Test func rejectedCoreSubmissionsNeverCompleteTheirLifetime() throws {
        var router: Router? = Router(rootDestination: .home)
        let root = try #require(router?.rootPresentation)
        let lifetime = NavigationPresentationLifetime()
        let observer = FinishProbe(lifetime)
        #expect(root.present(.parent, initialStack: .scope(.home), lifetime: lifetime)
            == .rejected(.incompatibleContainer))
        #expect(observer.finishes == 0)
        #expect(!lifetime.finished)
        #expect(root.present(.parent) == .applied)
        #expect(root.present(.child, lifetime: lifetime) == .rejected(.presentationAlreadyExists))
        #expect(root.submitAlert(.first, lifetime: lifetime) == .rejected(.presentationAlreadyExists))
        #expect(observer.finishes == 0)
        router = nil
        #expect(root.present(.child, lifetime: lifetime) == .rejected(.inactiveContext))
        #expect(root.submitAlert(.first, lifetime: lifetime) == .rejected(.inactiveContext))
        #expect(observer.finishes == 0)
        #expect(!lifetime.finished)
    }

    @Test(arguments: [false, true])
    func detachedAncestorWaitsForDescendantAlertAndFinishesChildrenFirst(actionFinishesFirst: Bool) throws {
        var router: Router? = Router(rootDestination: .home)
        weak var weakRouter = router
        let root = try #require(router?.rootPresentation)
        root.present(.parent)
        let parent = try #require(router?.presentedNode)
        parent.lifetime.claimHost()
        let parentProbe = FinishProbe(parent.lifetime)
        let parentContext = try #require(router?.presentationContext(for: parent))
        parentContext.present(.child)
        let child = try #require(parent.presentation)
        child.lifetime.claimHost()
        let childProbe = FinishProbe(child.lifetime)
        let childContext = try #require(router?.presentationContext(for: child))
        childContext.submitAlert(.first)
        let alert = try #require(childContext.presentedAlert)
        let alertProbe = FinishProbe(alert.lifetime)
        let session = try #require(childContext.claimAlertSession(id: .business(alert.id)))
        var order: [String] = []
        parentProbe.onFinish = { order.append("parent") }
        childProbe.onFinish = { order.append("child") }
        alertProbe.onFinish = { order.append("alert") }
        childContext.alertWillDismiss(id: session.id)
        #expect(session.beginCompletion())
        router = nil
        #expect(weakRouter == nil)
        #expect(order.isEmpty)
        if actionFinishesFirst {
            childContext.completeAlertSession(session)
            #expect(order == ["alert"])
            root.presentationDidDismiss(lifetime: parent.lifetime)
        } else {
            root.presentationDidDismiss(lifetime: parent.lifetime)
            #expect(order.isEmpty)
            childContext.completeAlertSession(session)
        }
        #expect(order == ["alert", "child", "parent"])
        root.presentationDidDismiss(lifetime: parent.lifetime)
        parentContext.presentationDidDismiss(lifetime: child.lifetime)
        childContext.completeAlertSession(session)
        #expect(order == ["alert", "child", "parent"])
    }

    @Test func routerTeardownPreservesAnAlreadyReceivedPhysicalCompletion() throws {
        var router: Router? = Router(rootDestination: .home)
        let root = try #require(router?.rootPresentation)
        root.present(.parent)
        let parent = try #require(router?.presentedNode)
        parent.lifetime.claimHost()
        let parentProbe = FinishProbe(parent.lifetime)
        let context = try #require(router?.presentationContext(for: parent))
        context.submitAlert(.first)
        let alert = try #require(context.presentedAlert)
        let session = try #require(context.claimAlertSession(id: .business(alert.id)))
        context.alertWillDismiss(id: session.id)
        #expect(session.beginCompletion())
        root.presentationDidDismiss(lifetime: parent.lifetime)
        #expect(parent.didCompletePhysicalDismissal)
        #expect(parentProbe.finishes == 0)
        router = nil
        #expect(parentProbe.finishes == 0)
        context.completeAlertSession(session)
        #expect(parentProbe.finishes == 1)
    }

    @Test func detachedAncestorAlsoWaitsForFrameworkConfirmationCompletion() throws {
        var router: Router? = Router(rootDestination: .home)
        let root = try #require(router?.rootPresentation)
        root.present(.parent)
        let parent = try #require(router?.presentedNode)
        parent.lifetime.claimHost()
        let parentProbe = FinishProbe(parent.lifetime)
        let context = try #require(router?.presentationContext(for: parent))
        #expect(router?.submit(.push(.queued, on: .primary), confirmIfPresented: true) == .awaitingConfirmation)
        let confirmation = try #require(context.confirmation)
        let session = try #require(context.claimAlertSession(id: .confirmation(confirmation.id)))
        #expect(session.lifetime == nil)
        router = nil
        root.presentationDidDismiss(lifetime: parent.lifetime)
        #expect(parentProbe.finishes == 0)
        session.beginDismissal()
        #expect(session.beginCompletion())
        context.completeAlertSession(session)
        #expect(parentProbe.finishes == 1)
    }

    @MainActor
    private final class FinishProbe: NavigationPresentationLifetimeObserver {
        var finishes = 0
        var onFinish: (() -> Void)?

        init(_ lifetime: NavigationPresentationLifetime) {
            lifetime.observer = self
        }

        func presentationLifetimeDidFinish(_: NavigationPresentationLifetime) {
            finishes += 1
            onFinish?()
        }
    }
}
