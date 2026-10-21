import Foundation
@testable import NavigationCore
import Testing

@MainActor
@Suite("普通根层的导航请求与栈根替换")
struct NavigationPrimaryLayerTests {
    private enum Tab: String, Codable, NavigationScope { case home, history }
    private enum Route: String, Codable, NavigationDestination {
        case home, detail, tabs
        var providesNavigationContainer: Bool {
            self == .tabs
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, NoNavigationAlert>
    private typealias Snapshot = NavigationSnapshot<Tab, Route, NoNavigationAlert>

    @Test(arguments: [false, true], [false, true])
    func presentationRequestsPreserveContainerStacks(fullScreen: Bool, namedStack: Bool) throws {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        let initialStack: NavigationStackID<Tab> = namedStack ? .scope(.history) : .primary
        let roots: [NavigationStackID<Tab>: Route] = [initialStack: .detail, .scope(.home): .home]
        let paths: [NavigationStackID<Tab>: [Route]] = [initialStack: [.home], .scope(.home): [.detail]]
        let before = router.snapshot
        let invalid: NavigationPresentationRequest<Tab, Route, NoNavigationAlert> = fullScreen
            ? .fullScreen(.tabs, initialStack: initialStack) : .sheet(.tabs, initialStack: initialStack)
        #expect(!router.rootPresentation.present(invalid))
        #expect(router.snapshot == before)
        let request: NavigationPresentationRequest<Tab, Route, NoNavigationAlert> = fullScreen
            ? .fullScreen(.tabs, initialStack: initialStack, rootDestinations: roots, paths: paths)
            : .sheet(.tabs, initialStack: initialStack, rootDestinations: roots, paths: paths)

        #expect(router.rootPresentation.present(request))
        let node = try #require(router.presentedNode)
        #expect(node.style == (fullScreen ? .fullScreen : .sheet))
        #expect(node.destination == .tabs)
        #expect(node.layer.selectedStack == initialStack)
        #expect(node.layer.roots == roots)
        #expect(node.layer.paths == paths)
        #expect(router.rootPresentation.context(for: .primary).path == [.detail])
    }

    @Test(arguments: [false, true], [false, true])
    func routerConveniencesPreserveContainerStacksInTheFrontmostLayer(fullScreen: Bool, namedStack: Bool) throws {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        #expect(router.rootPresentation.present(.detail))
        let parent = try #require(router.sheet)
        let initialStack: NavigationStackID<Tab> = namedStack ? .scope(.history) : .primary
        let roots: [NavigationStackID<Tab>: Route] = [initialStack: .detail, .scope(.home): .home]
        let paths: [NavigationStackID<Tab>: [Route]] = [initialStack: [.home], .scope(.home): [.detail]]
        let before = router.snapshot
        let invalid = fullScreen
            ? router.presentFullScreen(.tabs, initialStack: initialStack)
            : router.presentSheet(.tabs, initialStack: initialStack)
        #expect(!invalid)
        #expect(router.snapshot == before)
        let accepted = fullScreen
            ? router.presentFullScreen(.tabs, initialStack: initialStack, rootDestinations: roots, paths: paths)
            : router.presentSheet(.tabs, initialStack: initialStack, rootDestinations: roots, paths: paths)

        #expect(accepted)
        let node = try #require(parent.presentation)
        #expect(router.sheet === parent)
        #expect(node.style == (fullScreen ? .fullScreen : .sheet))
        #expect(node.destination == .tabs)
        #expect(node.layer.selectedStack == initialStack)
        #expect(node.layer.roots == roots)
        #expect(node.layer.paths == paths)
        #expect(router.rootPresentation.context(for: .primary).path == [.detail])
    }

    @Test func primarySelectionHasNoScopeForCoreAndExternalContainers() throws {
        for destination in [Route.home, .tabs] {
            let router = Router(
                rootDestination: destination,
                rootDestinations: destination.providesNavigationContainer ? [.primary: .home] : [:],
                paths: [.primary: [.detail]]
            )
            let before = router.snapshot
            #expect(router.selectedScope == nil)
            #expect(before.selectedScope == nil)
            #expect(router.rootPresentation.selectedStack == .primary)
            #expect(router.selectedDestination == .detail)
            router.selectedScope = nil
            #expect(router.snapshot == before)
            let decoded = try JSONDecoder().decode(Snapshot.self, from: JSONEncoder().encode(before))
            #expect(decoded.selectedScope == nil)
            #expect(decoded.layer.selectedStack == .primary)
            #expect(decoded == before)
        }
        let router = Router(rootDestination: .home)
        let before = router.snapshot
        router.selectedScope = .history
        #expect(router.selectedScope == nil)
        #expect(router.snapshot == before)
    }

    @Test func namedScopeSelectionPreservesPathsAndIgnoresNilWrites() {
        let router = Router(
            rootDestination: .tabs, initialStack: .scope(.home),
            rootDestinations: [.primary: .home, .scope(.home): .home, .scope(.history): .detail],
            paths: [.scope(.home): [.detail], .scope(.history): [.home]]
        )
        #expect(router.selectedScope == .home)
        let original = router.snapshot
        router.selectedScope = .history
        #expect(router.selectedScope == .history)
        #expect(router.snapshot.selectedScope == .history)
        #expect(original.selectedScope == .home)
        let selected = router.snapshot
        router.selectedScope = nil
        #expect(router.snapshot == selected)
        router.rootPresentation.selectedStack = .primary
        #expect(router.selectedScope == nil)
        #expect(router.snapshot.selectedScope == nil)
        router.selectedScope = .home
        #expect(router.selectedScope == .home)
        #expect(router.snapshot == original)
    }

    @Test func scopeProjectionFollowsRestorationBetweenPrimaryAndNamedRoots() {
        let router = Router(
            rootDestination: .tabs,
            selectedScope: .history,
            rootDestinations: [.home: .home, .history: .detail],
            paths: [.history: [.detail]]
        )
        let named = router.snapshot
        let primary = Router(rootDestination: .home, paths: [.primary: [.detail]]).snapshot
        #expect(router.restore(primary))
        #expect(router.selectedScope == nil)
        #expect(router.snapshot.selectedScope == nil)
        #expect(router.rootPresentation.selectedStack == .primary)
        #expect(router.selectedDestination == .detail)
        #expect(router.restore(named))
        #expect(router.selectedScope == .history)
        #expect(router.snapshot.selectedScope == .history)
        #expect(router.snapshot == named)
    }

    @Test func primaryRequestsUseTheRootStackAndRejectUnrelatedNamedStacks() {
        let router = Router(rootDestination: .home)
        let stack = router.rootPresentation.context(for: .primary)
        #expect(router.submit(.selectStack(.primary)) == .applied)
        #expect(router.submit(.replacePath([.detail], on: .primary)) == .applied)
        #expect(stack.path == [.detail])
        router.push(.tabs)
        #expect(stack.path == [.detail, .tabs])
        #expect(router.selectedDestination == .tabs)
        #expect(router.submit(.setRoot(.detail, on: .primary)) == .applied)
        #expect(stack.rootDestination == .detail)
        #expect(stack.path.isEmpty)
        #expect(router.selectedDestination == .detail)
        #expect(router.rootPresentation.destination == .home)
        let before = router.snapshot
        #expect(router.submit(.selectStack(.scope(.history))) == .rejected)
        #expect(router.submit(.push(.detail, on: .scope(.history))) == .rejected)
        #expect(router.submit(.replacePath([.tabs], on: .scope(.home))) == .rejected)
        #expect(router.snapshot == before)
    }

    @Test func primaryDeepLinkCancellationAndApprovalWaitForTheRootDismissal() throws {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        let root = router.rootPresentation.context(for: .primary)
        #expect(router.rootPresentation.present(.detail, paths: [.primary: [.home]]))
        let parent = try #require(router.sheet)
        let modal = router.presentationContext(for: parent)
        #expect(modal.present(.home, style: .fullScreen))
        let child = try router.presentationContext(for: #require(parent.fullScreen))
        let before = router.snapshot
        #expect(router.submit(.push(.tabs, on: .primary), confirmIfPresented: true) == .awaitingConfirmation)
        let cancelled = try #require(child.confirmation)
        #expect(!root.setPath([.tabs]))
        #expect(!modal.context(for: .primary).setPath([.tabs]))
        #expect(!root.setRootDestination(.tabs))
        #expect(!modal.context(for: .primary).setRootDestination(.tabs))
        child.cancelNavigation(id: cancelled.id)
        #expect(router.snapshot == before)
        #expect(router.pendingConfirmation == nil)

        #expect(router.submit(.push(.tabs, on: .primary), confirmIfPresented: true) == .awaitingConfirmation)
        let approved = try #require(child.confirmation)
        child.confirmNavigation(id: approved.id)
        #expect(router.presentedNode == nil)
        #expect(router.isAwaitingPresentationDismissal)
        #expect(root.path == [.detail])
        #expect(!root.setPath([.tabs]))
        #expect(!root.setRootDestination(.tabs))
        child.presentationDidDismiss()
        #expect(root.path == [.detail])
        #expect(router.isAwaitingPresentationDismissal)
        router.rootPresentation.presentationDidDismiss()
        #expect(!router.isAwaitingPresentationDismissal)
        #expect(root.path == [.detail, .tabs])
        #expect(root.rootDestination == .home)
        #expect(router.rootPresentation.selectedStack == .primary)
        router.rootPresentation.presentationDidDismiss()
        #expect(root.path == [.detail, .tabs])
        #expect(root.setPath([.home, .tabs]))
        #expect(root.path == [.home, .tabs])
    }

    @Test func replacingRootThroughEachContextClearsOnlyItsPathAndSurvivesRestoration() throws {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        let root = router.rootPresentation.context(for: .primary)
        #expect(router.rootPresentation.present(.detail, paths: [.primary: [.home]]))
        let node = try #require(router.sheet)
        let modal = router.presentationContext(for: node)
        let modalStack = modal.context(for: .primary)
        #expect(root.setRootDestination(.detail))
        #expect(root.rootDestination == .detail)
        #expect(root.path.isEmpty)
        #expect(modalStack.path == [.home])
        #expect(modalStack.setRootDestination(.tabs))
        #expect(modalStack.rootDestination == .tabs)
        #expect(modalStack.path.isEmpty)
        #expect(router.rootPresentation.destination == .home)
        #expect(modal.destination == .detail)
        #expect(root.push(.home))
        #expect(modalStack.path.isEmpty)
        let snapshot = try JSONDecoder().decode(Snapshot.self, from: JSONEncoder().encode(router.snapshot))
        #expect(modal.dismiss())
        #expect(!modalStack.setRootDestination(.home))
        router.rootPresentation.presentationDidDismiss()
        #expect(root.setRootDestination(.home))
        #expect(router.restore(snapshot))
        #expect(root === router.rootPresentation.context(for: .primary))
        #expect(root.rootDestination == .detail)
        #expect(root.path == [.home])
        let restored = try #require(router.sheet)
        #expect(restored.id == node.id)
        #expect(router.context(for: restored).rootDestination == .tabs)
        #expect(!modalStack.setRootDestination(.home))
        #expect(router.snapshot == snapshot)
    }
}
