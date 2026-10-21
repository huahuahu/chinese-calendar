import Foundation
@testable import NavigationCore
import Testing

@MainActor
@Suite("Context 缓存身份与释放")
struct NavigationContextStoreTests {
    private enum Tab: NavigationScope { case home, history }
    private enum Route: NavigationDestination {
        case tabs, first, second
        var providesNavigationContainer: Bool {
            self == .tabs
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, NoNavigationAlert>
    private typealias Node = NavigationPresentationNode<Tab, Route, NoNavigationAlert>
    private typealias Presentation = NavigationPresentationContext<Tab, Route, NoNavigationAlert>

    @Test func validContextsSurvivePathAndTabChangesAndRemainRouterLocal() throws {
        let router = makeRouter()
        let root = router.rootPresentation
        let home = router.context(for: .home)
        let history = router.context(for: .history)
        let source = root.scoped(to: .scope(.home))
        #expect(source.scoped(to: .scope(.home)) === source)
        #expect(source.unscoped() === root)
        #expect(home !== history)
        #expect(home.push(.second))
        #expect(home.pop())
        #expect(home.setPath([.second]))
        router.paths = [:]
        router.selectedScope = .history
        #expect(!source.present(.first))
        router.presentationDidDismiss(isRoot: false)
        #expect(home.isActive && history.isActive)
        #expect(home === router.context(for: .home))
        #expect(root === router.rootPresentation)
        #expect(source === root.scoped(to: .scope(.home)))
        #expect(home.path.isEmpty)
        let other = makeRouter()
        #expect(other.context(for: .home) !== home)
        #expect(other.rootPresentation !== root)
        #expect(other.rootPresentation.scoped(to: .scope(.home)) !== source)
        #expect(root.present(.first))
        let node = try #require(router.presentedNode)
        #expect(router.context(for: node) !== home)
        #expect(router.presentationContext(for: node) !== root)
    }

    @Test func dismissalInvalidatesImmediatelyAndCompletionReleasesAllThreeCaches() throws {
        let router = makeRouter()
        #expect(router.rootPresentation.present(.first))
        let node = try #require(router.presentedNode)
        let probe = Probe(router: router, node: node)
        #expect(probe.navigation != nil && probe.presentation != nil && probe.scoped != nil)
        #expect(probe.presentation?.dismiss() == true)
        #expect(probe.navigation?.isActive == false)
        #expect(probe.presentation?.isActive == false)
        #expect(probe.scoped?.isActive == false)
        #expect(probe.navigation?.push(.second) == false)
        #expect(probe.scoped?.present(.second) == false)
        // 节点仍被测试持有，缓存持有关系只在真实关闭完成后解除。
        #expect(probe.navigation != nil && probe.presentation != nil && probe.scoped != nil)
        router.rootPresentation.presentationDidDismiss()
        #expect(probe.navigation == nil && probe.presentation == nil && probe.scoped == nil)
        #expect(node.destination == .first)
    }

    @Test func parentDismissalReleasesNestedCachesEvenWhenOldLayerContextIsRetained() throws {
        let router = makeRouter()
        router.rootPresentation.present(.first)
        let parent = try #require(router.presentedNode)
        let parentProbe = Probe(router: router, node: parent)
        let retainedParentContext = router.presentationContext(for: parent)
        retainedParentContext.present(.second)
        let child = try #require(parent.presentation)
        let childProbe = Probe(router: router, node: child)
        #expect(retainedParentContext.dismiss())
        #expect(parentProbe.navigation?.isActive == false)
        #expect(childProbe.navigation?.isActive == false)
        #expect(childProbe.scoped?.isActive == false)
        router.rootPresentation.presentationDidDismiss()
        #expect(parentProbe.navigation == nil && parentProbe.scoped == nil)
        #expect(childProbe.navigation == nil && childProbe.presentation == nil && childProbe.scoped == nil)
        #expect(parentProbe.presentation === retainedParentContext)
        #expect(!retainedParentContext.isActive)
    }

    @Test func childCompletionKeepsParentAndRootCacheIdentity() throws {
        let router = makeRouter()
        let root = router.rootPresentation
        let home = router.context(for: .home)
        root.present(.first)
        let parent = try #require(router.presentedNode)
        let parentProbe = Probe(router: router, node: parent)
        let parentContext = router.presentationContext(for: parent)
        parentContext.present(.second)
        let child = try #require(parent.presentation)
        let childProbe = Probe(router: router, node: child)
        #expect(childProbe.presentation?.dismiss() == true)
        parentContext.presentationDidDismiss()
        #expect(childProbe.navigation == nil && childProbe.presentation == nil && childProbe.scoped == nil)
        #expect(parentProbe.navigation === router.context(for: parent))
        #expect(parentProbe.presentation === parentContext)
        #expect(parentProbe.scoped === parentContext.scoped(to: .primary))
        #expect(root === router.rootPresentation)
        #expect(home === router.context(for: .home))
    }

    @Test func staleEntriesCannotReplaceCachesForNewObjectsWithTheSameID() throws {
        let router = makeRouter()
        router.rootPresentation.present(.first)
        let oldNode = try #require(router.presentedNode)
        let oldStack = router.context(for: oldNode)
        let oldLayer = router.presentationContext(for: oldNode)
        let oldScoped = oldLayer.scoped(to: .primary)
        #expect(oldLayer.dismiss())
        router.rootPresentation.presentationDidDismiss()
        let newNode = Node(id: oldNode.id, destination: .second)
        router.rootLayer.presentation = newNode
        let newStack = router.context(for: newNode)
        let newLayer = router.presentationContext(for: newNode)
        let newScoped = newLayer.scoped(to: .primary)
        #expect(newStack !== oldStack && newLayer !== oldLayer && newScoped !== oldScoped)
        #expect(!router.context(for: oldNode).isActive)
        #expect(!router.presentationContext(for: oldNode).isActive)
        #expect(!oldScoped.scoped(to: .primary).isActive)
        #expect(!oldScoped.unscoped().isActive)
        #expect(!oldLayer.context(for: .primary).push(.first))
        #expect(!oldStack.push(.first) && !oldScoped.dismiss())
        router.presentationDidDismiss(isRoot: false)
        #expect(newStack === router.context(for: newNode))
        #expect(newLayer === router.presentationContext(for: newNode))
        #expect(newScoped === newLayer.scoped(to: .primary))
        #expect(newStack.push(.first))
        #expect(oldNode.path.isEmpty)
    }

    @Test func externalContextsDoNotRetainRouterStoreLayersOrStacks() throws {
        var router: Router? = makeRouter()
        weak var weakRouter = router
        weak var weakStore = router?.contextStore
        weak var rootLayer = router?.rootLayer
        weak var rootStack = router?.rootLayer.stacks[.scope(.home)]
        let rootNavigation = try #require(router?.context(for: .home))
        let rootPresentation = try #require(router?.rootPresentation)
        let rootScoped = rootPresentation.scoped(to: .scope(.home))
        rootScoped.present(.first)
        weak var modalNode = router?.presentedNode
        weak var modalLayer = modalNode?.layer
        weak var modalState = modalLayer?.stacks[.primary]
        let modalNavigation = try #require(modalNode.flatMap { router?.context(for: $0) })
        let modalPresentation = try #require(modalNode.flatMap { router?.presentationContext(for: $0) })
        let modalScoped = modalPresentation.scoped(to: .primary)
        router = nil
        #expect(weakRouter == nil && weakStore == nil)
        #expect(rootLayer == nil && rootStack == nil)
        #expect(modalNode == nil && modalLayer == nil && modalState == nil)
        #expect(!rootNavigation.isActive && !modalNavigation.isActive)
        #expect(!rootPresentation.isActive && !rootScoped.isActive)
        #expect(!modalPresentation.isActive && !modalScoped.isActive)
        #expect(!modalScoped.present(.second))
        #expect(modalPresentation.destination == .first)
    }

    @Test func routerDeallocationReleasesUnretainedCaches() {
        var router: Router? = makeRouter()
        weak var navigation = router?.context(for: .home)
        weak var presentation = router?.rootPresentation
        weak var scoped = router?.rootPresentation.scoped(to: .scope(.home))
        #expect(navigation != nil && presentation != nil && scoped != nil)
        router = nil
        #expect(navigation == nil && presentation == nil && scoped == nil)
    }

    private func makeRouter() -> Router {
        Router(rootDestination: .tabs, selectedScope: .home, rootDestinations: [.home: .first, .history: .second])
    }

    @MainActor
    private final class Probe {
        weak var navigation: NavigationContext<Tab, Route>?
        weak var presentation: Presentation?
        weak var scoped: Presentation?

        init(router: Router, node: Node) {
            navigation = router.context(for: node)
            presentation = router.presentationContext(for: node)
            scoped = router.presentationContext(for: node).scoped(to: .primary)
        }
    }
}
