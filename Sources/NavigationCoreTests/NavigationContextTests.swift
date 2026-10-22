import Foundation
@testable import NavigationCore
import Testing

@MainActor
@Suite("局部 Router 与导航事务")
struct NavigationContextTests {
    private enum Tab: String, NavigationScope { case home, history }
    private enum Route: String, NavigationDestination {
        case root, tabs, first, second, third
        var providesNavigationContainer: Bool {
            self == .root || self == .tabs
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, NoNavigationAlert>

    @Test func localOperationsKeepTabAndModalPathsIndependent() throws {
        let router = makeRouter(selectedScope: .history, paths: [.home: [.third]])
        let history = router.context(for: .history)
        let presentation = router.rootPresentation.scoped(to: .scope(.history))
        #expect(history === router.context(for: .history))
        #expect(history.push(.first) == .applied)
        #expect(presentation.present(.second) == .applied)
        let node = try #require(router.sheet)
        let modal = router.context(for: node)
        #expect(modal.push(.third) == .applied)
        #expect(node.path == [.third])
        #expect(history.path == [.first])
        #expect(router.path(for: .home) == [.third])
        #expect(modal.pop() == .applied)
        #expect(modal.pop() == .noChange(.alreadyAtRoot))
        #expect(presentation.dismiss() == .noChange(.notPresented))
        #expect(router.selectedScope == .history)
    }

    @Test func childDismissalPreservesParentAndBlocksReopenUntilCompletion() throws {
        let router = makeRouter()
        #expect(router.rootPresentation.present(.first) == .applied)
        let parent = try #require(router.sheet)
        let context = router.context(for: parent)
        let presentation = router.presentationContext(for: parent).scoped(to: .primary)
        context.push(.second)
        #expect(presentation.present(.third, style: .fullScreen) == .applied)
        #expect(presentation.present(.first) == .rejected(.presentationAlreadyExists))
        let childNode = try #require(parent.fullScreen)
        let child = router.context(for: childNode)
        let childPresentation = router.presentationContext(for: childNode).scoped(to: .primary)
        #expect(childPresentation.present(.second) == .applied)
        #expect(childPresentation.dismiss() == .applied)
        #expect(!child.isActive)
        #expect(child.push(.first) == .rejected(.inactiveContext))
        #expect(childPresentation.present(.first) == .rejected(.inactiveContext))
        #expect(childPresentation.dismiss() == .rejected(.inactiveContext))
        #expect(parent.path == [.second])
        #expect(router.sheet === parent)
        #expect(parent.fullScreen == nil)
        #expect(presentation.present(.third) == .rejected(.awaitingDismissal))
        router.presentSheet(.third)
        #expect(parent.sheet == nil)
        presentation.presentationDidDismiss()
        #expect(presentation.present(.third) == .applied)
    }

    @Test func inactiveTabCannotPresentOverCurrentTab() {
        let router = makeRouter()
        let history = router.rootPresentation.scoped(to: .scope(.history))
        #expect(history.present(.first) == .rejected(.sourceStackNotSelected))
        #expect(router.sheet == nil)
        router.selectedScope = .history
        #expect(history.present(.first) == .applied)
        #expect(router.rootPresentation.scoped(to: .scope(.home))
            .present(.second) == .rejected(.presentationAlreadyExists))
    }

    @Test func separateContextsDoNotKeepTheRouterAlive() throws {
        var router: Router? = makeRouter()
        weak var weakRouter = router
        let navigation = try #require(router?.context(for: .home))
        let presentation = try #require(router?.rootPresentation.scoped(to: .scope(.home)))
        #expect(navigation.push(.first) == .applied)
        router = nil
        #expect(weakRouter == nil)
        #expect(!navigation.isActive)
        #expect(navigation.path.isEmpty)
        #expect(navigation.push(.second) == .rejected(.inactiveContext))
        #expect(!presentation.isActive)
        #expect(presentation.present(.second) == .rejected(.inactiveContext))
    }

    @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
    func rootDismissalWithoutRequestAllowsReopening(style: NavigationPresentationStyle) throws {
        let router = makeRouter()
        let home = router.rootPresentation.scoped(to: .scope(.home))
        home.present(.first, style: style)
        let modal = try router.presentationContext(for: #require(router.frontmostPresentationNode))
        #expect(modal.dismiss() == .applied)
        #expect(router.isAwaitingPresentationDismissal)
        #expect(home.present(.second, style: style) == .rejected(.awaitingDismissal))
        router.rootPresentation.presentationDidDismiss()
        #expect(!router.isAwaitingPresentationDismissal)
        #expect(home.present(.second, style: style) == .applied)
    }

    @Test func confirmationIsVisibleOnlyOnTopModalAndCancelKeepsTheTree() throws {
        let router = makeRouter(paths: [.home: [.first]])
        router.presentSheet(.second)
        let parent = try #require(router.sheet)
        let context = router.presentationContext(for: parent)
        context.present(.third)
        let childNode = try #require(parent.sheet)
        let child = router.context(for: childNode)
        let childPresentation = router.presentationContext(for: childNode)
        #expect(router.submit(.push(.third, on: .history), confirmIfPresented: true) == .awaitingConfirmation)
        let confirmation = try #require(childPresentation.confirmation)
        #expect(router.rootPresentation.confirmation == nil)
        #expect(context.confirmation == nil)
        #expect(router.rootPresentation.scoped(to: .scope(.home)).confirmation == nil)
        #expect(router.sheet === parent)
        #expect(parent.sheet === childNode)
        #expect(router.selectedScope == .home)
        #expect(router.paths == [.home: [.first]])
        #expect(parent.path.isEmpty)
        #expect(child.path.isEmpty)
        #expect(child.push(.first) == .rejected(.awaitingConfirmation))
        childPresentation.cancelNavigation(id: confirmation.id)
        #expect(router.pendingConfirmation == nil)
        #expect(router.sheet === parent)
        #expect(parent.sheet === childNode)
        #expect(router.selectedScope == .home)
        #expect(router.paths == [.home: [.first]])
        #expect(parent.path.isEmpty)
        #expect(child.path.isEmpty)
        #expect(child.push(.first) == .applied)
    }

    @Test func approvalWaitsForRootDismissalAndRejectsChildCompletion() throws {
        let router = makeRouter(paths: [.home: [.first]])
        router.presentSheet(.second)
        let parentContext = try router.presentationContext(for: #require(router.sheet))
        parentContext.present(.third)
        router.submit(.push(.second, on: .history), confirmIfPresented: true)
        let confirmation = try #require(router.pendingConfirmation)
        router.confirmNavigation(id: confirmation.id)
        #expect(router.sheet == nil)
        #expect(router.selectedScope == .home)
        parentContext.presentationDidDismiss()
        #expect(router.isAwaitingPresentationDismissal)
        #expect(router.path(for: .history).isEmpty)
        router.rootPresentation.presentationDidDismiss()
        #expect(router.path(for: .history) == [.second])
        #expect(router.path(for: .home) == [.first])
        #expect(router.selectedScope == .history)
        router.rootPresentation.presentationDidDismiss()
        #expect(router.path(for: .history) == [.second])
    }

    @Test func repeatedAndReplacedRequestsCannotReuseOldApproval() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        router.submit(.push(.second, on: .home), confirmIfPresented: true)
        let original = try #require(router.pendingConfirmation)
        router.submit(original.request, confirmIfPresented: true)
        #expect(router.pendingConfirmation?.id == original.id)
        router.submit(.push(.third, on: .history), confirmIfPresented: true)
        let replacement = try #require(router.pendingConfirmation)
        #expect(replacement.id != original.id)
        router.confirmNavigation(id: original.id)
        router.cancelConfirmation(id: original.id)
        #expect(router.pendingConfirmation?.id == replacement.id)
        #expect(router.sheet != nil)
        router.confirmNavigation(id: replacement.id)
        router.rootPresentation.presentationDidDismiss()
        #expect(router.path(for: .home).isEmpty)
        #expect(router.path(for: .history) == [.third])
    }

    @Test func requestDuringApprovedDismissalRequiresItsOwnApproval() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        router.submit(.push(.second, on: .home), confirmIfPresented: true)
        try router.confirmNavigation(id: #require(router.pendingConfirmation).id)
        #expect(router.submit(.push(.third, on: .history), confirmIfPresented: true) == .awaitingConfirmation)
        #expect(router.rootPresentation.confirmation == nil)
        router.rootPresentation.presentationDidDismiss()
        #expect(router.path(for: .home) == [.second])
        #expect(router.path(for: .history).isEmpty)
        let next = try #require(router.rootPresentation.confirmation)
        router.confirmNavigation(id: next.id)
        #expect(router.path(for: .history) == [.third])
    }

    @Test func disappearingModalDoesNotImplicitlyApprovePendingRequest() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let modal = try router.presentationContext(for: #require(router.sheet))
        router.submit(.push(.second, on: .history), confirmIfPresented: true)
        let original = try #require(modal.confirmation)
        modal.dismiss()
        #expect(router.rootPresentation.confirmation == nil)
        router.rootPresentation.presentationDidDismiss()
        #expect(router.rootPresentation.confirmation?.id == original.id)
        modal.confirmNavigation(id: original.id)
        modal.cancelNavigation(id: original.id)
        #expect(router.rootPresentation.confirmation?.id == original.id)
        #expect(router.path(for: .history).isEmpty)
        router.cancelConfirmation(id: original.id)
        #expect(router.pendingConfirmation == nil)
    }

    @Test func coldRequestDoesNotRequireConfirmation() {
        let router = makeRouter()
        #expect(router.submit(.push(.first, on: .history), confirmIfPresented: true) == .applied)
        #expect(router.pendingConfirmation == nil)
        #expect(router.path(for: .history) == [.first])
    }

    @Test func newNodeWithReusedIDKeepsFormerContextsInactive() throws {
        let router = makeRouter()
        router.presentSheet(.first)
        let original = try #require(router.sheet)
        let oldContext = router.context(for: original)
        let oldPresentation = router.presentationContext(for: original).scoped(to: .primary)
        oldPresentation.dismiss()
        router.rootPresentation.presentationDidDismiss()
        let replacement = NavigationPresentationNode<Tab, Route, NoNavigationAlert>(
            id: original.id, destination: .first
        )
        router.rootLayer.presentation = replacement
        #expect(replacement.id == original.id)
        #expect(!oldContext.isActive)
        #expect(oldContext.push(.second) == .rejected(.inactiveContext))
        #expect(oldPresentation.dismiss() == .rejected(.inactiveContext))
        #expect(router.context(for: replacement) !== oldContext)
        #expect(router.context(for: replacement).push(.second) == .applied)
    }
}

extension NavigationContextTests {
    @Test func tabsSharePresentationStateButHaveIndependentStacks() throws {
        let router = makeRouter()
        let home = router.context(for: .home)
        let history = router.context(for: .history)
        let homePresentation = router.rootPresentation.scoped(to: .scope(.home))
        let historyPresentation = router.rootPresentation.scoped(to: .scope(.history))
        #expect(home !== history)
        #expect(homePresentation === router.rootPresentation.scoped(to: .scope(.home)))
        #expect(homePresentation !== historyPresentation)
        home.push(.first)
        history.push(.second)
        #expect(home.path == [.first])
        #expect(history.path == [.second])
        #expect(homePresentation.present(.third) == .applied)
        #expect(homePresentation.presentedNode === historyPresentation.presentedNode)
        #expect(homePresentation.dismiss() == .noChange(.notPresented))
        #expect(router.rootPresentation.dismiss() == .noChange(.notPresented))
        #expect(try #require(router.presentedNode).style == .sheet)
    }

    @Test func modalTabsShareTheirLayerWithoutSharingRootPaths() throws {
        let router = makeRouter(paths: [.home: [.third]])
        router.rootPresentation.present(
            .tabs,
            initialStack: .scope(.home),
            rootDestinations: [.scope(.home): .first, .scope(.history): .first]
        )
        let node = try #require(router.presentedNode)
        let layer = router.presentationContext(for: node)
        let home = layer.context(for: .scope(.home))
        let history = layer.context(for: .scope(.history))
        let homePresentation = layer.scoped(to: .scope(.home))
        let historyPresentation = layer.scoped(to: .scope(.history))
        #expect(homePresentation.id == historyPresentation.id)
        #expect(homePresentation.id != router.rootPresentation.id)
        home.push(.first)
        history.push(.second)
        #expect(historyPresentation.present(.third) == .rejected(.sourceStackNotSelected))
        layer.selectedStack = .scope(.history)
        #expect(historyPresentation.present(.third, style: .fullScreen) == .applied)
        let child = try #require(layer.presentedNode)
        #expect(router.presentationContext(for: child).dismiss() == .applied)
        #expect(home.path == [.first])
        #expect(history.path == [.second])
        #expect(router.path(for: .home) == [.third])
        #expect(homePresentation.present(.third) == .rejected(.awaitingDismissal))
        layer.presentationDidDismiss()
        #expect(historyPresentation.present(.third) == .applied)
    }

    @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
    func eachLayerAcceptsOnlyOneChildUntilDismissalCompletes(style: NavigationPresentationStyle) throws {
        let router = makeRouter()
        let root = router.rootPresentation
        #expect(root.present(.first, style: style) == .applied)
        let original = try #require(root.presentedNode)
        #expect(root
            .present(.second, style: style == .sheet ? .fullScreen : .sheet) == .rejected(.presentationAlreadyExists))
        #expect(root.presentedNode === original)
        #expect(root.dismissPresented(id: original.id) == .applied)
        #expect(root.present(.second) == .rejected(.awaitingDismissal))
        root.presentationDidDismiss()
        #expect(root.present(.second) == .applied)
        let replacement = try #require(root.presentedNode)
        #expect(root.dismissPresented(id: original.id) == .noChange(.presentationNotFound))
        #expect(root.presentedNode === replacement)
    }

    @Test func staleLayerCannotReacquireStacksFromNewNodeWithTheSameID() throws {
        let router = makeRouter()
        router.rootPresentation.present(
            .tabs,
            initialStack: .scope(.home),
            rootDestinations: [.scope(.home): .first, .scope(.history): .first]
        )
        let node = try #require(router.presentedNode)
        let oldLayer = router.presentationContext(for: node)
        let oldStack = oldLayer.context(for: .scope(.home))
        let oldPresentation = oldLayer.scoped(to: .scope(.home))
        oldStack.push(.second)
        #expect(oldLayer.dismiss() == .applied)
        router.rootPresentation.presentationDidDismiss()
        router.rootLayer.presentation = NavigationPresentationNode(
            id: node.id, destination: .tabs, initialStack: .scope(.home),
            rootDestinations: [.scope(.home): .first, .scope(.history): .first],
            paths: [.scope(.home): [.second]]
        )
        let newLayer = try router.presentationContext(for: #require(router.presentedNode))
        #expect(!oldLayer.isActive)
        #expect(oldLayer.context(for: .scope(.history)).push(.third) == .rejected(.inactiveContext))
        #expect(oldLayer.present(.third) == .rejected(.inactiveContext))
        #expect(oldStack.pop() == .rejected(.inactiveContext))
        #expect(oldPresentation.present(.third) == .rejected(.inactiveContext))
        #expect(oldPresentation.scoped(to: .scope(.history)).present(.third) == .rejected(.inactiveContext))
        #expect(newLayer.scoped(to: .scope(.home)).present(.third) == .applied)
        #expect(newLayer.context(for: .scope(.home)).path == [.second])
    }

    @Test func modalTabConfirmationUsesTheLayerAndCancellationPreservesEveryStack() throws {
        let router = makeRouter()
        router.rootPresentation.present(
            .tabs,
            initialStack: .scope(.home),
            rootDestinations: [.scope(.home): .first, .scope(.history): .first]
        )
        let parent = try #require(router.presentedNode)
        let layer = router.presentationContext(for: parent)
        layer.context(for: .scope(.home)).push(.second)
        layer.context(for: .scope(.history)).push(.third)
        router.submit(.push(.second, on: .history), confirmIfPresented: true)
        let confirmation = try #require(layer.confirmation)
        #expect(router.rootPresentation.confirmation == nil)
        #expect(layer.scoped(to: .scope(.home)).confirmation?.id == confirmation.id)
        #expect(layer.scoped(to: .scope(.history)).confirmation?.id == confirmation.id)
        layer.cancelNavigation(id: confirmation.id)
        #expect(router.presentedNode === parent)
        #expect(router.selectedScope == .home)
        #expect(router.paths.isEmpty)
        #expect(layer.selectedStack == .scope(.home))
        #expect(layer.context(for: .scope(.home)).path == [.second])
        #expect(layer.context(for: .scope(.history)).path == [.third])
        #expect(layer.presentedNode == nil)
    }
}

private extension NavigationContextTests {
    private func makeRouter(selectedScope: Tab = .home, paths: [Tab: [Route]] = [:]) -> Router {
        Router(
            rootDestination: .root, selectedScope: selectedScope,
            rootDestinations: [.home: .first, .history: .second], paths: paths
        )
    }
}
