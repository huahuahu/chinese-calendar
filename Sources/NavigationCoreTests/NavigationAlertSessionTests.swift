import Foundation
@testable import NavigationCore
import Testing

// swiftformat:disable:next modifierOrder
nonisolated private enum SessionTestNotice: String, NavigationAlertRoute {
    case first, second
}

@MainActor
@Suite("提示会话的生命周期约束")
struct NavigationAlertSessionTests {
    private enum Tab: String, NavigationScope { case home, history }
    private enum Route: String, NavigationDestination {
        case root, first, second
        var providesNavigationContainer: Bool {
            self == .root
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, SessionTestNotice>
    private typealias Presentation = NavigationPresentationContext<Tab, Route, SessionTestNotice>
    typealias State = NavigationAlertSession.State

    @Test(arguments: [false, true])
    func completionRequiresDismissalAndCannotReleaseEarly(isConfirmation: Bool) throws {
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second]
        )
        router.presentSheet(.first)
        let context = try router.presentationContext(for: #require(router.sheet))
        router.sheet?.lifetime.claimHost()
        let id: NavigationSystemAlertID
        if isConfirmation {
            router.submit(.push(.second, on: .history), confirmIfPresented: true)
            id = try .confirmation(#require(context.confirmation).id)
        } else {
            context.submitAlert(.first)
            id = try .business(#require(context.presentedAlert).id)
        }
        #expect(context.alertWillPresent(id: id))
        #expect(context.layer?.alertSession?.state == .presented)
        #expect(context.layer?.alertSession?.id == id)
        #expect(!context.alertWillPresent(id: id))
        #expect(!context.beginAlertCompletion(id: id))
        context.alertDidDismiss(id: id)
        #expect(context.layer?.alertSession?.state == .presented)

        context.alertWillDismiss(id: id)
        context.alertWillDismiss(id: id)
        context.alertDidDismiss(id: id)
        #expect(context.layer?.alertSession?.state == .dismissing)
        #expect(router.hasActiveAlert)
        #expect(context.presentedAlert == nil)
        #expect(router.path(for: .history).isEmpty)

        #expect(context.beginAlertCompletion(id: id))
        context.alertWillDismiss(id: id)
        #expect(context.layer?.alertSession?.state == .handlingCompletion)
        #expect(!context.beginAlertCompletion(id: id))
        if case let .confirmation(confirmationID) = id { context.cancelNavigation(id: confirmationID) }
        context.alertDidDismiss(id: id)
        #expect(context.layer?.alertSession == nil)
        #expect(!router.hasActiveAlert)
        context.alertDidDismiss(id: id)
        #expect(!context.beginAlertCompletion(id: id))
        #expect(router.path(for: .history).isEmpty)
    }

    @Test(arguments: [State.presented, .dismissing, .handlingCompletion])
    func wrongIDCannotChangeCurrentSession(state: State) throws {
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second]
        )
        let context = router.rootPresentation
        let id = try beginAlert(context)
        context.submitAlert(.second)
        router.submit(.push(.second, on: .history))
        advance(context, id: id, to: state)
        let wrongID = NavigationAlertID()

        #expect(!context.alertWillPresent(id: .business(wrongID)))
        context.alertWillDismiss(id: .business(wrongID))
        #expect(!context.beginAlertCompletion(id: .business(wrongID)))
        context.alertDidDismiss(id: .business(wrongID))

        #expect(context.layer?.alertSession?.id == .business(id))
        #expect(context.layer?.alertSession?.state == state)
        #expect(context.presentedAlert?.id == (state == .presented ? id : nil))
        #expect(router.hasActiveAlert)
        #expect(context.layer?.queuedPresentations.count == 1)
        #expect(router.requestWaitingForAlert == .push(.second, on: .history))
        #expect(router.selectedScope == .home)
        #expect(router.path(for: .history).isEmpty)
    }

    @Test(arguments: [State.presented, .dismissing, .handlingCompletion])
    func matchingRawValueFromConfirmationCannotChangeBusinessSession(state: State) {
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second]
        )
        let context = router.rootPresentation
        let rawValue = UUID()
        let alertID = NavigationAlertID(rawValue: rawValue)
        let wrongSource = NavigationSystemAlertID.confirmation(NavigationConfirmationID(rawValue: rawValue))
        router.rootLayer.presentedContent = .alert(NavigationAlertNode(id: alertID, destination: .first))
        #expect(!context.alertWillPresent(id: wrongSource))
        #expect(context.alertWillPresent(id: .business(alertID)))
        #expect(context.submitAlert(.second) == .queued)
        #expect(router.submit(.push(.second, on: .history)) == .deferredUntilAlertDismisses)
        advance(context, id: alertID, to: state)

        #expect(!context.alertWillPresent(id: wrongSource))
        context.alertWillDismiss(id: wrongSource)
        #expect(!context.beginAlertCompletion(id: wrongSource))
        context.alertDidDismiss(id: wrongSource)

        #expect(context.layer?.alertSession?.id == .business(alertID))
        #expect(context.layer?.alertSession?.state == state)
        #expect(context.presentedAlert?.id == (state == .presented ? alertID : nil))
        #expect(router.hasBusinessAlert)
        #expect(context.layer?.queuedPresentations.count == 1)
        #expect(router.requestWaitingForAlert == .push(.second, on: .history))
        #expect(router.path(for: .history).isEmpty)
    }

    @Test(arguments: [State.presented, .dismissing, .handlingCompletion])
    func expiredCallbacksCannotAffectNextAlert(state: State) throws {
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second]
        )
        let context = router.rootPresentation
        let first = try beginAlert(context)
        context.submitAlert(.second)
        router.submit(.push(.second, on: .history))
        advance(context, id: first, to: .handlingCompletion)
        context.alertDidDismiss(id: .business(first))
        let second = try #require(context.presentedAlert).id
        #expect(context.alertWillPresent(id: .business(second)))
        advance(context, id: second, to: state)

        #expect(!context.alertWillPresent(id: .business(first)))
        context.alertWillDismiss(id: .business(first))
        #expect(!context.beginAlertCompletion(id: .business(first)))
        context.alertDidDismiss(id: .business(first))

        #expect(context.layer?.alertSession?.id == .business(second))
        #expect(context.layer?.alertSession?.state == state)
        #expect(context.presentedAlert?.id == (state == .presented ? second : nil))
        #expect(router.hasActiveAlert)
        #expect(router.path(for: .history).isEmpty)
        #expect(router.requestWaitingForAlert == .push(.second, on: .history))
    }

    @Test func inactiveContextCannotChangeNewLayerWithSameID() throws {
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second]
        )
        router.presentSheet(.first)
        let oldPage = try #require(router.sheet)
        oldPage.lifetime.claimHost()
        let oldContext = router.presentationContext(for: oldPage)
        oldContext.dismiss()
        router.rootPresentation.presentationDidDismiss()
        router.rootLayer.presentation = NavigationPresentationNode(id: oldPage.id, destination: .first)
        let newPage = try #require(router.sheet)
        newPage.lifetime.claimHost()
        let context = router.presentationContext(for: newPage)
        #expect(newPage.id == oldPage.id)
        #expect(!oldContext.isActive)
        let id = try beginAlert(context)

        // 即使传入新提示的真实 ID，旧 Context 也不能连接同 ID 的新层。
        #expect(!oldContext.alertWillPresent(id: .business(id)))
        oldContext.alertWillDismiss(id: .business(id))
        #expect(!oldContext.beginAlertCompletion(id: .business(id)))
        oldContext.alertDidDismiss(id: .business(id))
        #expect(context.layer?.alertSession?.state == .presented)
        #expect(context.presentedAlert?.id == id)

        advance(context, id: id, to: .handlingCompletion)
        oldContext.alertDidDismiss(id: .business(id))
        #expect(context.layer?.alertSession?.state == .handlingCompletion)
        context.alertDidDismiss(id: .business(id))
        #expect(!router.hasActiveAlert)
    }

    private func beginAlert(_ context: Presentation) throws -> NavigationAlertID {
        #expect(context.submitAlert(.first) == .applied)
        let id = try #require(context.presentedAlert).id
        #expect(context.alertWillPresent(id: .business(id)))
        return id
    }

    private func advance(_ context: Presentation, id: NavigationAlertID, to state: State) {
        guard state != .presented else { return }
        context.alertWillDismiss(id: .business(id))
        if state == .handlingCompletion {
            #expect(context.beginAlertCompletion(id: .business(id)))
        }
    }
}
