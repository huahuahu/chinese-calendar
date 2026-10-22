import Foundation
@testable import NavigationCore
import Testing

// swiftformat:disable:next modifierOrder
nonisolated private enum ResultTestAlert: NavigationAlertRoute {
    case first, second
    typealias Action = Bool
}

@MainActor
@Suite("呈现操作结果与拒绝原因")
struct NavigationPresentationResultTests {
    private enum Tab: NavigationScope { case home, history }
    private enum Route: NavigationDestination {
        case home, detail, tabs

        var providesNavigationContainer: Bool {
            self == .tabs
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, ResultTestAlert>

    @Test func invalidConfigurationReportsItsCauseWithoutChangingTheLayer() {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        let context = router.rootPresentation
        #expect(context.present(.detail, initialStack: .scope(.home)) == .rejected(.incompatibleContainer))
        #expect(context.present(.detail, rootDestinations: [.primary: .home]) == .rejected(.incompatibleContainer))
        #expect(context.present(.tabs) == .rejected(.missingRootDestination))
        #expect(context.present(
            .tabs, initialStack: .scope(.home), rootDestinations: [.scope(.home): .home],
            paths: [.scope(.history): []]
        ) == .rejected(.missingRootDestination))
        #expect(router.presentedNode == nil)
        #expect(router.rootLayer.queuedPresentations.isEmpty)
        #expect(router.rootLayer.paths == [.primary: [.detail]])
        #expect(context.present(.detail) == .applied)
        #expect(context.present(.home) == .rejected(.presentationAlreadyExists))
    }

    @Test func alertAndPageRequestsReportQueuedWithoutReplacingTheActiveAlert() throws {
        let router = Router(rootDestination: .home)
        let context = router.rootPresentation
        #expect(context.present(.alert(.first)) == .applied)
        let first = try #require(context.presentedAlert)
        #expect(context.presentAlert(.second) == .queued)
        #expect(context.present(.detail) == .queued)
        #expect(context.presentedAlert?.id == first.id)
        #expect(context.presentedNode == nil)
        #expect(router.rootLayer.queuedPresentations.count == 2)
        #expect(context.dismiss() == .noChange(.notPresented))
    }

    @Test func dismissReportsNoChangeOrQueueWithoutAdvancingThePresentation() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        #expect(root.dismissPresented(id: UUID()) == .noChange(.presentationNotFound))
        #expect(root.present(.detail) == .applied)
        let page = try #require(root.presentedNode)
        let context = router.presentationContext(for: page)
        #expect(context.presentAlert(.first) == .applied)
        #expect(root.dismissPresented(id: UUID()) == .noChange(.presentationNotFound))
        #expect(context.dismiss() == .queued)
        #expect(root.dismissPresented(id: page.id) == .queued)
        #expect(root.presentedNode === page)
        #expect(context.isActive)
        #expect(!router.isAwaitingPresentationDismissal)
    }

    @Test func dismissalInvalidatesOldOperationsAndSeparatesPageFromAlertWaiting() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        #expect(root.present(.detail) == .applied)
        let context = try router.presentationContext(for: #require(root.presentedNode))
        #expect(context.dismiss() == .applied)
        #expect(context.present(.home) == .rejected(.inactiveContext))
        #expect(context.presentAlert(.first) == .rejected(.inactiveContext))
        #expect(context.dismiss() == .rejected(.inactiveContext))
        #expect(context.setSelectedStack(.primary) == .rejected(.inactiveContext))
        #expect(root.present(.home) == .rejected(.awaitingDismissal))
        #expect(root.presentAlert(.first) == .queued)
        #expect(root.presentedContent == nil)
        root.presentationDidDismiss()
        #expect(root.presentedAlert?.destination == .first)
    }

    @Test func selectedStackAndScopedPresentationReportSpecificRejections() {
        let router = Router(
            rootDestination: .tabs, selectedScope: .home,
            rootDestinations: [.home: .home, .history: .detail]
        )
        let root = router.rootPresentation
        let background = root.scoped(to: .scope(.history))
        #expect(background.present(.detail) == .rejected(.sourceStackNotSelected))
        #expect(background.presentAlert(.first) == .rejected(.sourceStackNotSelected))
        #expect(root.setSelectedStack(.primary) == .rejected(.undeclaredStack))
        #expect(root.setSelectedStack(.scope(.history)) == .applied)
        #expect(root.setSelectedStack(.scope(.history)) == .applied)
        #expect(background.presentAlert(.first) == .applied)
        #expect(root.setSelectedStack(.scope(.home)) == .rejected(.alertInProgress))
        #expect(root.selectedStack == .scope(.history))

        let primary = Router(rootDestination: .home)
        #expect(primary.rootPresentation.setSelectedStack(.scope(.home)) == .rejected(.incompatibleContainer))
    }

    @Test func selectedStackCannotBypassPendingConfirmationOrDismissal() throws {
        let router = Router(
            rootDestination: .tabs, selectedScope: .home,
            rootDestinations: [.home: .home, .history: .detail]
        )
        let root = router.rootPresentation
        #expect(root.present(.detail) == .applied)
        #expect(router.submit(.selectScope(.history), confirmIfPresented: true) == .awaitingConfirmation)
        #expect(root.setSelectedStack(.scope(.history)) == .rejected(.awaitingConfirmation))
        let confirmation = try #require(router.pendingConfirmation)
        router.confirmNavigation(id: confirmation.id)
        #expect(root.setSelectedStack(.scope(.history)) == .rejected(.awaitingDismissal))
        #expect(root.selectedStack == .scope(.home))
        root.presentationDidDismiss()
        #expect(root.selectedStack == .scope(.history))
    }
}
