import Foundation
@testable import NavigationCore
import Testing

@MainActor
@Suite("Destination 容器与同构导航层")
struct NavigationDestinationTests {
    private enum Tab: String, NavigationScope { case home, history }
    enum Route: String, NavigationDestination {
        case tabs, split, home, detail

        var providesNavigationContainer: Bool {
            self == .tabs || self == .split
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, NoNavigationAlert>
    private typealias StackID = NavigationStackID<Tab>

    private let tabRoots: [StackID: Route] = [.scope(.home): .home, .scope(.history): .detail]

    private func makeRouter() -> Router {
        Router(rootDestination: .tabs, initialStack: .scope(.home), rootDestinations: tabRoots)
    }

    @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
    func coreOwnedRootAndModalUseTheSamePrimaryStackRules(style: NavigationPresentationStyle) throws {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        let root = router.rootPresentation
        let rootStack = root.context(for: .primary)
        #expect(root.selectedStack == .primary)
        #expect(rootStack.rootDestination == .home)
        #expect(rootStack.path == [.detail])
        #expect(root.present(.home, style: style, paths: [.primary: [.detail]]))
        let node = try #require(router.presentedNode)
        let modal = router.presentationContext(for: node)
        let modalStack = modal.context(for: .primary)
        #expect(node.layer.selectedStack == router.rootLayer.selectedStack)
        #expect(node.layer.roots == router.rootLayer.roots)
        #expect(node.layer.paths == router.rootLayer.paths)
        #expect(modal.selectedStack == .primary)
        #expect(!root.context(for: .scope(.history)).isActive)
        #expect(!modal.context(for: .scope(.history)).isActive)
        #expect(!root.context(for: .scope(.history)).push(.detail))
        #expect(!modal.context(for: .scope(.history)).push(.detail))
        #expect(!root.context(for: .scope(.history)).setPath([.detail]))
        #expect(!modal.context(for: .scope(.history)).setPath([.detail]))
        #expect(modalStack.rootDestination == rootStack.rootDestination)
        #expect(modalStack.path == rootStack.path)
        root.selectedStack = .scope(.history)
        modal.selectedStack = .scope(.history)
        #expect(root.selectedStack == .primary)
        #expect(modal.selectedStack == .primary)
        #expect(modalStack.push(.tabs))
        #expect(rootStack.path == [.detail])
        #expect(modalStack.path == [.detail, .tabs])
        #expect(modalStack.pop())
        #expect(modalStack.path == rootStack.path)
        #expect(root.destination == .home)
        #expect(modal.destination == .home)
        #expect(!root.dismiss())
        #expect(modal.dismiss())
        #expect(!modalStack.isActive)
        #expect(rootStack.isActive)
        #expect(rootStack.path == [.detail])
    }

    @Test func identicalContainerPagesOwnIndependentSelectionsPathsAndChildPresentation() throws {
        let router = Router(
            rootDestination: .tabs, initialStack: .scope(.history), rootDestinations: tabRoots,
            paths: [.scope(.home): [.detail], .scope(.history): [.home]]
        )
        let root = router.rootPresentation
        let home = root.context(for: .scope(.home))
        let history = root.context(for: .scope(.history))
        #expect(root.present(
            .tabs, initialStack: .scope(.home), rootDestinations: tabRoots,
            paths: [.scope(.history): [.detail]]
        ))
        let node = try #require(root.presentedNode)
        let modal = router.presentationContext(for: node)
        let modalHome = modal.context(for: .scope(.home))
        let modalHistory = modal.context(for: .scope(.history))
        #expect(modalHome !== home)
        #expect(modalHome.push(.detail))
        #expect(!modal.scoped(to: .scope(.history)).present(.home))
        modal.selectedStack = .scope(.history)
        #expect(modalHistory.push(.tabs))
        #expect(modal.scoped(to: .scope(.history)).present(
            .tabs, style: .fullScreen, initialStack: .scope(.home), rootDestinations: tabRoots
        ))
        let childNode = try #require(modal.presentedNode)
        let child = router.presentationContext(for: childNode)
        #expect(child.context(for: .scope(.home)).push(.home))
        #expect(child.selectedStack == .scope(.home))
        #expect(modal.selectedStack == .scope(.history))
        #expect(root.selectedStack == .scope(.history))
        #expect(home.path == [.detail])
        #expect(history.path == [.home])
        #expect(modalHome.path == [.detail])
        #expect(modalHistory.path == [.detail, .tabs])
        #expect(root.route == .root(destination: .tabs))
        #expect(modal.route == .presentation(id: node.id, destination: .tabs))
        #expect(child.route == .presentation(id: childNode.id, destination: .tabs))
        #expect(child.dismiss())
        #expect(!child.isActive)
        #expect(modal.isActive)
        #expect(modalHistory.path == [.detail, .tabs])
        #expect(home.path == [.detail])
        #expect(history.path == [.home])
    }

    @Test(arguments: [Route.home, .tabs, .split])
    func everyDestinationCanEnterRootStackRootPushAndModal(route: Route) {
        let roots: [NavigationStackID<Tab>: Route] = route.providesNavigationContainer ? [.primary: .home] : [:]
        let directRoot = Router(rootDestination: route, rootDestinations: roots)
        #expect(directRoot.rootPresentation.destination == route)
        #expect(directRoot.rootPresentation.context(for: .primary).isActive)

        let router = Router(
            rootDestination: .tabs, initialStack: .scope(.home), rootDestinations: [.scope(.home): route]
        )
        let stack = router.rootPresentation.context(for: .scope(.home))
        #expect(stack.rootDestination == route)
        #expect(stack.push(route))
        #expect(stack.path == [route])
        #expect(router.rootPresentation.present(route, rootDestinations: roots))
        #expect(router.presentedNode?.destination == route)
    }

    @Test func pathAndRootMutationsDoNotReintroduceContainerEntryRestrictions() {
        let router = makeRouter()
        let stack = router.context(for: .home)
        #expect(stack.setPath([.split, .tabs]))
        #expect(stack.path == [.split, .tabs])
        stack.path = [.tabs, .split]
        #expect(stack.path == [.tabs, .split])
        router.push(.tabs, on: .history)
        #expect(router.path(for: .history) == [.tabs])
        router.setPath([.split], for: .history)
        #expect(router.path(for: .history) == [.split])
        router.paths = [.home: [.split], .history: [.tabs]]
        #expect(stack.path == [.split])
        #expect(router.path(for: .history) == [.tabs])
        router.setRootDestination(.tabs, for: .home)
        #expect(stack.rootDestination == .tabs)
        #expect(stack.path.isEmpty)
        #expect(router.submit(.push(.split, on: .home)) == .applied)
        #expect(stack.path == [.split])
        #expect(router.submit(.replacePath([.tabs, .split], on: .home)) == .applied)
        #expect(stack.path == [.tabs, .split])
        #expect(router.submit(.setRoot(.split, on: .home)) == .applied)
        #expect(stack.rootDestination == .split)
        #expect(stack.path.isEmpty)
        #expect(router.rootPresentation.destination == .tabs)
    }

    @Test func repeatedDestinationAndReusedUUIDNeverReviveOldContexts() throws {
        let router = makeRouter()
        #expect(router.rootPresentation.present(.tabs, initialStack: .scope(.home), rootDestinations: tabRoots))
        let first = try #require(router.presentedNode)
        let old = router.presentationContext(for: first)
        let stack = old.context(for: .scope(.home))
        let oldScoped = old.scoped(to: .scope(.home))
        #expect(stack.push(.detail))
        #expect(old.dismiss())
        #expect(old.route == .presentation(id: first.id, destination: .tabs))
        #expect(stack.rootDestination == nil)
        #expect(!stack.setPath([.home]))
        #expect(first.layer.paths[.scope(.home)] == [.detail])
        router.rootPresentation.presentationDidDismiss()
        #expect(router.rootPresentation.present(.tabs, initialStack: .scope(.home), rootDestinations: tabRoots))
        let second = try #require(router.presentedNode)
        #expect(second.id != first.id)
        #expect(router.presentationContext(for: second).dismiss())
        router.rootPresentation.presentationDidDismiss()
        let replacement = NavigationPresentationNode<Tab, Route, NoNavigationAlert>(
            id: first.id, destination: .tabs, initialStack: .scope(.home),
            rootDestinations: tabRoots, paths: [.scope(.home): [.detail]]
        )
        router.rootLayer.presentation = replacement
        let current = router.presentationContext(for: replacement)
        #expect(replacement.id == first.id)
        #expect(!old.isActive)
        #expect(old.destination == .tabs)
        #expect(!oldScoped.present(.detail))
        #expect(!stack.setPath([.home]))
        #expect(!stack.push(.detail))
        #expect(!old.context(for: .scope(.history)).push(.detail))
        #expect(!old.scoped(to: .scope(.history)).present(.detail))
        #expect(current.context(for: .scope(.home)).path == [.detail])
        #expect(current.context(for: .scope(.home)).push(.home))
        #expect(current.present(.detail))
    }
}
