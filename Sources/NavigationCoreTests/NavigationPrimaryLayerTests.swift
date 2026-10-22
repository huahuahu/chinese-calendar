import Foundation
@testable import NavigationCore
import Testing

@MainActor
@Suite("普通根层的导航请求与栈根替换")
struct NavigationPrimaryLayerTests {
    private enum Tab: String, NavigationScope { case home, history }
    private enum Route: String, NavigationDestination {
        case home, detail, tabs
        var providesNavigationContainer: Bool {
            self == .tabs
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, NoNavigationAlert>

    @Test(arguments: [false, true], [false, true])
    func presentationRequestsPreserveContainerStacks(fullScreen: Bool, namedStack: Bool) throws {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        let initialStack: NavigationStackID<Tab> = namedStack ? .scope(.history) : .primary
        let roots: [NavigationStackID<Tab>: Route] = [initialStack: .detail, .scope(.home): .home]
        let paths: [NavigationStackID<Tab>: [Route]] = [initialStack: [.home], .scope(.home): [.detail]]
        let invalid: NavigationPresentationRequest<Tab, Route, NoNavigationAlert> = fullScreen
            ? .fullScreen(.tabs, initialStack: initialStack) : .sheet(.tabs, initialStack: initialStack)
        #expect(router.rootPresentation.present(invalid) == .rejected(.missingRootDestination))
        #expect(router.presentedNode == nil)
        #expect(router.rootLayer.roots == [.primary: .home])
        #expect(router.rootLayer.paths == [.primary: [.detail]])
        let request: NavigationPresentationRequest<Tab, Route, NoNavigationAlert> = fullScreen
            ? .fullScreen(.tabs, initialStack: initialStack, rootDestinations: roots, paths: paths)
            : .sheet(.tabs, initialStack: initialStack, rootDestinations: roots, paths: paths)

        #expect(router.rootPresentation.present(request) == .applied)
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
        #expect(router.rootPresentation.present(.detail) == .applied)
        let parent = try #require(router.sheet)
        let initialStack: NavigationStackID<Tab> = namedStack ? .scope(.history) : .primary
        let roots: [NavigationStackID<Tab>: Route] = [initialStack: .detail, .scope(.home): .home]
        let paths: [NavigationStackID<Tab>: [Route]] = [initialStack: [.home], .scope(.home): [.detail]]
        let invalid = fullScreen
            ? router.presentFullScreen(.tabs, initialStack: initialStack)
            : router.presentSheet(.tabs, initialStack: initialStack)
        #expect(invalid == .rejected(.missingRootDestination))
        #expect(router.sheet === parent)
        #expect(parent.presentation == nil)
        #expect(parent.layer.roots == [.primary: .detail])
        #expect(parent.path.isEmpty)
        #expect(router.rootLayer.paths == [.primary: [.detail]])
        let accepted = fullScreen
            ? router.presentFullScreen(.tabs, initialStack: initialStack, rootDestinations: roots, paths: paths)
            : router.presentSheet(.tabs, initialStack: initialStack, rootDestinations: roots, paths: paths)

        #expect(accepted == .applied)
        let node = try #require(parent.presentation)
        #expect(router.sheet === parent)
        #expect(node.style == (fullScreen ? .fullScreen : .sheet))
        #expect(node.destination == .tabs)
        #expect(node.layer.selectedStack == initialStack)
        #expect(node.layer.roots == roots)
        #expect(node.layer.paths == paths)
        #expect(router.rootPresentation.context(for: .primary).path == [.detail])
    }

    @Test func primarySelectionHasNoScopeForCoreAndExternalContainers() {
        for destination in [Route.home, .tabs] {
            let router = Router(
                rootDestination: destination,
                rootDestinations: destination.providesNavigationContainer ? [.primary: .home] : [:],
                paths: [.primary: [.detail]]
            )
            #expect(router.selectedScope == nil)
            #expect(router.rootPresentation.selectedStack == .primary)
            #expect(router.selectedDestination == .detail)
            router.selectedScope = nil
            #expect(router.selectedScope == nil)
            #expect(router.rootPresentation.selectedStack == .primary)
            #expect(router.rootLayer.roots == [.primary: .home])
            #expect(router.rootLayer.paths == [.primary: [.detail]])
        }
        let router = Router(rootDestination: .home)
        router.selectedScope = .history
        #expect(router.selectedScope == nil)
        #expect(router.rootPresentation.selectedStack == .primary)
        #expect(router.rootLayer.roots == [.primary: .home])
        #expect(router.rootLayer.paths.isEmpty)
    }

    @Test func namedScopeSelectionPreservesPathsAndIgnoresNilWrites() {
        let router = Router(
            rootDestination: .tabs, initialStack: .scope(.home),
            rootDestinations: [.primary: .home, .scope(.home): .home, .scope(.history): .detail],
            paths: [.scope(.home): [.detail], .scope(.history): [.home]]
        )
        #expect(router.selectedScope == .home)
        router.selectedScope = .history
        #expect(router.selectedScope == .history)
        #expect(router.rootPresentation.selectedStack == .scope(.history))
        router.selectedScope = nil
        #expect(router.selectedScope == .history)
        #expect(router.rootPresentation.selectedStack == .scope(.history))
        router.rootPresentation.selectedStack = .primary
        #expect(router.selectedScope == nil)
        router.selectedScope = .home
        #expect(router.selectedScope == .home)
        #expect(router.rootLayer.roots == [.primary: .home, .scope(.home): .home, .scope(.history): .detail])
        #expect(router.rootLayer.paths == [.scope(.home): [.detail], .scope(.history): [.home]])
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
        #expect(router.submit(.selectStack(.scope(.history))) == .rejected(.incompatibleContainer))
        #expect(router.submit(.push(.detail, on: .scope(.history))) == .rejected(.incompatibleContainer))
        #expect(router.submit(.replacePath([.tabs], on: .scope(.home))) == .rejected(.incompatibleContainer))
        #expect(router.rootPresentation.selectedStack == .primary)
        #expect(stack.rootDestination == .detail)
        #expect(stack.path.isEmpty)
        #expect(router.presentedNode == nil)
    }

    @Test func primaryDeepLinkCancellationAndApprovalWaitForTheRootDismissal() throws {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        let root = router.rootPresentation.context(for: .primary)
        #expect(router.rootPresentation.present(.detail, paths: [.primary: [.home]]) == .applied)
        let parent = try #require(router.sheet)
        let modal = router.presentationContext(for: parent)
        #expect(modal.present(.home, style: .fullScreen) == .applied)
        let child = try router.presentationContext(for: #require(parent.fullScreen))
        #expect(router.submit(.push(.tabs, on: .primary), confirmIfPresented: true) == .awaitingConfirmation)
        let cancelled = try #require(child.confirmation)
        #expect(root.setPath([.tabs]) == .rejected(.awaitingConfirmation))
        #expect(modal.context(for: .primary).setPath([.tabs]) == .rejected(.awaitingConfirmation))
        #expect(root.setRootDestination(.tabs) == .rejected(.awaitingConfirmation))
        #expect(modal.context(for: .primary).setRootDestination(.tabs) == .rejected(.awaitingConfirmation))
        child.cancelNavigation(id: cancelled.id)
        #expect(router.sheet === parent)
        #expect(parent.fullScreen?.layer.id == child.id)
        #expect(root.path == [.detail])
        #expect(modal.context(for: .primary).path == [.home])
        #expect(child.context(for: .primary).path.isEmpty)
        #expect(router.pendingConfirmation == nil)

        #expect(router.submit(.push(.tabs, on: .primary), confirmIfPresented: true) == .awaitingConfirmation)
        let approved = try #require(child.confirmation)
        child.confirmNavigation(id: approved.id)
        #expect(router.presentedNode == nil)
        #expect(router.isAwaitingPresentationDismissal)
        #expect(root.path == [.detail])
        #expect(root.setPath([.tabs]) == .rejected(.awaitingDismissal))
        #expect(root.setRootDestination(.tabs) == .rejected(.awaitingDismissal))
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
        #expect(root.setPath([.home, .tabs]) == .applied)
        #expect(root.path == [.home, .tabs])
    }

    @Test func replacingRootThroughEachContextClearsOnlyItsPath() throws {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        let root = router.rootPresentation.context(for: .primary)
        #expect(router.rootPresentation.present(.detail, paths: [.primary: [.home]]) == .applied)
        let node = try #require(router.sheet)
        let modal = router.presentationContext(for: node)
        let modalStack = modal.context(for: .primary)
        #expect(root.setRootDestination(.detail) == .applied)
        #expect(root.rootDestination == .detail)
        #expect(root.path.isEmpty)
        #expect(modalStack.path == [.home])
        #expect(modalStack.setRootDestination(.tabs) == .applied)
        #expect(modalStack.rootDestination == .tabs)
        #expect(modalStack.path.isEmpty)
        #expect(router.rootPresentation.destination == .home)
        #expect(modal.destination == .detail)
        #expect(root.push(.home) == .applied)
        #expect(modalStack.path.isEmpty)
        #expect(modal.dismiss() == .applied)
        #expect(modalStack.setRootDestination(.home) == .rejected(.inactiveContext))
        router.rootPresentation.presentationDidDismiss()
        #expect(root === router.rootPresentation.context(for: .primary))
        #expect(root.rootDestination == .detail)
        #expect(root.path == [.home])
        #expect(root.setRootDestination(.home) == .applied)
        #expect(root.rootDestination == .home)
        #expect(root.path.isEmpty)
        #expect(modalStack.setRootDestination(.home) == .rejected(.inactiveContext))
    }
}
