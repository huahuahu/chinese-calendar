import Foundation
@testable import NavigationCore
import Testing

@MainActor
@Suite("NavigationPresentationContext 的路由读取与有效性")
struct NavigationPresentationRouteTests {
    private enum Scope: NavigationScope { case home }
    private enum Route: NavigationDestination { case home, detail }
    private typealias Router = NavigationRouter<Scope, Route, NoNavigationAlert>
    private typealias Node = NavigationPresentationNode<Scope, Route, NoNavigationAlert>

    @Test func expiredContextsDoNotRetainRootRoute() throws {
        var router: Router? = Router(rootDestination: .home)
        weak var originalRouter = router
        weak var originalLayer = router?.rootLayer
        let root = try #require(router?.rootPresentation)
        let scoped = root.scoped(to: .primary)
        #expect(root.isActive)
        #expect(scoped.isActive)
        #expect(root.route == .root(destination: .home))
        #expect(scoped.destination == .home)

        router = nil
        #expect(originalRouter == nil)
        #expect(originalLayer == nil)
        #expect(!root.isActive)
        #expect(!scoped.isActive)
        #expect(root.route == nil)
        #expect(scoped.destination == nil)
        #expect(root.submitPresentation(.detail) == .rejected(.inactiveContext))
        #expect(scoped.submitPresentation(.detail) == .rejected(.inactiveContext))
        #expect(!root.context(for: .primary).isActive)
    }

    @Test func dismissedRouteReleasesWithItsLayerAndDoesNotFollowReusedIdentity() throws {
        let router = Router(rootDestination: .home)
        #expect(router.rootPresentation.submitPresentation(.home) == .applied)
        var node: Node? = try #require(router.presentedNode)
        let lifetime = try #require(node?.lifetime)
        // 本测试覆盖已交宿主的关闭阶段；未接手请求取消时应立即释放层。
        lifetime.claimHost()
        weak var originalLayer = node?.layer
        let id = try #require(node?.id)
        let modal = try router.presentationContext(for: #require(node))
        let scoped = modal.scoped(to: .primary)
        #expect(modal.dismiss() == .applied)
        node = nil
        #expect(originalLayer != nil)
        #expect(!lifetime.finished)
        #expect(!modal.isActive)
        #expect(modal.route == .presentation(id: id, destination: .home))
        #expect(scoped.destination == .home)
        router.rootPresentation.presentationDidDismiss(lifetime: lifetime)
        #expect(originalLayer == nil)
        #expect(lifetime.finished)

        router.rootLayer.presentation = Node(id: id, destination: .detail)
        let current = try router.presentationContext(for: #require(router.presentedNode))
        router.presentedNode?.lifetime.claimHost()
        #expect(current.id == modal.id)
        #expect(current.isActive)
        #expect(current.destination == .detail)
        #expect(modal.destination == nil)
        #expect(scoped.destination == nil)
        #expect(modal.submitPresentation(.detail) == .rejected(.inactiveContext))
        #expect(modal.dismiss() == .rejected(.inactiveContext))
        #expect(scoped.submitPresentation(.detail) == .rejected(.inactiveContext))
        #expect(modal.context(for: .primary).push(.detail) == .rejected(.inactiveContext))
        #expect(current.isActive)
    }
}
