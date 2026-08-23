@testable import NavigationCore
import SwiftUI
import Testing

private enum TestScope: Hashable {
    case primary
    case secondary
}

private enum TestDestination: Hashable {
    case first
    case second
    case third
}

@MainActor
@Test func scopePathsAreIndependent() {
    let router = NavigationRouter<TestScope, TestDestination>(selectedScope: .primary)

    router.push(.first, on: .primary)
    router.push(.second, on: .secondary)

    #expect(router.path(for: .primary) == [.first])
    #expect(router.path(for: .secondary) == [.second])
    #expect(router.selectedScope == .secondary)
}

@MainActor
@Test func settingRootClearsOnlyItsScopePath() {
    let router = NavigationRouter<TestScope, TestDestination>(
        selectedScope: .primary,
        paths: [.primary: [.first], .secondary: [.second]]
    )

    router.setRootDestination(.third, for: .primary)

    #expect(router.rootDestination(for: .primary) == .third)
    #expect(router.path(for: .primary).isEmpty)
    #expect(router.path(for: .secondary) == [.second])
}

@MainActor
@Test func rootPresentationsCreateIndependentNodes() {
    let sheetRouter = NavigationRouter<TestScope, TestDestination>(selectedScope: .primary)
    let fullScreenRouter = NavigationRouter<TestScope, TestDestination>(selectedScope: .primary)

    sheetRouter.presentSheet(.first)
    fullScreenRouter.presentFullScreen(.second)

    #expect(sheetRouter.sheet?.destination == .first)
    #expect(sheetRouter.sheet?.path.isEmpty == true)
    #expect(fullScreenRouter.fullScreen?.destination == .second)
    #expect(fullScreenRouter.fullScreen?.path.isEmpty == true)
}

@MainActor
@Test func presentationNestsAtFrontmostNode() throws {
    let router = NavigationRouter<TestScope, TestDestination>(selectedScope: .primary)
    router.presentSheet(.first)
    let parent = try #require(router.sheet)

    router.presentFullScreen(.second)
    router.presentSheet(.third)

    #expect(router.fullScreen == nil)
    #expect(parent.fullScreen?.destination == .second)
    #expect(parent.fullScreen?.sheet?.destination == .third)
}

@MainActor
@Test func presentedPushDoesNotChangeScopePath() throws {
    let router = NavigationRouter<TestScope, TestDestination>(selectedScope: .primary)
    router.presentSheet(.first)

    let sheet = try #require(router.sheet)
    sheet.push(.second)

    #expect(sheet.path == [.second])
    #expect(router.path(for: .primary).isEmpty)
}

@MainActor
@Test func dismissingChildReturnsToParentNode() throws {
    let router = NavigationRouter<TestScope, TestDestination>(selectedScope: .primary)
    router.presentSheet(.first)
    let parent = try #require(router.sheet)
    parent.presentSheet(.second)

    parent.dismissSheet()

    #expect(router.sheet === parent)
    #expect(parent.sheet == nil)
}

@MainActor
@Test func navigationRequestCasesUpdateTheirTargetScope() {
    let router = NavigationRouter<TestScope, TestDestination>(
        selectedScope: .primary,
        rootDestinations: [.secondary: .first],
        paths: [.secondary: [.second]]
    )

    #expect(router.submit(.selectScope(.secondary)) == .applied)
    #expect(router.selectedScope == .secondary)

    #expect(router.submit(.setRoot(.third, on: .secondary)) == .applied)
    #expect(router.selectedScope == .secondary)
    #expect(router.rootDestination(for: .secondary) == .third)
    #expect(router.path(for: .secondary).isEmpty)

    #expect(router.submit(.replacePath([.first, .second], on: .primary)) == .applied)
    #expect(router.selectedScope == .primary)
    #expect(router.path(for: .primary) == [.first, .second])

    #expect(router.submit(.push(.third, on: .secondary)) == .applied)
    #expect(router.selectedScope == .secondary)
    #expect(router.path(for: .secondary) == [.third])
}

@MainActor
@Test func requestDismissesPresentationTreeAndWaitsForDismissalCompletion() throws {
    let router = NavigationRouter<TestScope, TestDestination>(
        selectedScope: .primary,
        rootDestinations: [.primary: .first]
    )
    router.presentSheet(.second)
    let sheet = try #require(router.sheet)
    sheet.presentFullScreen(.third)

    let result = router.submit(.setRoot(.second, on: .secondary))

    #expect(result == .deferredUntilPresentationDismisses)
    #expect(router.sheet == nil)
    #expect(router.fullScreen == nil)
    #expect(router.isAwaitingPresentationDismissal)
    #expect(router.deferredRequest == .setRoot(.second, on: .secondary))
    #expect(router.selectedScope == .primary)
    #expect(router.rootDestination(for: .primary) == .first)
    #expect(router.rootDestination(for: .secondary) == nil)

    let appliedRequest = router.applyDeferredRequestIfReady()

    #expect(appliedRequest == .setRoot(.second, on: .secondary))
    #expect(router.deferredRequest == nil)
    #expect(!router.isAwaitingPresentationDismissal)
    #expect(router.selectedScope == .secondary)
    #expect(router.rootDestination(for: .secondary) == .second)
}

@MainActor
@Test func latestRequestWinsWhilePresentationDismissalIsInProgress() {
    let router = NavigationRouter<TestScope, TestDestination>(selectedScope: .primary)
    router.presentFullScreen(.first)

    #expect(router.submit(.push(.second, on: .primary)) == .deferredUntilPresentationDismisses)
    #expect(router.submit(.replacePath([.third], on: .secondary)) == .deferredUntilPresentationDismisses)
    #expect(router.path(for: .primary).isEmpty)
    #expect(router.path(for: .secondary).isEmpty)
    #expect(router.deferredRequest == .replacePath([.third], on: .secondary))

    #expect(router.applyDeferredRequestIfReady() == .replacePath([.third], on: .secondary))
    #expect(router.path(for: .primary).isEmpty)
    #expect(router.path(for: .secondary) == [.third])
}

@MainActor
@Test func applyingDeferredRequestIsIdempotent() {
    let router = NavigationRouter<TestScope, TestDestination>(selectedScope: .primary)
    router.presentSheet(.first)
    router.submit(.push(.second, on: .primary))

    #expect(router.applyDeferredRequestIfReady() == .push(.second, on: .primary))
    #expect(router.applyDeferredRequestIfReady() == nil)
    #expect(router.path(for: .primary) == [.second])
}

@MainActor
@Test func presentationHostAcceptsAnArbitraryDestinationBuilder() {
    let node = NavigationPresentationNode(destination: TestDestination.first)

    _ = NavigationPresentationNodeView(node: node) { destination, _ in
        Text(String(describing: destination))
    }
}
