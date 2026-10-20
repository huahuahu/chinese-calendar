import Foundation
@testable import NavigationCore
import Observation
import Synchronization
import Testing

@MainActor
@Suite("独立栈状态与访问约束")
struct NavigationStackStateTests {
    private enum Tab: String, Codable { case home, history }
    private enum Route: String, Codable, NavigationDestination {
        case root, first, second, third
        var providesNavigationContainer: Bool {
            self == .root
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, NoNavigationAlert>

    @Test func contextWorksWithoutRouterOrPresentationLayer() {
        let state = NavigationStackState<Route>(rootDestination: .first, path: [.second])
        let policy = AccessPolicy()
        let context = NavigationContext<Tab, Route>(
            id: .primary,
            state: state,
            access: NavigationStackAccess(isActive: { policy.isActive }, canMutate: { policy.canMutate })
        )
        #expect(context.isActive)
        #expect(context.path == [.second])
        #expect(context.push(.third))
        #expect(state.path == [.second, .third])
        #expect(context.pop())
        state.path = [.first]
        #expect(context.path == [.first])

        policy.canMutate = false
        context.path = [.third]
        #expect(!context.push(.second))
        #expect(!context.pop())
        #expect(state.path == [.first])
        #expect(context.isActive)

        policy.isActive = false
        policy.canMutate = true
        #expect(!context.isActive)
        #expect(context.path.isEmpty)
        #expect(!context.push(.second))
        #expect(state.path == [.first])
    }

    @Test func replacingAllPathsKeepsExistingContextsConnected() {
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first],
            paths: [.home: [.second]]
        )
        let home = router.context(for: .home)
        let history = router.context(for: .history)
        router.paths = [.history: [.third]]
        #expect(home === router.context(for: .home))
        #expect(history === router.context(for: .history))
        #expect(home.isActive)
        #expect(home.path.isEmpty)
        #expect(router.paths[.home] == nil)
        #expect(history.path == [.third])
        #expect(router.rootDestination(for: .home) == .first)
        #expect(home.push(.second))
        #expect(router.paths == [.home: [.second], .history: [.third]])

        router.setRootDestination(nil, for: .home)
        #expect(router.rootDestination(for: .home) == nil)
        #expect(home.path.isEmpty)
        #expect(router.paths[.home] == [])
        #expect(history.path == [.third])
    }

    @Test func acquiringContextsDoesNotWriteEmptyPathsIntoSnapshots() throws {
        let router = Router(rootDestination: .root, selectedScope: .home, paths: [.history: []])
        router.presentSheet(.first)
        let before = router.snapshot
        _ = router.context(for: .home)
        _ = router.context(for: .history)
        let node = try #require(router.sheet)
        _ = router.context(for: node)
        _ = router.presentationContext(for: node).context(for: .scope(.history))
        #expect(router.snapshot == before)
        #expect(router.paths[.home] == nil)
        #expect(router.paths[.history] == [])

        let bytes = try JSONEncoder().encode(before)
        let saved = try JSONDecoder().decode(NavigationSnapshot<Tab, Route, NoNavigationAlert>.self, from: bytes)
        let restored = Router(rootDestination: .root, selectedScope: .history)
        #expect(restored.restore(saved))
        #expect(restored.snapshot == before)
    }

    @Test func observingAPathTracksThatStackInsteadOfEveryTabsPath() {
        let router = Router(rootDestination: .root, selectedScope: .home)
        let home = router.context(for: .home)
        let history = router.context(for: .history)
        let changes = Mutex(0)
        withObservationTracking {
            _ = home.path
        } onChange: {
            changes.withLock { $0 += 1 }
        }
        #expect(history.push(.first))
        #expect(changes.withLock { $0 } == 0)
        router.setPath([.second], for: .home)
        #expect(changes.withLock { $0 } == 1)
        #expect(home.path == [.second])
    }

    @Test func rootContextRemainsConnectedAfterSnapshotRestoration() {
        let router = Router(rootDestination: .root, selectedScope: .home, paths: [.home: [.first]])
        let home = router.context(for: .home)
        let history = router.context(for: .history)
        #expect(router.restore(.init(rootDestination: .root, selectedScope: .history, paths: [.history: [.second]])))
        #expect(home === router.context(for: .home))
        #expect(history === router.context(for: .history))
        #expect(home.path.isEmpty)
        #expect(history.path == [.second])
        #expect(history.push(.third))
        #expect(router.path(for: .history) == [.second, .third])
    }

    @Test func rootStackWritesRespectConfirmationAndDismissalTransactions() throws {
        let router = Router(rootDestination: .root, selectedScope: .home, paths: [.home: [.first]])
        let home = router.context(for: .home)
        router.presentSheet(.second)
        router.submit(.replacePath([.third], on: .home), confirmIfPresented: true)
        let confirmation = try #require(router.pendingConfirmation)
        home.path = [.second]
        #expect(!home.push(.second))
        #expect(!home.pop())
        #expect(home.path == [.first])
        router.cancelConfirmation(id: confirmation.id)
        #expect(home.push(.second))
        router.submit(.replacePath([.third], on: .home))
        #expect(home.isActive)
        home.path = []
        #expect(!home.pop())
        #expect(home.path == [.first, .second])
        router.rootPresentation.presentationDidDismiss()
        #expect(home.path == [.third])
        #expect(home.push(.first))
    }
}

private extension NavigationStackStateTests {
    @MainActor
    final class AccessPolicy {
        var isActive = true
        var canMutate = true
    }
}
