import Foundation
@testable import NavigationCore
import Testing

@MainActor
@Suite("根层与递归模态的初始化约束")
struct NavigationLayerInitializationTests {
    private enum Tab: NavigationScope { case home, history }
    private enum Route: NavigationDestination {
        case home, detail, tabs

        var providesNavigationContainer: Bool {
            self == .tabs
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, NoNavigationAlert>
    private typealias Layer = NavigationLayer<Tab, Route, NoNavigationAlert>
    private typealias StackID = NavigationStackID<Tab>

    @Test(arguments: [false, true])
    func coreLayersRejectNamedStacksAndExplicitRoots(isModal: Bool) {
        let route: NavigationLayerRoute<Route> = isModal
            ? .presentation(id: NavigationPresentationID(), destination: .home) : .root(destination: .home)
        #expect(Layer(route: route, initialStack: .scope(.home)) == nil)
        #expect(Layer(route: route, rootDestinations: [.primary: .home]) == nil)
        #expect(Layer(route: route, rootDestinations: [.scope(.home): .home]) == nil)
        #expect(Layer(route: route, paths: [.scope(.history): [.detail]]) == nil)
        #expect(Layer(route: route, paths: [.scope(.history): []]) == nil)
    }

    @Test(arguments: [false, true])
    func containerLayersRequireRootsForSelectionAndEveryPath(isModal: Bool) {
        let route: NavigationLayerRoute<Route> = isModal
            ? .presentation(id: NavigationPresentationID(), destination: .tabs) : .root(destination: .tabs)
        #expect(Layer(route: route) == nil)
        #expect(Layer(
            route: route, initialStack: .scope(.history), rootDestinations: [.scope(.home): .home]
        ) == nil)
        for path in [[], [Route.detail]] {
            #expect(Layer(
                route: route, initialStack: .scope(.home), rootDestinations: [.scope(.home): .home],
                paths: [.scope(.history): path]
            ) == nil)
        }
    }

    @Test(arguments: [false, true])
    func containerLayersPreservePrimaryAndNamedStacks(isModal: Bool) throws {
        let route: NavigationLayerRoute<Route> = isModal
            ? .presentation(id: NavigationPresentationID(), destination: .tabs) : .root(destination: .tabs)
        let roots: [StackID: Route] = [.primary: .home, .scope(.home): .detail, .scope(.history): .home]
        let layer = try #require(Layer(
            route: route, initialStack: .scope(.history), rootDestinations: roots,
            paths: [.primary: [.detail], .scope(.home): [], .scope(.history): [.detail, .home]]
        ))
        #expect(layer.route == route)
        #expect(layer.selectedStack == .scope(.history))
        #expect(layer.roots == roots)
        #expect(layer.paths == [.primary: [.detail], .scope(.history): [.detail, .home]])
        #expect(layer.stacks.count == 3)
        #expect(layer.presentedContent == nil)
    }

    @Test func malformedPresentationsLeaveEveryExistingLayerUntouched() throws {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        #expect(router.rootPresentation.present(.detail, paths: [.primary: [.home]]) == .applied)
        let parent = try #require(router.sheet)
        parent.lifetime.claimHost()
        let modal = router.presentationContext(for: parent)
        #expect(modal.present(.home, initialStack: .scope(.home)) == .rejected(.incompatibleContainer))
        #expect(modal.present(.home, rootDestinations: [.primary: .home]) == .rejected(.incompatibleContainer))
        #expect(modal.present(.home, paths: [.scope(.history): [.detail]]) == .rejected(.incompatibleContainer))
        #expect(modal.present(.tabs) == .rejected(.missingRootDestination))
        #expect(modal.present(
            .tabs, initialStack: .scope(.home), rootDestinations: [.scope(.home): .home],
            paths: [.scope(.history): []]
        ) == .rejected(.missingRootDestination))
        #expect(router.sheet === parent)
        #expect(parent.presentation == nil)
        #expect(parent.layer.roots == [.primary: .detail])
        #expect(parent.path == [.home])
        #expect(router.rootLayer.roots == [.primary: .home])
        #expect(router.rootLayer.paths == [.primary: [.detail]])
        #expect(router.pendingConfirmation == nil)
        #expect(!router.isAwaitingPresentationDismissal)
        #expect(!parent.layer.isAwaitingDismissal)
        #expect(parent.layer.queuedPresentations.isEmpty)
    }

    @Test func replacingStackRootsKeepsNestedLayerEntriesAndOtherPaths() throws {
        let router = Router(rootDestination: .home)
        let rootStack = router.rootPresentation.context(for: .primary)
        #expect(rootStack.setRootDestination(.detail) == .applied)
        #expect(rootStack.push(.tabs) == .applied)
        #expect(router.rootPresentation.present(.detail) == .applied)
        let parent = try #require(router.sheet)
        parent.lifetime.claimHost()
        let modal = router.presentationContext(for: parent)
        #expect(modal.context(for: .primary).setRootDestination(.tabs) == .applied)
        #expect(modal.context(for: .primary).push(.home) == .applied)
        #expect(modal.present(
            .tabs, style: .fullScreen, initialStack: .scope(.history),
            rootDestinations: [.scope(.home): .home, .scope(.history): .detail],
            paths: [.scope(.home): [.detail], .scope(.history): [.home, .tabs]]
        ) == .applied)
        let child = try #require(parent.fullScreen)
        child.lifetime.claimHost()
        let tabs = router.presentationContext(for: child)
        #expect(router.rootPresentation.destination == .home)
        #expect(modal.destination == .detail)
        #expect(tabs.destination == .tabs)
        #expect(tabs.selectedStack == .scope(.history))
        #expect(tabs.context(for: .scope(.home)).path == [.detail])
        #expect(tabs.context(for: .scope(.history)).path == [.home, .tabs])
        #expect(tabs.context(for: .scope(.history)).push(.detail) == .applied)
        #expect(modal.context(for: .primary).rootDestination == .tabs)
        #expect(modal.context(for: .primary).path == [.home])
        #expect(rootStack.rootDestination == .detail)
        #expect(rootStack.path == [.tabs])
    }
}
