import Foundation
@testable import NavigationCore
import Observation
import Synchronization
import Testing

@MainActor
@Suite("独立栈状态与访问约束")
struct NavigationStackStateTests {
    private enum Tab: String, Codable, NavigationScope { case home, history }
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
        #expect(context.setPath([.first, .second]))
        #expect(state.path == [.first, .second])
        #expect(context.rootDestination == .first)
        context.path = [.second]
        #expect(context.push(.third))
        #expect(state.path == [.second, .third])
        #expect(context.pop())
        state.path = [.first]
        #expect(context.path == [.first])

        policy.canMutate = false
        #expect(!context.setPath([.third]))
        context.path = [.third]
        #expect(!context.push(.second))
        #expect(!context.pop())
        #expect(state.path == [.first])
        #expect(context.isActive)

        policy.isActive = false
        policy.canMutate = true
        #expect(!context.isActive)
        #expect(context.path.isEmpty)
        #expect(!context.setPath([.third]))
        #expect(!context.push(.second))
        #expect(state.path == [.first])
    }

    @Test func replacingAllPathsKeepsExistingContextsConnected() {
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second],
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

        router.setRootDestination(.third, for: .home)
        #expect(router.rootDestination(for: .home) == .third)
        #expect(home.path.isEmpty)
        #expect(router.paths[.home] == nil)
        #expect(home.setPath([.second]))
        #expect(home.push(.third))
        #expect(home.rootDestination == .third)
        #expect(home.path == [.second, .third])
        #expect(history.path == [.third])
    }

    @Test func acquiringContextsDoesNotWriteEmptyPathsIntoSnapshots() throws {
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second],
            paths: [.history: []]
        )
        router.presentSheet(.first)
        let before = router.snapshot
        _ = router.context(for: .home)
        _ = router.context(for: .history)
        let node = try #require(router.sheet)
        _ = router.context(for: node)
        _ = router.presentationContext(for: node).context(for: .scope(.history))
        #expect(router.snapshot == before)
        #expect(router.paths[.home] == nil)
        #expect(router.paths[.history] == nil)

        let bytes = try JSONEncoder().encode(before)
        let saved = try JSONDecoder().decode(NavigationSnapshot<Tab, Route, NoNavigationAlert>.self, from: bytes)
        let restored = Router(
            rootDestination: .root,
            selectedScope: .history,
            rootDestinations: [.home: .first, .history: .second]
        )
        #expect(restored.restore(saved))
        #expect(restored.snapshot == before)
    }

    @Test func observingAPathTracksThatStackInsteadOfEveryTabsPath() {
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second]
        )
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
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second],
            paths: [.home: [.first]]
        )
        let home = router.context(for: .home)
        let history = router.context(for: .history)
        #expect(router.restore(.init(
            rootDestination: .root,
            selectedScope: .history,
            rootDestinations: [.home: .first, .history: .second],
            paths: [.history: [.second]]
        )))
        #expect(home === router.context(for: .home))
        #expect(history === router.context(for: .history))
        #expect(home.path.isEmpty)
        #expect(history.path == [.second])
        #expect(history.push(.third))
        #expect(router.path(for: .history) == [.second, .third])
    }

    @Test func rootStackWritesRespectConfirmationAndDismissalTransactions() throws {
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second],
            paths: [.home: [.first]]
        )
        let home = router.context(for: .home)
        router.presentSheet(.second)
        router.submit(.replacePath([.third], on: .home), confirmIfPresented: true)
        let confirmation = try #require(router.pendingConfirmation)
        #expect(!home.setPath([.second]))
        home.path = [.second]
        #expect(!home.push(.second))
        #expect(!home.pop())
        #expect(home.path == [.first])
        router.cancelConfirmation(id: confirmation.id)
        #expect(home.setPath([.first, .second]))
        router.submit(.replacePath([.third], on: .home))
        #expect(home.isActive)
        #expect(router.isAwaitingPresentationDismissal)
        #expect(!home.setPath([]))
        home.path = []
        #expect(!home.pop())
        #expect(home.path == [.first, .second])
        router.rootPresentation.presentationDidDismiss()
        #expect(home.path == [.third])
        #expect(home.setPath([]))
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

extension NavigationStackStateTests {
    private typealias Layer = NavigationLayerSnapshot<Tab, Route, NoNavigationAlert>

    @Test func lookupCannotCreateAnUnrootedStackAndLaterRegistrationDoesNotReviveIt() {
        let router = Router(rootDestination: .root, selectedScope: .home, rootDestinations: [.home: .first])
        let before = router.snapshot
        let missing = router.context(for: .history)
        #expect(!missing.isActive)
        #expect(!missing.push(.second))
        #expect(!missing.setRootDestination(.second))
        router.selectedScope = .history
        router.rootPresentation.selectedStack = .scope(.history)
        router.setPath([.second], for: .history)
        router.paths = [.history: [.second]]
        router.push(.second, on: .history)
        #expect(router.submit(.push(.second, on: .history)) == .rejected)
        #expect(router.snapshot == before)
        #expect(router.submit(.setRoot(.second, on: .history)) == .applied)
        let registered = router.context(for: .history)
        #expect(registered.isActive)
        #expect(registered.rootDestination == .second)
        #expect(!missing.isActive)
        #expect(!missing.setPath([.first]))
    }

    @Test func restoringRemovedStacksInvalidatesOnlyTheirOldContexts() {
        let router = Router(
            rootDestination: .root, selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second], paths: [.history: [.first]]
        )
        let original = router.snapshot
        let home = router.context(for: .home)
        let history = router.context(for: .history)
        let reduced = Router(rootDestination: .root, selectedScope: .home, rootDestinations: [.home: .second]).snapshot
        #expect(router.restore(reduced))
        #expect(home === router.context(for: .home))
        #expect(home.rootDestination == .second)
        #expect(!history.isActive)
        #expect(router.restore(original))
        #expect(!history.isActive)
        #expect(!history.push(.second))
        #expect(router.context(for: .history).path == [.first])
    }

    @Test func emptyAndMissingPathsHaveTheSameSnapshotRepresentation() throws {
        let empty = Layer(rootDestinations: [.primary: .first], paths: [.primary: []])
        let absent = Layer(rootDestinations: [.primary: .first])
        #expect(empty == absent)
        let encoder = JSONEncoder()
        var json = try #require(JSONSerialization.jsonObject(with: encoder.encode(absent)) as? [String: Any])
        let legacy: [NavigationStackID<Tab>: [Route]] = [.primary: []]
        json["paths"] = try JSONSerialization.jsonObject(with: encoder.encode(legacy))
        let decoded = try JSONDecoder().decode(Layer.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(decoded == absent)
        let router = Router(rootDestination: .first)
        #expect(router.restore(.init(rootDestination: .first, layer: decoded)))
        let before = router.snapshot
        let stack = router.rootPresentation.context(for: .primary)
        #expect(stack.setPath([]))
        #expect(router.snapshot == before)
    }

    @Test func containersRejectMissingRootsBeforeChangingPresentationOrRestoration() {
        let router = Router(rootDestination: .first, paths: [.primary: [.second]])
        let before = router.snapshot
        #expect(!router.rootPresentation.present(.root))
        #expect(!router.rootPresentation.present(
            .root, initialStack: .scope(.history), rootDestinations: [.scope(.home): .first]
        ))
        #expect(!router.rootPresentation.present(
            .root, rootDestinations: [.primary: .first], paths: [.scope(.history): []]
        ))
        #expect(!router.restore(.init(rootDestination: .root, layer: .init())))
        #expect(!router.restore(.init(rootDestination: .root, layer: .init(
            rootDestinations: [.primary: .first], paths: [.scope(.history): [.second]]
        ))))
        #expect(router.snapshot == before)
    }
}
