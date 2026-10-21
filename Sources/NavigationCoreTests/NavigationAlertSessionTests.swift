import Foundation
@testable import NavigationCore
import Testing

// swiftformat:disable:next modifierOrder
nonisolated private enum SessionTestNotice: String, Codable, NavigationAlertRoute {
    case first, second
    typealias Action = Bool
}

@MainActor
@Suite("提示会话的生命周期约束")
struct NavigationAlertSessionTests {
    private enum Tab: String, Codable, NavigationScope { case home, history }
    private enum Route: String, Codable, NavigationDestination {
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
        let id: UUID
        if isConfirmation {
            router.submit(.push(.second, on: .history), confirmIfPresented: true)
            id = try #require(context.confirmation).id
        } else {
            context.presentAlert(.first)
            id = try #require(context.presentedAlert).id
        }
        #expect(context.alertWillPresent(id: id, isConfirmation: isConfirmation))
        #expect(context.layer?.alertSession?.state == .presented)
        #expect(context.layer?.alertSession?.isConfirmation == isConfirmation)
        #expect(!context.alertWillPresent(id: id, isConfirmation: isConfirmation))
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
        if isConfirmation { context.cancelNavigation(id: id) }
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
        context.presentAlert(.second)
        router.submit(.push(.second, on: .history))
        advance(context, id: id, to: state)
        let wrongID = UUID()

        #expect(!context.alertWillPresent(id: wrongID, isConfirmation: false))
        context.alertWillDismiss(id: wrongID)
        #expect(!context.beginAlertCompletion(id: wrongID))
        context.alertDidDismiss(id: wrongID)

        #expect(context.layer?.alertSession?.id == id)
        #expect(context.layer?.alertSession?.state == state)
        #expect(context.presentedAlert?.id == (state == .presented ? id : nil))
        #expect(router.hasActiveAlert)
        #expect(context.layer?.queuedPresentations.count == 1)
        #expect(router.requestWaitingForAlert == .push(.second, on: .history))
        #expect(router.selectedScope == .home)
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
        context.presentAlert(.second)
        router.submit(.push(.second, on: .history))
        advance(context, id: first, to: .handlingCompletion)
        context.alertDidDismiss(id: first)
        let second = try #require(context.presentedAlert).id
        #expect(context.alertWillPresent(id: second, isConfirmation: false))
        advance(context, id: second, to: state)

        #expect(!context.alertWillPresent(id: first, isConfirmation: false))
        context.alertWillDismiss(id: first)
        #expect(!context.beginAlertCompletion(id: first))
        context.alertDidDismiss(id: first)

        #expect(context.layer?.alertSession?.id == second)
        #expect(context.layer?.alertSession?.state == state)
        #expect(context.presentedAlert?.id == (state == .presented ? second : nil))
        #expect(router.hasActiveAlert)
        #expect(router.path(for: .history).isEmpty)
        #expect(router.requestWaitingForAlert == .push(.second, on: .history))
    }

    @Test func inactiveContextCannotChangeRestoredLayerWithSameID() throws {
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second]
        )
        router.presentSheet(.first)
        let oldPage = try #require(router.sheet)
        let oldContext = router.presentationContext(for: oldPage)
        let snapshot = router.snapshot
        oldContext.dismiss()
        router.rootPresentation.presentationDidDismiss()
        #expect(router.restore(snapshot))
        let newPage = try #require(router.sheet)
        let context = router.presentationContext(for: newPage)
        #expect(newPage.id == oldPage.id)
        #expect(!oldContext.isActive)
        let id = try beginAlert(context)

        // 即使传入新提示的真实 ID，旧 Context 也不能连接同 ID 的新层。
        #expect(!oldContext.alertWillPresent(id: id, isConfirmation: false))
        oldContext.alertWillDismiss(id: id)
        #expect(!oldContext.beginAlertCompletion(id: id))
        oldContext.alertDidDismiss(id: id)
        #expect(context.layer?.alertSession?.state == .presented)
        #expect(context.presentedAlert?.id == id)

        advance(context, id: id, to: .handlingCompletion)
        oldContext.alertDidDismiss(id: id)
        #expect(context.layer?.alertSession?.state == .handlingCompletion)
        context.alertDidDismiss(id: id)
        #expect(!router.hasActiveAlert)
    }

    private func beginAlert(_ context: Presentation) throws -> UUID {
        #expect(context.presentAlert(.first))
        let id = try #require(context.presentedAlert).id
        #expect(context.alertWillPresent(id: id, isConfirmation: false))
        return id
    }

    private func advance(_ context: Presentation, id: UUID, to state: State) {
        guard state != .presented else { return }
        context.alertWillDismiss(id: id)
        if state == .handlingCompletion {
            #expect(context.beginAlertCompletion(id: id))
        }
    }
}
