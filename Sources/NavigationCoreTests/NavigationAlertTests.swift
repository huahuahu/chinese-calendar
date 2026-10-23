import Foundation
@testable import NavigationCore
import Testing

// swiftformat:disable:next modifierOrder
nonisolated private enum AlertTestNotice: String, NavigationAlertRoute {
    case first, second
}

@MainActor
@Suite("业务 alert 与导航的串行协调")
struct NavigationAlertTests {
    private enum Tab: String, NavigationScope { case home, history }
    private enum Route: String, NavigationDestination {
        case root, first, second, third
        var providesNavigationContainer: Bool {
            self == .root
        }
    }

    private typealias Notice = AlertTestNotice

    private typealias Router = NavigationRouter<Tab, Route, Notice>
    private typealias Presentation = NavigationPresentationContext<Tab, Route, Notice>

    @Test func rootAlertQueuesNavigationUntilActualDismissal() throws {
        let router = makeRouter(paths: [.home: [.first]])
        let context = router.rootPresentation
        let home = router.context(for: .home)
        #expect(context.present(.alert(.first), lifetime: NavigationPresentationLifetime()) == .applied)
        let id = try beginAlert(context)
        #expect(router.submit(.push(.second, on: .history), confirmIfPresented: true) == .deferredUntilAlertDismisses)
        #expect(router.pendingConfirmation == nil)
        #expect(router.selectedScope == .home)
        #expect(home.push(.third) == .rejected(.alertInProgress))
        #expect(home.setPath([.third]) == .rejected(.alertInProgress))
        context.alertWillDismiss(id: .business(id))
        #expect(home.setPath([]) == .rejected(.alertInProgress))
        #expect(context.beginAlertCompletion(id: .business(id)))
        #expect(context.presentedAlert == nil)
        #expect(router.path(for: .history).isEmpty)
        #expect(router.hasActiveAlert)
        #expect(home.setPath([]) == .rejected(.alertInProgress))
        context.alertDidDismiss(id: .business(id))
        #expect(router.selectedScope == .history)
        #expect(router.path(for: .history) == [.second])
        #expect(router.path(for: .home) == [.first])
        #expect(!router.hasActiveAlert)
        #expect(home.setPath([.third]) == .applied)
        #expect(home.path == [.third])
    }

    @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
    func modalAlertFinishesBeforeLeaveConfirmation(style: NavigationPresentationStyle) throws {
        let router = makeRouter()
        router.rootPresentation.present(.first, style: style)
        let page = try #require(router.presentedNode)
        page.lifetime.claimHost()
        let context = router.presentationContext(for: page)
        context.submitAlert(.first)
        let alertID = try beginAlert(context)
        router.submit(.push(.second, on: .history), confirmIfPresented: true)
        #expect(context.confirmation == nil)
        context.alertWillDismiss(id: .business(alertID))
        #expect(context.beginAlertCompletion(id: .business(alertID)))
        #expect(context.confirmation == nil)
        context.alertDidDismiss(id: .business(alertID))
        let confirmation = try #require(context.confirmation)
        #expect(router.presentedNode === page)
        #expect(context.alertWillPresent(id: .confirmation(confirmation.id)))
        context.alertWillDismiss(id: .confirmation(confirmation.id))
        #expect(context.beginAlertCompletion(id: .confirmation(confirmation.id)))
        context.confirmNavigation(id: confirmation.id)
        #expect(router.presentedNode === page)
        context.alertDidDismiss(id: .confirmation(confirmation.id))
        #expect(router.presentedNode == nil)
        #expect(router.path(for: .history).isEmpty)
        router.rootPresentation.presentationDidDismiss()
        #expect(router.path(for: .history) == [.second])
    }

    @Test func cancelLeaveConfirmationKeepsOriginalModalAndPaths() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let page = try #require(router.sheet)
        page.lifetime.claimHost()
        let context = router.presentationContext(for: page)
        router.context(for: page).push(.second)
        context.submitAlert(.first)
        let id = try beginAlert(context)
        router.submit(.push(.third, on: .history), confirmIfPresented: true)
        context.alertWillDismiss(id: .business(id))
        #expect(context.beginAlertCompletion(id: .business(id)))
        context.alertDidDismiss(id: .business(id))
        try context.cancelNavigation(id: #require(context.confirmation).id)
        #expect(router.sheet === page)
        #expect(page.path == [.second])
        #expect(page.presentation == nil)
        #expect(context.presentedAlert == nil)
        #expect(router.selectedScope == .home)
        #expect(router.paths.isEmpty)
    }

    @Test func queuedAlertsKeepOrderAndNavigationWaitsForAllOfThem() throws {
        let router = makeRouter()
        let context = router.rootPresentation
        context.submitAlert(.first)
        let first = try beginAlert(context)
        #expect(context.submitAlert(.second) == .queued)
        router.submit(.push(.third, on: .history), confirmIfPresented: true)
        context.alertWillDismiss(id: .business(first))
        #expect(router.selectedScope == .home)
        #expect(context.presentedAlert == nil)
        #expect(context.beginAlertCompletion(id: .business(first)))
        #expect(context.presentedAlert == nil)
        context.alertDidDismiss(id: .business(first))
        #expect(context.presentedAlert?.destination == .second)
        #expect(router.selectedScope == .home)
        let second = try beginAlert(context)
        context.alertDidDismiss(id: .business(first))
        #expect(context.presentedAlert?.id == second)
        context.alertWillDismiss(id: .business(second))
        #expect(context.beginAlertCompletion(id: .business(second)))
        context.alertDidDismiss(id: .business(second))
        #expect(router.path(for: .history) == [.third])
    }

    @Test func latestExternalRequestKeepsItsOwnConfirmationRequirement() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let context = try router.presentationContext(for: #require(router.sheet))
        router.sheet?.lifetime.claimHost()
        context.submitAlert(.first)
        let id = try beginAlert(context)
        router.submit(.push(.second, on: .history))
        router.submit(.push(.third, on: .history), confirmIfPresented: true)
        context.alertWillDismiss(id: .business(id))
        #expect(context.beginAlertCompletion(id: .business(id)))
        context.alertDidDismiss(id: .business(id))
        #expect(context.confirmation?.request == .push(.third, on: .history))
        #expect(router.path(for: .history).isEmpty)
    }

    @Test func businessActionCanQueueResultBeforeExternalNavigationContinues() throws {
        let router = makeRouter()
        let context = router.rootPresentation
        context.submitAlert(.first)
        let id = try beginAlert(context)
        router.submit(.push(.third, on: .history), confirmIfPresented: true)
        context.alertWillDismiss(id: .business(id))
        // 相当于原生关闭已完成、异步业务尚在执行：会话仍保留，不能提前跳转。
        #expect(context.beginAlertCompletion(id: .business(id)))
        context.alertWillDismiss(id: .business(id))
        #expect(!context.beginAlertCompletion(id: .business(id)))
        #expect(context.submitAlert(.second) == .queued)
        #expect(context.presentedAlert == nil)
        #expect(router.hasActiveAlert)
        #expect(router.selectedScope == .home)
        context.alertDidDismiss(id: .business(id))
        #expect(context.presentedAlert?.destination == .second)
        #expect(router.requestWaitingForAlert == .push(.third, on: .history))
    }

    @Test(arguments: [true, false])
    func latestRequestAfterAlertWinsDuringModalDismissal(requiresConfirmation: Bool) throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let context = try router.presentationContext(for: #require(router.sheet))
        router.sheet?.lifetime.claimHost()
        context.submitAlert(.first)
        let id = try beginAlert(context)
        router.submit(.push(.second, on: .history), confirmIfPresented: true)
        context.dismiss()
        context.alertWillDismiss(id: .business(id))
        #expect(context.beginAlertCompletion(id: .business(id)))
        context.alertDidDismiss(id: .business(id))
        #expect(router.isAwaitingPresentationDismissal)

        router.submit(.push(.third, on: .history), confirmIfPresented: requiresConfirmation)
        #expect(router.requestWaitingForAlert == nil)
        router.rootPresentation.presentationDidDismiss()

        if requiresConfirmation {
            let confirmation = try #require(router.pendingConfirmation)
            #expect(confirmation.request == .push(.third, on: .history))
            #expect(router.path(for: .history).isEmpty)
            router.confirmNavigation(id: confirmation.id)
        }
        #expect(router.path(for: .history) == [.third])
        #expect(router.pendingConfirmation == nil)
    }

    @Test func alertActionNavigationWaitsForAlertAndThenModalDismissal() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let context = try router.presentationContext(for: #require(router.sheet))
        router.sheet?.lifetime.claimHost()
        context.submitAlert(.first)
        let id = try beginAlert(context)
        context.alertWillDismiss(id: .business(id))
        #expect(context.beginAlertCompletion(id: .business(id)))
        #expect(router.submit(.push(.second, on: .history)) == .deferredUntilAlertDismisses)
        context.alertDidDismiss(id: .business(id))
        #expect(router.pendingConfirmation == nil)
        #expect(router.isAwaitingPresentationDismissal)
        router.rootPresentation.presentationDidDismiss()
        #expect(router.path(for: .history) == [.second])
    }

    @Test func newConfirmationKeepsRequestApprovedDuringAlertCompletion() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let context = try router.presentationContext(for: #require(router.sheet))
        router.sheet?.lifetime.claimHost()
        router.submit(.push(.second, on: .history), confirmIfPresented: true)
        let first = try #require(context.confirmation)
        #expect(context.alertWillPresent(id: .confirmation(first.id)))
        context.alertWillDismiss(id: .confirmation(first.id))
        #expect(context.beginAlertCompletion(id: .confirmation(first.id)))
        context.confirmNavigation(id: first.id)

        router.submit(.push(.third, on: .history), confirmIfPresented: true)
        let second = try #require(router.pendingConfirmation)
        context.alertDidDismiss(id: .confirmation(first.id))
        #expect(router.isAwaitingPresentationDismissal)
        router.rootPresentation.presentationDidDismiss()
        #expect(router.path(for: .history) == [.second])
        #expect(router.pendingConfirmation?.id == second.id)
        router.cancelConfirmation(id: second.id)
        #expect(router.path(for: .history) == [.second])
    }

    @Test func newConfirmationKeepsAcceptedRequestAfterBusinessAlertEnds() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let context = try router.presentationContext(for: #require(router.sheet))
        router.sheet?.lifetime.claimHost()
        context.submitAlert(.first)
        let id = try beginAlert(context)
        router.submit(.push(.second, on: .history))
        context.dismiss()
        context.alertWillDismiss(id: .business(id))
        #expect(context.beginAlertCompletion(id: .business(id)))
        context.alertDidDismiss(id: .business(id))

        router.submit(.push(.third, on: .history), confirmIfPresented: true)
        let confirmation = try #require(router.pendingConfirmation)
        router.rootPresentation.presentationDidDismiss()
        #expect(router.path(for: .history) == [.second])
        #expect(router.pendingConfirmation?.id == confirmation.id)
        router.cancelConfirmation(id: confirmation.id)
        #expect(router.path(for: .history) == [.second])
    }

    @Test func dismissingModalWaitsForAlertAndInvalidatesItsContext() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let page = try #require(router.sheet)
        page.lifetime.claimHost()
        let context = router.presentationContext(for: page)
        context.submitAlert(.first)
        let id = try beginAlert(context)
        #expect(context.dismiss() == .queued)
        #expect(router.sheet === page)
        context.alertWillDismiss(id: .business(id))
        #expect(context.beginAlertCompletion(id: .business(id)))
        context.alertDidDismiss(id: .business(id))
        #expect(!context.isActive)
        router.rootPresentation.presentationDidDismiss()
        router.presentSheet(.second)
        router.frontmostPresentationNode?.lifetime.claimHost()
        #expect(context.submitAlert(.second) == .rejected(.inactiveContext))
        context.alertDidDismiss(id: .business(id))
        #expect(router.sheet?.destination == .second)
    }
}

extension NavigationAlertTests {
    @Test func backgroundTabCannotPresentAlert() {
        let router = makeRouter()
        #expect(router.rootPresentation.scoped(to: .scope(.history))
            .submitAlert(.first) == .rejected(.sourceStackNotSelected))
        #expect(!router.hasActivePresentation)
    }

    @Test func closingModalDiscardsItsQueuedAlerts() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let context = try router.presentationContext(for: #require(router.sheet))
        router.sheet?.lifetime.claimHost()
        context.submitAlert(.first)
        let id = try beginAlert(context)
        context.submitAlert(.second)
        #expect(context.presentedAlert?.destination == .first)
        #expect(context.layer?.queuedPresentations.count == 1)
        context.dismiss()
        context.alertWillDismiss(id: .business(id))
        #expect(!context.beginAlertCompletion(id: .business(NavigationAlertID())))
        #expect(context.beginAlertCompletion(id: .business(id)))
        context.alertDidDismiss(id: .business(id))
        #expect(!router.hasActiveAlert)
        #expect(context.layer?.queuedPresentations.isEmpty == true)
        #expect(!context.beginAlertCompletion(id: .business(id)))
    }

    @Test func customConfirmationCancellationResumesQueuedAlert() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let context = try router.presentationContext(for: #require(router.sheet))
        router.sheet?.lifetime.claimHost()
        router.submit(.push(.second, on: .history), confirmIfPresented: true)
        let request = try #require(context.confirmation)
        #expect(context.submitAlert(.first) == .queued)
        #expect(context.presentedAlert == nil)
        context.cancelNavigation(id: request.id)
        #expect(context.presentedAlert?.destination == .first)
        #expect(router.path(for: .history).isEmpty)
    }

    @Test func childDismissalFinishesBeforeParentShowsConfirmation() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let parent = try router.presentationContext(for: #require(router.sheet))
        router.sheet?.lifetime.claimHost()
        parent.present(.second)
        let child = try router.presentationContext(for: #require(parent.presentedNode))
        parent.presentedNode?.lifetime.claimHost()
        child.dismiss()
        router.submit(.push(.third, on: .history), confirmIfPresented: true)
        #expect(parent.confirmation == nil)
        parent.presentationDidDismiss()
        #expect(parent.confirmation?.request == .push(.third, on: .history))
    }

    @Test func alertDoesNotCreateAnotherNavigationLayerOrStack() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let page = try #require(router.sheet)
        page.lifetime.claimHost()
        let context = router.presentationContext(for: page)
        #expect(context.submitAlert(.second) == .applied)
        #expect(router.presentations.count == 1)
        #expect(context.presentedAlert?.destination == .second)
        #expect(page.presentation == nil)
        #expect(page.layer.roots == [.primary: .first])
        #expect(page.layer.paths.isEmpty)
    }

    private func beginAlert(_ context: Presentation) throws -> NavigationAlertID {
        let node = try #require(context.presentedAlert)
        #expect(context.alertWillPresent(id: .business(node.id)))
        return node.id
    }
}

private extension NavigationAlertTests {
    private func makeRouter(selectedScope: Tab = .home, paths: [Tab: [Route]] = [:]) -> Router {
        Router(
            rootDestination: .root, selectedScope: selectedScope,
            rootDestinations: [.home: .first, .history: .second], paths: paths
        )
    }
}
