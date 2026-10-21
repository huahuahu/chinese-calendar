import Foundation
@testable import NavigationCore
import Observation
import Synchronization
import Testing

@MainActor
@Suite("呈现 Context 的路由读取与有效性")
struct NavigationPresentationRouteTests {
    private enum Scope: NavigationScope { case home }
    private enum Route: NavigationDestination { case home, detail }
    private typealias Router = NavigationRouter<Scope, Route, NoNavigationAlert>
    private typealias Snapshot = NavigationSnapshot<Scope, Route, NoNavigationAlert>
    private typealias Node = NavigationPresentationNode<Scope, Route, NoNavigationAlert>

    @Test func rootRoutesFollowRestorationAndRemainReadableAfterRelease() throws {
        var router: Router? = Router(rootDestination: .home)
        weak var originalRouter = router
        weak var originalLayer = router?.rootLayer
        let root = try #require(router?.rootPresentation)
        let scoped = root.scoped(to: .primary)
        #expect(router?.restore(Snapshot(
            rootDestination: .detail, layer: .init(rootDestinations: [.primary: .detail])
        )) == true)
        #expect(root.isActive)
        #expect(scoped.isActive)
        #expect(root.route == .root(destination: .detail))
        #expect(scoped.destination == .detail)

        // 恢复后不先读取 Context，释放时也必须保留最新入口，不能退回初始化值或读取缓存。
        #expect(router?.restore(Snapshot(
            rootDestination: .home, layer: .init(rootDestinations: [.primary: .home])
        )) == true)
        router = nil
        #expect(originalRouter == nil)
        #expect(originalLayer == nil)
        #expect(!root.isActive)
        #expect(!scoped.isActive)
        #expect(root.route == .root(destination: .home))
        #expect(scoped.destination == .home)
        #expect(!root.present(.detail))
        #expect(!scoped.present(.detail))
        #expect(!root.context(for: .primary).isActive)
    }

    @Test func dismissedRouteOutlivesItsLayerWithoutFollowingRestoredIdentity() throws {
        let router = Router(rootDestination: .home)
        #expect(router.rootPresentation.present(.home))
        var node: Node? = try #require(router.presentedNode)
        weak var originalLayer = node?.layer
        let id = try #require(node?.id)
        let modal = try router.presentationContext(for: #require(node))
        let scoped = modal.scoped(to: .primary)
        #expect(modal.dismiss())
        node = nil
        #expect(originalLayer == nil)
        #expect(!modal.isActive)
        #expect(modal.route == .presentation(id: id, destination: .home))
        #expect(scoped.destination == .home)
        router.rootPresentation.presentationDidDismiss()

        let snapshot = Snapshot(rootDestination: .home, layer: .init(
            rootDestinations: [.primary: .home],
            presentation: .node(id: id, destination: .detail, style: .sheet, layer: .init(
                rootDestinations: [.primary: .detail]
            ))
        ))
        #expect(router.restore(snapshot))
        let current = try router.presentationContext(for: #require(router.presentedNode))
        #expect(current.id == modal.id)
        #expect(current.isActive)
        #expect(current.destination == .detail)
        #expect(modal.destination == .home)
        #expect(scoped.destination == .home)
        #expect(!modal.present(.detail))
        #expect(!modal.dismiss())
        #expect(!scoped.present(.detail))
        #expect(!modal.context(for: .primary).push(.detail))
        #expect(current.isActive)
    }

    @Test func rootRestorationNotifiesRootAndScopedRouteObservers() {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        let scoped = root.scoped(to: .primary)
        let changes = Mutex(0)
        withObservationTracking {
            _ = root.destination
        } onChange: {
            changes.withLock { $0 += 1 }
        }
        withObservationTracking {
            _ = scoped.route
        } onChange: {
            changes.withLock { $0 += 1 }
        }
        #expect(router.restore(Snapshot(
            rootDestination: .detail, layer: .init(rootDestinations: [.primary: .detail])
        )))
        #expect(changes.withLock { $0 } == 2)
        #expect(root.destination == .detail)
        #expect(scoped.route == root.route)
    }
}
