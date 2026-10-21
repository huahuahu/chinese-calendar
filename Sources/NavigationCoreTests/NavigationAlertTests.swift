import Foundation
@testable import NavigationCore
import Testing

// swiftformat:disable:next modifierOrder
nonisolated private enum AlertTestNotice: String, Codable, NavigationAlertRoute {
    case first, second
    typealias Action = Bool
}

@MainActor
@Suite("业务 alert 与导航的串行协调")
struct NavigationAlertTests {
    private enum Tab: String, Codable, NavigationScope { case home, history }
    private enum Route: String, Codable, NavigationDestination {
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
        #expect(context.present(.alert(.first)))
        let id = try beginAlert(context)
        #expect(router.submit(.push(.second, on: .history), confirmIfPresented: true) == .deferredUntilAlertDismisses)
        #expect(router.pendingConfirmation == nil)
        #expect(router.selectedScope == .home)
        #expect(!home.push(.third))
        #expect(!home.setPath([.third]))
        context.alertWillDismiss(id: id)
        #expect(!home.setPath([]))
        #expect(context.beginAlertCompletion(id: id))
        #expect(context.presentedAlert == nil)
        #expect(router.path(for: .history).isEmpty)
        #expect(router.hasActiveAlert)
        #expect(!home.setPath([]))
        context.alertDidDismiss(id: id)
        #expect(router.selectedScope == .history)
        #expect(router.path(for: .history) == [.second])
        #expect(router.path(for: .home) == [.first])
        #expect(!router.hasActiveAlert)
        #expect(home.setPath([.third]))
        #expect(home.path == [.third])
    }

    @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
    func modalAlertFinishesBeforeLeaveConfirmation(style: NavigationPresentationStyle) throws {
        let router = makeRouter()
        router.rootPresentation.present(.first, style: style)
        let page = try #require(router.presentedNode)
        let context = router.presentationContext(for: page)
        context.presentAlert(.first)
        let alertID = try beginAlert(context)
        router.submit(.push(.second, on: .history), confirmIfPresented: true)
        #expect(context.confirmation == nil)
        context.alertWillDismiss(id: alertID)
        #expect(context.beginAlertCompletion(id: alertID))
        #expect(context.confirmation == nil)
        context.alertDidDismiss(id: alertID)
        let confirmation = try #require(context.confirmation)
        #expect(router.presentedNode === page)
        #expect(context.alertWillPresent(id: confirmation.id, isConfirmation: true))
        context.alertWillDismiss(id: confirmation.id)
        #expect(context.beginAlertCompletion(id: confirmation.id))
        context.confirmNavigation(id: confirmation.id)
        #expect(router.presentedNode === page)
        context.alertDidDismiss(id: confirmation.id)
        #expect(router.presentedNode == nil)
        #expect(router.path(for: .history).isEmpty)
        router.rootPresentation.presentationDidDismiss()
        #expect(router.path(for: .history) == [.second])
    }

    @Test func cancelLeaveConfirmationKeepsOriginalModalAndPaths() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let page = try #require(router.sheet)
        let context = router.presentationContext(for: page)
        router.context(for: page).push(.second)
        let before = router.snapshot
        context.presentAlert(.first)
        let id = try beginAlert(context)
        router.submit(.push(.third, on: .history), confirmIfPresented: true)
        context.alertWillDismiss(id: id)
        #expect(context.beginAlertCompletion(id: id))
        context.alertDidDismiss(id: id)
        try context.cancelNavigation(id: #require(context.confirmation).id)
        #expect(router.snapshot == before)
    }

    @Test func queuedAlertsKeepOrderAndNavigationWaitsForAllOfThem() throws {
        let router = makeRouter()
        let context = router.rootPresentation
        context.presentAlert(.first)
        let first = try beginAlert(context)
        #expect(context.presentAlert(.second))
        router.submit(.push(.third, on: .history), confirmIfPresented: true)
        context.alertWillDismiss(id: first)
        #expect(router.selectedScope == .home)
        #expect(context.presentedAlert == nil)
        #expect(context.beginAlertCompletion(id: first))
        #expect(context.presentedAlert == nil)
        context.alertDidDismiss(id: first)
        #expect(context.presentedAlert?.destination == .second)
        #expect(router.selectedScope == .home)
        let second = try beginAlert(context)
        context.alertDidDismiss(id: first)
        #expect(context.presentedAlert?.id == second)
        context.alertWillDismiss(id: second)
        #expect(context.beginAlertCompletion(id: second))
        context.alertDidDismiss(id: second)
        #expect(router.path(for: .history) == [.third])
    }

    @Test func latestExternalRequestKeepsItsOwnConfirmationRequirement() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let context = try router.presentationContext(for: #require(router.sheet))
        context.presentAlert(.first)
        let id = try beginAlert(context)
        router.submit(.push(.second, on: .history))
        router.submit(.push(.third, on: .history), confirmIfPresented: true)
        context.alertWillDismiss(id: id)
        #expect(context.beginAlertCompletion(id: id))
        context.alertDidDismiss(id: id)
        #expect(context.confirmation?.request == .push(.third, on: .history))
        #expect(router.path(for: .history).isEmpty)
    }

    @Test func businessActionCanQueueResultBeforeExternalNavigationContinues() throws {
        let router = makeRouter()
        let context = router.rootPresentation
        context.presentAlert(.first)
        let id = try beginAlert(context)
        router.submit(.push(.third, on: .history), confirmIfPresented: true)
        context.alertWillDismiss(id: id)
        // 相当于原生关闭已完成、异步业务尚在执行：会话仍保留，不能提前跳转。
        #expect(context.beginAlertCompletion(id: id))
        context.alertWillDismiss(id: id)
        #expect(!context.beginAlertCompletion(id: id))
        #expect(context.presentAlert(.second))
        #expect(context.presentedAlert == nil)
        #expect(router.hasActiveAlert)
        #expect(router.selectedScope == .home)
        context.alertDidDismiss(id: id)
        #expect(context.presentedAlert?.destination == .second)
        #expect(router.requestWaitingForAlert == .push(.third, on: .history))
    }

    @Test(arguments: [true, false])
    func latestRequestAfterAlertWinsDuringModalDismissal(requiresConfirmation: Bool) throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let context = try router.presentationContext(for: #require(router.sheet))
        context.presentAlert(.first)
        let id = try beginAlert(context)
        router.submit(.push(.second, on: .history), confirmIfPresented: true)
        context.dismiss()
        context.alertWillDismiss(id: id)
        #expect(context.beginAlertCompletion(id: id))
        context.alertDidDismiss(id: id)
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
        context.presentAlert(.first)
        let id = try beginAlert(context)
        context.alertWillDismiss(id: id)
        #expect(context.beginAlertCompletion(id: id))
        #expect(router.submit(.push(.second, on: .history)) == .deferredUntilAlertDismisses)
        context.alertDidDismiss(id: id)
        #expect(router.pendingConfirmation == nil)
        #expect(router.isAwaitingPresentationDismissal)
        router.rootPresentation.presentationDidDismiss()
        #expect(router.path(for: .history) == [.second])
    }

    @Test func newConfirmationKeepsRequestApprovedDuringAlertCompletion() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let context = try router.presentationContext(for: #require(router.sheet))
        router.submit(.push(.second, on: .history), confirmIfPresented: true)
        let first = try #require(context.confirmation)
        #expect(context.alertWillPresent(id: first.id, isConfirmation: true))
        context.alertWillDismiss(id: first.id)
        #expect(context.beginAlertCompletion(id: first.id))
        context.confirmNavigation(id: first.id)

        router.submit(.push(.third, on: .history), confirmIfPresented: true)
        let second = try #require(router.pendingConfirmation)
        context.alertDidDismiss(id: first.id)
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
        context.presentAlert(.first)
        let id = try beginAlert(context)
        router.submit(.push(.second, on: .history))
        context.dismiss()
        context.alertWillDismiss(id: id)
        #expect(context.beginAlertCompletion(id: id))
        context.alertDidDismiss(id: id)

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
        let context = router.presentationContext(for: page)
        context.presentAlert(.first)
        let id = try beginAlert(context)
        #expect(context.dismiss())
        #expect(router.sheet === page)
        context.alertWillDismiss(id: id)
        #expect(context.beginAlertCompletion(id: id))
        context.alertDidDismiss(id: id)
        #expect(!context.isActive)
        router.rootPresentation.presentationDidDismiss()
        router.presentSheet(.second)
        #expect(!context.presentAlert(.second))
        context.alertDidDismiss(id: id)
        #expect(router.sheet?.destination == .second)
    }
}

extension NavigationAlertTests {
    @Test func backgroundTabCannotPresentAlert() {
        let router = makeRouter()
        #expect(!router.rootPresentation.scoped(to: .scope(.history)).presentAlert(.first))
        #expect(!router.hasActivePresentation)
    }

    @Test func closingModalDiscardsItsQueuedAlerts() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let context = try router.presentationContext(for: #require(router.sheet))
        context.presentAlert(.first)
        let id = try beginAlert(context)
        context.presentAlert(.second)
        #expect(router.alertRoutes == [.first, .second])
        context.dismiss()
        context.alertWillDismiss(id: id)
        #expect(!context.beginAlertCompletion(id: UUID()))
        #expect(context.beginAlertCompletion(id: id))
        context.alertDidDismiss(id: id)
        #expect(router.alertRoutes.isEmpty)
        #expect(!context.beginAlertCompletion(id: id))
    }

    @Test func customConfirmationCancellationResumesQueuedAlert() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let context = try router.presentationContext(for: #require(router.sheet))
        router.submit(.push(.second, on: .history), confirmIfPresented: true)
        let request = try #require(context.confirmation)
        #expect(context.presentAlert(.first))
        #expect(context.presentedAlert == nil)
        context.cancelNavigation(id: request.id)
        #expect(context.presentedAlert?.destination == .first)
        #expect(router.path(for: .history).isEmpty)
    }

    @Test func childDismissalFinishesBeforeParentShowsConfirmation() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let parent = try router.presentationContext(for: #require(router.sheet))
        parent.present(.second)
        let child = try router.presentationContext(for: #require(parent.presentedNode))
        child.dismiss()
        router.submit(.push(.third, on: .history), confirmIfPresented: true)
        #expect(parent.confirmation == nil)
        parent.presentationDidDismiss()
        #expect(parent.confirmation?.request == .push(.third, on: .history))
    }

    @Test func snapshotPreservesAlertDataWithoutCreatingAStackForIt() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let page = try #require(router.sheet)
        router.presentationContext(for: page).presentAlert(.second)
        let snapshot = router.snapshot
        #expect(snapshot.presentation?.alerts == [.second])
        #expect(router.presentations.count == 1)
        let data = try JSONEncoder().encode(snapshot)
        let restored = makeRouter(selectedScope: .history)
        #expect(try restored.restore(JSONDecoder().decode(NavigationSnapshot<Tab, Route, Notice>.self, from: data)))
        #expect(restored.snapshot == snapshot)
        let context = try restored.presentationContext(for: #require(restored.sheet))
        #expect(context.presentedAlert?.destination == .second)
    }

    @Test func cannotRestoreWhileAlertIsClosingOrItsActionIsRunning() throws {
        let router = makeRouter()
        let clean = router.snapshot
        let context = router.rootPresentation
        context.presentAlert(.first)
        let id = try beginAlert(context)
        context.alertWillDismiss(id: id)
        #expect(!router.restore(clean))
        #expect(context.beginAlertCompletion(id: id))
        #expect(!router.restore(clean))
        context.alertDidDismiss(id: id)
        #expect(router.restore(clean))
    }

    private func beginAlert(_ context: Presentation) throws -> UUID {
        let node = try #require(context.presentedAlert)
        #expect(context.alertWillPresent(id: node.id, isConfirmation: false))
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
