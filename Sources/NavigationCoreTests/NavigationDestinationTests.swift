import Foundation
@testable import NavigationCore
import Testing

@MainActor
@Suite("Destination 容器与层入口")
struct NavigationDestinationTests {
    private enum Tab: String, Codable { case home, history }
    enum Route: String, Codable, NavigationDestination {
        case root, tabs, home, detail, rootOnly, modalOnly, twoColumn, threeColumn

        var providesNavigationContainer: Bool {
            self == .root || self == .tabs
        }

        var navigationContainer: NavigationContainerKind {
            switch self {
            case .twoColumn: .twoColumn
            case .threeColumn: .threeColumn
            default: .stack
            }
        }

        var allowedNavigationEntries: Set<NavigationDestinationEntry> {
            switch self {
            case .root: [.root]
            case .tabs: [.presentation]
            case .rootOnly: [.root]
            case .modalOnly: [.presentation]
            default: [.root, .stackRoot, .presentation, .push]
            }
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, NoNavigationAlert>
    private typealias Snapshot = NavigationSnapshot<Tab, Route, NoNavigationAlert>

    private func makeRouter() -> Router {
        Router(rootDestination: .root, selectedScope: .home, rootDestinations: [.home: .home, .history: .detail])
    }

    @Test func layerEntryIsIndependentOfTabRootsAndPaths() throws {
        let router = makeRouter()
        let root = router.rootPresentation
        let home = root.context(for: .scope(.home))
        #expect(root.route == .root(destination: .root))
        #expect(home.rootDestination == .home)
        #expect(home.push(.detail))
        root.selectedStack = .scope(.history)
        #expect(root.destination == .root)
        #expect(root.scoped(to: .scope(.history)).route == root.route)
        #expect(root.present(.tabs, initialStack: .scope(.home), rootDestinations: [
            .scope(.home): .home, .scope(.history): .detail
        ]))
        let node = try #require(router.presentedNode)
        let modal = router.presentationContext(for: node)
        #expect(modal.route == .presentation(id: node.id, destination: .tabs))
        #expect(modal.context(for: .scope(.home)).rootDestination == .home)
        #expect(modal.context(for: .scope(.home)).push(.detail))
        modal.selectedStack = .scope(.history)
        #expect(modal.destination == .tabs)
        #expect(node.destination == modal.destination)
        #expect(home.path == [.detail])
        #expect(modal.context(for: .scope(.history)).path.isEmpty)
    }

    @Test func repeatedDestinationHasNewIdentityAndRestoredIdentityDoesNotReviveOldContexts() throws {
        let router = makeRouter()
        #expect(router.rootPresentation.present(.detail))
        let first = try #require(router.presentedNode)
        let old = router.presentationContext(for: first)
        let stack = old.context(for: .primary)
        #expect(stack.rootDestination == .detail)
        old.selectedStack = .scope(.history)
        #expect(old.selectedStack == .primary)
        let snapshot = router.snapshot
        #expect(old.dismiss())
        #expect(old.route == nil)
        #expect(stack.rootDestination == nil)
        router.rootPresentation.presentationDidDismiss()
        #expect(router.rootPresentation.present(.detail))
        let second = try #require(router.presentedNode)
        #expect(second.id != first.id)
        #expect(router.presentationContext(for: second).dismiss())
        router.rootPresentation.presentationDidDismiss()
        let decoded = try JSONDecoder().decode(Snapshot.self, from: JSONEncoder().encode(snapshot))
        #expect(router.restore(decoded))
        let restored = try #require(router.presentedNode)
        #expect(restored.id == first.id)
        #expect(router.rootPresentation.destination == .root)
        #expect(router.presentationContext(for: restored).destination == .detail)
        #expect(!old.isActive)
        #expect(old.destination == nil)
        #expect(!old.scoped(to: .primary).present(.detail))
        #expect(!stack.push(.detail))
        #expect(!old.context(for: .primary).push(.detail))
    }

    @Test func containerPagesCannotEnterPathsThroughAnyPublicMutation() {
        let router = makeRouter()
        let stack = router.context(for: .home)
        let before = router.snapshot
        #expect(!stack.push(.tabs))
        stack.path = [.detail, .tabs]
        router.push(.tabs, on: .history)
        router.setPath([.tabs], for: .history)
        router.paths = [.home: [.detail], .history: [.tabs]]
        router.setRootDestination(.tabs, for: .home)
        #expect(router.submit(.push(.tabs, on: .history), confirmIfPresented: true) == .rejected)
        #expect(router.submit(.replacePath([.detail, .tabs], on: .home)) == .rejected)
        #expect(router.submit(.setRoot(.tabs, on: .home)) == .rejected)
        #expect(!router.rootPresentation.present(.root))
        #expect(router.snapshot == before)
        #expect(router.pendingConfirmation == nil)
    }

    @Test(arguments: [Route.twoColumn, .threeColumn])
    func unsupportedContainersAreRejectedWithoutPretendingToSupportSplitView(route: Route) {
        let router = makeRouter()
        let before = router.snapshot
        #expect(!route.navigationContainer.isSupported)
        #expect(!router.rootPresentation.present(route))
        #expect(!router.context(for: .home).push(route))
        #expect(!router.restore(Snapshot(rootDestination: route, selectedScope: .home)))
        #expect(!router.restore(Snapshot(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: route]
        )))
        #expect(router.snapshot == before)
    }

    @Test func restorationValidatesAllEntrypointsBeforeChangingRootState() {
        let router = makeRouter()
        let before = router.snapshot
        let invalidSnapshots: [Snapshot] = [
            .init(rootDestination: .tabs, selectedScope: .history),
            .init(rootDestination: .root, selectedScope: .history, paths: [.home: [.tabs]]),
            .init(rootDestination: .root, selectedScope: .history, presentation: .node(
                id: UUID(), destination: .root, style: .sheet, layer: .init()
            )),
            .init(rootDestination: .root, selectedScope: .history, presentation: .node(
                id: UUID(), destination: .detail, style: .sheet, layer: .init()
            )),
            .init(rootDestination: .root, selectedScope: .history, presentation: .node(
                id: UUID(), destination: .detail, style: .sheet,
                layer: .init(rootDestinations: [.primary: .detail], paths: [.primary: [.tabs]])
            ))
        ]
        for snapshot in invalidSnapshots {
            #expect(!router.restore(snapshot))
            #expect(router.snapshot == before)
        }
    }

    @Test func ordinaryRootKeepsItsEntryDuringPushAndRestore() {
        let router = Router(rootDestination: .home, selectedScope: .home)
        #expect(router.rootPresentation.destination == .home)
        #expect(router.context(for: .home).rootDestination == .home)
        #expect(router.context(for: .home).push(.detail))
        #expect(router.rootPresentation.destination == .home)
        #expect(router.snapshot.rootDestination == .home)
        #expect(router.restore(router.snapshot))
    }

    @Test func changingStackRootPreservesLayerEntryAndRoundTrips() throws {
        let router = Router(rootDestination: .home, selectedScope: .home)
        let context = router.context(for: .home)
        router.setRootDestination(.detail, for: .home)
        #expect(router.rootPresentation.destination == .home)
        #expect(context.rootDestination == .detail)
        let snapshot = try JSONDecoder().decode(Snapshot.self, from: JSONEncoder().encode(router.snapshot))
        router.setRootDestination(.home, for: .home)
        #expect(router.restore(snapshot))
        #expect(router.rootPresentation.destination == .home)
        #expect(context.rootDestination == .detail)
        #expect(router.snapshot == snapshot)
    }

    @Test func ordinaryEntriesDoNotNeedExplicitTabRootPermissionToRestore() throws {
        let router = Router(rootDestination: .rootOnly, selectedScope: .home)
        #expect(router.restore(router.snapshot))
        #expect(router.rootPresentation.present(.modalOnly))
        let snapshot = router.snapshot
        let node = try #require(router.presentedNode)
        #expect(router.presentationContext(for: node).dismiss())
        router.rootPresentation.presentationDidDismiss()
        #expect(router.restore(snapshot))
        #expect(router.presentedNode?.destination == .modalOnly)
    }
}
