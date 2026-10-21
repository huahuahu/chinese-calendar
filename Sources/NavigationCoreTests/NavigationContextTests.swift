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
        #expect(history.push(.first))
        #expect(presentation.present(.second))
        let node = try #require(router.sheet)
        let modal = router.context(for: node)
        #expect(modal.push(.third))
        #expect(node.path == [.third])
        #expect(history.path == [.first])
        #expect(router.path(for: .home) == [.third])
        #expect(modal.pop())
        #expect(!modal.pop())
        #expect(!presentation.dismiss())
        #expect(router.selectedScope == .history)
    }

    @Test func childDismissalPreservesParentAndBlocksReopenUntilCompletion() throws {
        let router = makeRouter()
        #expect(router.rootPresentation.present(.first))
        let parent = try #require(router.sheet)
        let context = router.context(for: parent)
        let presentation = router.presentationContext(for: parent).scoped(to: .primary)
        context.push(.second)
        #expect(presentation.present(.third, style: .fullScreen))
        #expect(!presentation.present(.first))
        let childNode = try #require(parent.fullScreen)
        let child = router.context(for: childNode)
        let childPresentation = router.presentationContext(for: childNode).scoped(to: .primary)
        #expect(childPresentation.present(.second))
        #expect(childPresentation.dismiss())
        #expect(!child.isActive)
        #expect(!child.push(.first))
        #expect(!childPresentation.present(.first))
        #expect(!childPresentation.dismiss())
        #expect(parent.path == [.second])
        #expect(router.sheet === parent)
        #expect(parent.fullScreen == nil)
        #expect(!presentation.present(.third))
        router.presentSheet(.third)
        #expect(parent.sheet == nil)
        presentation.presentationDidDismiss()
        #expect(presentation.present(.third))
    }

    @Test func inactiveTabCannotPresentOverCurrentTab() {
        let router = makeRouter()
        let history = router.rootPresentation.scoped(to: .scope(.history))
        #expect(!history.present(.first))
        #expect(router.sheet == nil)
        router.selectedScope = .history
        #expect(history.present(.first))
        #expect(!router.rootPresentation.scoped(to: .scope(.home)).present(.second))
    }

    @Test func separateContextsDoNotKeepTheRouterAlive() throws {
        var router: Router? = makeRouter()
        weak var weakRouter = router
        let navigation = try #require(router?.context(for: .home))
        let presentation = try #require(router?.rootPresentation.scoped(to: .scope(.home)))
        #expect(navigation.push(.first))
        router = nil
        #expect(weakRouter == nil)
        #expect(!navigation.isActive)
        #expect(navigation.path.isEmpty)
        #expect(!navigation.push(.second))
        #expect(!presentation.isActive)
        #expect(!presentation.present(.second))
    }

    @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
    func rootDismissalWithoutRequestAllowsReopening(style: NavigationPresentationStyle) throws {
        let router = makeRouter()
        let home = router.rootPresentation.scoped(to: .scope(.home))
        home.present(.first, style: style)
        let modal = try router.presentationContext(for: #require(router.frontmostPresentationNode))
        #expect(modal.dismiss())
        #expect(router.isAwaitingPresentationDismissal)
        #expect(!home.present(.second, style: style))
        router.rootPresentation.presentationDidDismiss()
        #expect(!router.isAwaitingPresentationDismissal)
        #expect(home.present(.second, style: style))
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
        #expect(!child.push(.first))
        childPresentation.cancelNavigation(id: confirmation.id)
        #expect(router.pendingConfirmation == nil)
        #expect(router.sheet === parent)
        #expect(parent.sheet === childNode)
        #expect(router.selectedScope == .home)
        #expect(router.paths == [.home: [.first]])
        #expect(parent.path.isEmpty)
        #expect(child.path.isEmpty)
        #expect(child.push(.first))
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
        #expect(!oldContext.push(.second))
        #expect(!oldPresentation.dismiss())
        #expect(router.context(for: replacement) !== oldContext)
        #expect(router.context(for: replacement).push(.second))
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
        #expect(homePresentation.present(.third))
        #expect(homePresentation.presentedNode === historyPresentation.presentedNode)
        #expect(!homePresentation.dismiss())
        #expect(!router.rootPresentation.dismiss())
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
        #expect(!historyPresentation.present(.third))
        layer.selectedStack = .scope(.history)
        #expect(historyPresentation.present(.third, style: .fullScreen))
        let child = try #require(layer.presentedNode)
        #expect(router.presentationContext(for: child).dismiss())
        #expect(home.path == [.first])
        #expect(history.path == [.second])
        #expect(router.path(for: .home) == [.third])
        #expect(!homePresentation.present(.third))
        layer.presentationDidDismiss()
        #expect(historyPresentation.present(.third))
    }

    @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
    func eachLayerAcceptsOnlyOneChildUntilDismissalCompletes(style: NavigationPresentationStyle) throws {
        let router = makeRouter()
        let root = router.rootPresentation
        #expect(root.present(.first, style: style))
        let original = try #require(root.presentedNode)
        #expect(!root.present(.second, style: style == .sheet ? .fullScreen : .sheet))
        #expect(root.presentedNode === original)
        #expect(root.dismissPresented(id: original.id))
        #expect(!root.present(.second))
        root.presentationDidDismiss()
        #expect(root.present(.second))
        let replacement = try #require(root.presentedNode)
        #expect(!root.dismissPresented(id: original.id))
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
        #expect(oldLayer.dismiss())
        router.rootPresentation.presentationDidDismiss()
        router.rootLayer.presentation = NavigationPresentationNode(
            id: node.id, destination: .tabs, initialStack: .scope(.home),
            rootDestinations: [.scope(.home): .first, .scope(.history): .first],
            paths: [.scope(.home): [.second]]
        )
        let newLayer = try router.presentationContext(for: #require(router.presentedNode))
        #expect(!oldLayer.isActive)
        #expect(!oldLayer.context(for: .scope(.history)).push(.third))
        #expect(!oldLayer.present(.third))
        #expect(!oldStack.pop())
        #expect(!oldPresentation.present(.third))
        #expect(!oldPresentation.scoped(to: .scope(.history)).present(.third))
        #expect(newLayer.scoped(to: .scope(.home)).present(.third))
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
