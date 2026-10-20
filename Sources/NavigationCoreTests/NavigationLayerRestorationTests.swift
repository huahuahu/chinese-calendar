import NavigationCore
import Testing

@MainActor
@Suite("导航层承载切换恢复")
struct NavigationLayerRestorationTests {
    private enum Tab: Hashable { case home }
    private enum Route: NavigationDestination {
        case tabs, home, detail

        var providesNavigationContainer: Bool {
            self == .tabs
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, NoNavigationAlert>
    private typealias Snapshot = NavigationSnapshot<Tab, Route, NoNavigationAlert>

    @Test func restoringCoreLayerInvalidatesFormerNamedStackContext() {
        let router = Router(
            rootDestination: .tabs, initialStack: .scope(.home),
            rootDestinations: [.scope(.home): .home], paths: [.scope(.home): [.detail]]
        )
        let named = router.rootPresentation.context(for: .scope(.home))
        let presentation = router.rootPresentation
        let snapshot = Snapshot(rootDestination: .home, layer: .init(rootDestinations: [.primary: .home]))

        #expect(router.restore(snapshot))
        #expect(presentation === router.rootPresentation)
        #expect(!named.isActive)
        #expect(named.rootDestination == nil)
        #expect(named.path.isEmpty)
        #expect(!named.push(.detail))
        #expect(!named.setRootDestination(.detail))
        #expect(router.snapshot == snapshot)
        let primary = router.rootPresentation.context(for: .primary)
        #expect(primary.isActive)
        #expect(primary.rootDestination == .home)
        #expect(primary.push(.detail))
    }

    @Test func restoringExternalContainerInvalidatesFormerPrimaryStackContext() {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        let primary = router.rootPresentation.context(for: .primary)
        let presentation = router.rootPresentation
        let snapshot = Snapshot(
            rootDestination: .tabs,
            layer: .init(selectedStack: .scope(.home), rootDestinations: [.scope(.home): .home])
        )

        #expect(router.restore(snapshot))
        #expect(presentation === router.rootPresentation)
        #expect(!primary.isActive)
        #expect(primary.rootDestination == nil)
        #expect(primary.path.isEmpty)
        #expect(!primary.push(.detail))
        #expect(!primary.setRootDestination(.detail))
        #expect(router.snapshot == snapshot)
        let named = router.rootPresentation.context(for: .scope(.home))
        #expect(named.isActive)
        #expect(named.rootDestination == .home)
        #expect(named.push(.detail))
    }

    @Test func restoringSameContainerOwnershipPreservesPrimaryStackContext() {
        let router = Router(rootDestination: .home, paths: [.primary: [.detail]])
        let primary = router.rootPresentation.context(for: .primary)
        let snapshot = Snapshot(rootDestination: .home, layer: .init(rootDestinations: [.primary: .detail]))

        #expect(router.restore(snapshot))
        #expect(primary === router.rootPresentation.context(for: .primary))
        #expect(primary.isActive)
        #expect(primary.rootDestination == .detail)
        #expect(primary.path.isEmpty)
        #expect(primary.push(.home))
    }
}
