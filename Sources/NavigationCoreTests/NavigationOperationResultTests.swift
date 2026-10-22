import Foundation
@testable import NavigationCore
import Testing

// swiftformat:disable:next modifierOrder
nonisolated private enum OperationTestAlert: NavigationAlertRoute {
    case notice
}

@MainActor
@Suite("导航操作结果与状态边界")
struct NavigationOperationResultTests {
    private enum Tab: NavigationScope { case home, history }
    private enum Route: NavigationDestination {
        case home, detail, tabs
        var providesNavigationContainer: Bool {
            self == .tabs
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, OperationTestAlert>

    @Test func popSeparatesEmptyStackFromTransactionRejectionAndInvalidation() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        let stack = root.context(for: .primary)
        #expect(stack.pop() == .noChange(.alreadyAtRoot))
        #expect(stack.push(.detail) == .applied)
        #expect(root.presentAlert(.notice) == .applied)
        #expect(stack.pop() == .rejected(.alertInProgress))
        #expect(stack.setRootDestination(.detail) == .rejected(.alertInProgress))
        #expect(stack.path == [.detail])
        #expect(stack.rootDestination == .home)

        let other = Router(rootDestination: .home)
        other.presentSheet(.detail)
        let modal = try other.context(for: #require(other.presentedNode))
        #expect(other.dismissSheet() == .applied)
        #expect(modal.pop() == .rejected(.inactiveContext))
    }

    @Test func repeatedPathAcceptanceStillHonorsConfirmationAndDismissal() throws {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        let stack = router.rootPresentation.context(for: .primary)
        #expect(stack.setPath(stack.path) == .applied)
        router.presentSheet(.detail)
        #expect(router.submit(.replacePath([], on: .primary), confirmIfPresented: true) == .awaitingConfirmation)
        #expect(stack.setPath(stack.path) == .rejected(.awaitingConfirmation))
        #expect(stack.push(.home) == .rejected(.awaitingConfirmation))
        #expect(stack.setRootDestination(.detail) == .rejected(.awaitingConfirmation))
        stack.path = []
        #expect(stack.path == [.detail])
        let confirmation = try #require(router.pendingConfirmation)
        #expect(router.confirmNavigation(id: confirmation.id) == .deferredUntilPresentationDismisses)
        #expect(stack.setPath(stack.path) == .rejected(.awaitingDismissal))
        #expect(stack.path == [.detail])
        router.rootPresentation.presentationDidDismiss()
        #expect(stack.path.isEmpty)
        #expect(stack.setPath(stack.path) == .applied)
    }

    @Test func rootCommandsReportStructuralErrorsWithoutPartialUpdates() {
        let router = Router(
            rootDestination: .tabs, selectedScope: .home,
            rootDestinations: [.home: .home], paths: [.home: [.detail]]
        )
        #expect(router.setPath([], for: .history) == .rejected(.undeclaredStack))
        #expect(router.push(.detail, on: .history) == .rejected(.undeclaredStack))
        #expect(router.selectScope(.history) == .rejected(.undeclaredStack))
        #expect(router.setPaths([.home: [], .history: []]) == .rejected(.undeclaredStack))
        #expect(router.submit(.push(.detail, on: .history)) == .rejected(.undeclaredStack))
        #expect(router.path(for: .home) == [.detail])
        #expect(router.selectedScope == .home)
        #expect(router.selectScope(nil) == .noChange(.noSelection))

        let primary = Router(rootDestination: .home)
        #expect(primary.setRootDestination(.detail, for: .home) == .rejected(.incompatibleContainer))
        #expect(primary.setPaths([:]) == .rejected(.incompatibleContainer))
        #expect(primary.submit(.selectScope(.home)) == .rejected(.incompatibleContainer))
        #expect(primary.push(.detail) == .applied)
        #expect(primary.rootPresentation.context(for: .primary).path == [.detail])
    }

    @Test func unavailableContextKeepsItsOriginalCauseAfterDeclaringANewStack() {
        let router = Router(rootDestination: .tabs, selectedScope: .home, rootDestinations: [.home: .home])
        let missing = router.context(for: .history)
        #expect(missing.push(.detail) == .rejected(.undeclaredStack))
        #expect(router.setRootDestination(.home, for: .history) == .applied)
        #expect(missing.push(.detail) == .rejected(.undeclaredStack))
        #expect(router.context(for: .history).push(.detail) == .applied)
        #expect(router.path(for: .history) == [.detail])

        let primary = Router(rootDestination: .home)
        #expect(primary.context(for: .home).setPath([]) == .rejected(.incompatibleContainer))
    }

    @Test func staleConfirmationResultsDoNotResolveTheReplacementRequest() throws {
        let router = Router(rootDestination: .home)
        router.presentSheet(.detail)
        #expect(router.submit(.push(.detail, on: .primary), confirmIfPresented: true) == .awaitingConfirmation)
        let first = try #require(router.pendingConfirmation)
        #expect(router.submit(.push(.home, on: .primary), confirmIfPresented: true) == .awaitingConfirmation)
        let replacement = try #require(router.pendingConfirmation)
        #expect(first.id != replacement.id)
        #expect(router.rootPresentation.confirmNavigation(id: first.id) == .noChange(.staleConfirmation))
        #expect(router.rootPresentation.cancelNavigation(id: first.id) == .noChange(.staleConfirmation))
        #expect(router.pendingConfirmation?.id == replacement.id)
        #expect(router.presentedNode != nil)
        #expect(router.cancelConfirmation(id: replacement.id) == .applied)
        #expect(router.pendingConfirmation == nil)
        #expect(router.cancelConfirmation(id: replacement.id) == .noChange(.staleConfirmation))
    }

    @Test func rootDismissalReportsNoChangeAndAlertDeferral() {
        let router = Router(rootDestination: .home)
        #expect(router.dismissSheet() == .noChange(.notPresented))
        #expect(router.dismissFullScreen() == .noChange(.notPresented))
        #expect(router.dismissAllPresentations() == .noChange(.notPresented))
        #expect(router.dismissPresentation(id: NavigationPresentationID()) == .noChange(.presentationNotFound))
        #expect(router.presentAlert(.notice) == .applied)
        #expect(router.dismissAllPresentations() == .queued)
        #expect(router.rootPresentation.presentedAlert?.destination == .notice)
    }
}
