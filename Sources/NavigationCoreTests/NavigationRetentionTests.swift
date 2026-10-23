import Foundation
@testable import NavigationCore
import Observation
import Synchronization
import Testing

// swiftformat:disable:next modifierOrder
nonisolated private enum RetentionTestAlert: NavigationAlertRoute {
    case notice
    typealias Action = Bool
}

@MainActor
@Suite("呈现会话保留与关闭完成")
struct NavigationRetentionTests {
    private enum Tab: NavigationScope { case home }
    private enum Route: NavigationDestination { case home, parent, child, queued }
    private typealias Router = NavigationRouter<Tab, Route, RetentionTestAlert>

    @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
    func childCompletionReleasesOnlyItsSession(style: NavigationPresentationStyle) throws {
        let router = Router(rootDestination: .home)
        router.rootPresentation.present(.parent, style: style)
        let parent = try #require(router.presentedNode)
        let context = router.presentationContext(for: parent)
        context.present(.child)
        let child = try #require(parent.presentation)
        let navigation = router.context(for: child)
        router.dismissPresentation(id: child.id)
        #expect(!navigation.isActive)
        #expect(router.retains(navigation))
        #expect(router.retainedPresentationRoutes.map(\.destination) == [.parent, .child])
        context.presentationDidDismiss()
        #expect(router.retainedPresentationRoutes == [context.route])
        #expect(!router.retains(navigation))
        #expect(router.retains(router.context(for: parent)))
        #expect(router.retains(router.rootPresentation.context(for: .primary)))
        context.presentationDidDismiss()
        #expect(router.retainedPresentationRoutes == [context.route])
    }

    @Test func ancestorCompletionReleasesAlreadyClosingDescendantsWithoutReleasingNewPages() throws {
        let router = Router(rootDestination: .home)
        router.presentSheet(.parent)
        let parent = try #require(router.presentedNode)
        let context = router.presentationContext(for: parent)
        context.present(.child)
        let child = try #require(parent.presentation)
        router.dismissPresentation(id: child.id)
        #expect(router.submit(.push(.queued, on: .primary)) == .deferredUntilPresentationDismisses)
        #expect(router.retainedPresentationRoutes.map(\.destination) == [.parent, .child])
        context.presentationDidDismiss()
        #expect(router.retainedPresentationRoutes.count == 2)
        #expect(router.rootPresentation.context(for: .primary).path.isEmpty)
        router.rootPresentation.presentationDidDismiss()
        #expect(router.retainedPresentationRoutes.isEmpty)
        #expect(router.rootPresentation.context(for: .primary).path == [.queued])
        router.presentSheet(.parent)
        let reopened = try #require(router.presentedNode)
        router.rootPresentation.presentationDidDismiss()
        context.presentationDidDismiss()
        #expect(router.retainedPresentationRoutes == [.presentation(id: reopened.id, destination: .parent)])
        #expect(reopened.id != parent.id)
    }

    @Test func queuedPagesSurviveWaitingAndDisappearWhenTheirOwnerFinishes() throws {
        let router = Router(rootDestination: .home)
        router.presentSheet(.parent)
        let parent = try #require(router.presentedNode)
        let context = router.presentationContext(for: parent)
        context.presentAlert(.notice)
        let alert = try #require(context.presentedAlert)
        #expect(context.alertWillPresent(id: .business(alert.id)))
        #expect(context.present(.queued) == .queued)
        #expect(router.retainedPresentationRoutes.map(\.destination) == [.parent, .queued])
        #expect(context.dismiss() == .queued)
        context.alertWillDismiss(id: .business(alert.id))
        #expect(context.beginAlertCompletion(id: .business(alert.id)))
        context.alertDidDismiss(id: .business(alert.id))
        #expect(router.presentedNode == nil)
        #expect(router.retainedPresentationRoutes.map(\.destination) == [.parent, .queued])
        router.rootPresentation.presentationDidDismiss()
        #expect(router.retainedPresentationRoutes.isEmpty)
        #expect(router.alertRoutes.isEmpty)
    }

    @Test func cancellingRootQueueNeedsNoPageDismissalCallback() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        root.presentAlert(.notice)
        let alert = try #require(root.presentedAlert)
        #expect(root.alertWillPresent(id: .business(alert.id)))
        #expect(root.present(.queued) == .queued)
        #expect(router.retainedPresentationRoutes.map(\.destination) == [.queued])
        #expect(router.dismissAllPresentations() == .queued)
        root.alertWillDismiss(id: .business(alert.id))
        #expect(root.beginAlertCompletion(id: .business(alert.id)))
        root.alertDidDismiss(id: .business(alert.id))
        #expect(router.retainedPresentationRoutes.isEmpty)
        #expect(!router.isAwaitingPresentationDismissal)
    }

    @Test func retainedRoutesPublishActualCompletionAndDoNotKeepTheTreeAlive() throws {
        var router: Router? = Router(rootDestination: .home)
        router?.presentSheet(.parent)
        weak var node = router?.presentedNode
        let root = try #require(router?.rootPresentation)
        router?.dismissSheet()
        #expect(node != nil)
        let changes = Mutex(0)
        withObservationTracking {
            _ = router?.retainedPresentationRoutes
        } onChange: {
            changes.withLock { $0 += 1 }
        }
        root.presentationDidDismiss()
        #expect(changes.withLock { $0 } > 0)
        #expect(node == nil)
        root.present(.child)
        weak var child = router?.presentedNode
        router?.dismissSheet()
        #expect(child != nil)
        router = nil
        #expect(child == nil)
        #expect(!root.isActive)
    }
}
