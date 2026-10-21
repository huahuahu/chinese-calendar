import Foundation
@testable import NavigationCore
import Testing

@MainActor
@Suite("根层与递归模态的统一快照")
struct NavigationLayerSnapshotTests {
    private enum Tab: String, Codable { case home, history }
    private enum Route: String, Codable, NavigationDestination {
        case home, detail, tabs
        var providesNavigationContainer: Bool {
            self == .tabs
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, NoNavigationAlert>
    private typealias Snapshot = NavigationSnapshot<Tab, Route, NoNavigationAlert>
    private typealias Layer = NavigationLayerSnapshot<Tab, Route, NoNavigationAlert>
    private typealias Presentation = NavigationPresentationSnapshot<Tab, Route, NoNavigationAlert>

    @Test func replacedStackRootsAndNestedContainerRoundTripWithoutChangingLayerEntries() throws {
        let parentID = UUID()
        let childID = UUID()
        let snapshot = Snapshot(rootDestination: .home, layer: Layer(
            rootDestinations: [.primary: .detail], paths: [.primary: [.tabs]],
            presentation: .node(id: parentID, destination: .detail, style: .sheet, layer: Layer(
                rootDestinations: [.primary: .tabs], paths: [.primary: [.home]],
                presentation: .node(id: childID, destination: .tabs, style: .fullScreen, layer: Layer(
                    selectedStack: .scope(.history),
                    rootDestinations: [.scope(.home): .home, .scope(.history): .detail],
                    paths: [.scope(.home): [.detail], .scope(.history): [.home, .tabs]]
                ))
            ))
        ))
        let decoded = try JSONDecoder().decode(Snapshot.self, from: JSONEncoder().encode(snapshot))
        #expect(decoded == snapshot)
        let router = Router(rootDestination: .home)
        let rootStack = router.rootPresentation.context(for: .primary)
        #expect(router.restore(decoded))
        #expect(router.snapshot == decoded)
        #expect(rootStack === router.rootPresentation.context(for: .primary))
        #expect(rootStack.rootDestination == .detail)
        #expect(rootStack.path == [.tabs])
        #expect(router.rootPresentation.destination == .home)
        let parent = try #require(router.sheet)
        let modal = router.presentationContext(for: parent)
        #expect(parent.id == parentID)
        #expect(modal.destination == .detail)
        #expect(modal.context(for: .primary).rootDestination == .tabs)
        #expect(modal.context(for: .primary).path == [.home])
        let child = try #require(parent.fullScreen)
        let tabs = router.presentationContext(for: child)
        #expect(child.id == childID)
        #expect(tabs.destination == .tabs)
        #expect(tabs.selectedStack == .scope(.history))
        #expect(tabs.context(for: .scope(.home)).path == [.detail])
        #expect(tabs.context(for: .scope(.history)).path == [.home, .tabs])
        #expect(tabs.context(for: .scope(.history)).push(.detail))
        #expect(modal.context(for: .primary).path == [.home])
        #expect(rootStack.path == [.tabs])
    }

    @Test func malformedSingleStackLayersAreRejectedAtRootAndAtAnyModalDepth() {
        let router = Router(
            rootDestination: .tabs, initialStack: .scope(.history),
            rootDestinations: [.scope(.home): .home, .scope(.history): .detail],
            paths: [.scope(.history): [.home]]
        )
        let history = router.rootPresentation.context(for: .scope(.history))
        let before = router.snapshot
        let malformed: [Layer] = [
            .init(),
            .init(selectedStack: .scope(.home), rootDestinations: [.primary: .home]),
            .init(rootDestinations: [.scope(.home): .home]),
            .init(rootDestinations: [.primary: .home, .scope(.history): .detail]),
            .init(rootDestinations: [.primary: .home], paths: [.scope(.history): [.detail]])
        ]
        for layer in malformed {
            let invalidRoot = Snapshot(rootDestination: .home, layer: layer)
            let invalidChild = Presentation.node(id: UUID(), destination: .home, style: .sheet, layer: layer)
            let invalidGrandchild = Presentation.node(
                id: UUID(), destination: .tabs, style: .fullScreen,
                layer: .init(selectedStack: .scope(.home), presentation: invalidChild)
            )
            let invalidModal = Snapshot(rootDestination: .tabs, layer: Layer(
                selectedStack: .scope(.home), rootDestinations: [.scope(.home): .detail],
                paths: [.scope(.home): [.tabs]], presentation: invalidGrandchild
            ))
            for snapshot in [invalidRoot, invalidModal] {
                #expect(!router.restore(snapshot))
                #expect(router.snapshot == before)
                #expect(history.isActive)
                #expect(history.path == [.home])
                #expect(router.rootPresentation.selectedStack == .scope(.history))
            }
        }
    }

    @Test func duplicateModalIdentityIsRejectedBeforeReplacingTheRootLayer() {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        let root = router.rootPresentation.context(for: .primary)
        let before = router.snapshot
        let duplicateID = UUID()
        let snapshot = Snapshot(rootDestination: .tabs, layer: Layer(
            selectedStack: .scope(.history), rootDestinations: [.scope(.history): .tabs],
            presentation: .node(id: duplicateID, destination: .home, style: .sheet, layer: Layer(
                rootDestinations: [.primary: .home],
                presentation: .node(id: duplicateID, destination: .detail, style: .fullScreen, layer: Layer(
                    rootDestinations: [.primary: .detail]
                ))
            ))
        ))
        #expect(!router.restore(snapshot))
        #expect(router.snapshot == before)
        #expect(root.isActive)
        #expect(root.rootDestination == .home)
        #expect(root.path == [.detail])
    }

    @Test func malformedSingleStackPresentationsLeaveTheCurrentLayerUntouched() {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        let before = router.snapshot
        #expect(!router.rootPresentation.present(.detail, initialStack: .scope(.home)))
        #expect(!router.rootPresentation.present(.detail, rootDestinations: [.scope(.home): .home]))
        #expect(!router.rootPresentation.present(.detail, paths: [.scope(.history): [.home]]))
        #expect(router.snapshot == before)
        #expect(router.pendingConfirmation == nil)
        #expect(!router.isAwaitingPresentationDismissal)
    }
}
