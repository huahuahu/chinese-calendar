import Foundation
@testable import NavigationCore
import Testing

@MainActor
@Suite("普通根层的导航请求与栈根替换")
struct NavigationPrimaryLayerTests {
    private enum Tab: String, Codable { case home, history }
    private enum Route: String, Codable, NavigationDestination {
        case home, detail, tabs
        var providesNavigationContainer: Bool {
            self == .tabs
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, NoNavigationAlert>
    private typealias Snapshot = NavigationSnapshot<Tab, Route, NoNavigationAlert>

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
        #expect(router.submit(.setRoot(nil, on: .primary)) == .rejected)
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
