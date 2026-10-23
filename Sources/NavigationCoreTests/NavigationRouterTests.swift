@testable import NavigationCore
import Testing

private enum TestScope: NavigationScope {
    case primary
    case secondary
}

private enum TestDestination: NavigationDestination {
    case root
    var providesNavigationContainer: Bool {
        self == .root
    }

    case first
    case second
    case third
}

@MainActor
@Test func scopePathsAreIndependent() {
    let router = NavigationRouter<TestScope, TestDestination, NoNavigationAlert>(
        rootDestination: .root,
        selectedScope: .primary, rootDestinations: [.primary: .first, .secondary: .second]
    )

    router.push(.first, on: .primary)
    router.push(.second, on: .secondary)

    #expect(router.path(for: .primary) == [.first])
    #expect(router.path(for: .secondary) == [.second])
    #expect(router.selectedScope == .secondary)
}

@MainActor
@Test func settingRootClearsOnlyItsScopePath() {
    let router = NavigationRouter<TestScope, TestDestination, NoNavigationAlert>(
        rootDestination: .root, selectedScope: .primary, rootDestinations: [.primary: .first, .secondary: .second],
        paths: [.primary: [.first], .secondary: [.second]]
    )

    router.setRootDestination(.third, for: .primary)

    #expect(router.rootDestination(for: .primary) == .third)
    #expect(router.path(for: .primary).isEmpty)
    #expect(router.path(for: .secondary) == [.second])
}

@MainActor
@Test func rootPresentationsCreateIndependentNodes() {
    let sheetRouter = NavigationRouter<TestScope, TestDestination, NoNavigationAlert>(
        rootDestination: .root,
        selectedScope: .primary, rootDestinations: [.primary: .first, .secondary: .second]
    )
    let fullScreenRouter = NavigationRouter<TestScope, TestDestination, NoNavigationAlert>(
        rootDestination: .root,
        selectedScope: .primary, rootDestinations: [.primary: .first, .secondary: .second]
    )

    sheetRouter.presentSheet(.first)
    sheetRouter.frontmostPresentationNode?.lifetime.claimHost()
    fullScreenRouter.presentFullScreen(.second)
    fullScreenRouter.frontmostPresentationNode?.lifetime.claimHost()

    #expect(sheetRouter.sheet?.destination == .first)
    #expect(sheetRouter.sheet?.path.isEmpty == true)
    #expect(fullScreenRouter.fullScreen?.destination == .second)
    #expect(fullScreenRouter.fullScreen?.path.isEmpty == true)
}

@MainActor
@Test func presentationNestsAtFrontmostNode() throws {
    let router = NavigationRouter<TestScope, TestDestination, NoNavigationAlert>(
        rootDestination: .root,
        selectedScope: .primary, rootDestinations: [.primary: .first, .secondary: .second]
    )
    router.presentSheet(.first)
    let parent = try #require(router.sheet)
    parent.lifetime.claimHost()

    router.presentFullScreen(.second)
    router.frontmostPresentationNode?.lifetime.claimHost()
    router.presentSheet(.third)
    router.frontmostPresentationNode?.lifetime.claimHost()

    #expect(router.fullScreen == nil)
    #expect(parent.fullScreen?.destination == .second)
    #expect(parent.fullScreen?.sheet?.destination == .third)
}

@MainActor
@Test func presentedPushDoesNotChangeScopePath() throws {
    let router = NavigationRouter<TestScope, TestDestination, NoNavigationAlert>(
        rootDestination: .root,
        selectedScope: .primary, rootDestinations: [.primary: .first, .secondary: .second]
    )
    router.presentSheet(.first)
    router.frontmostPresentationNode?.lifetime.claimHost()

    let sheet = try #require(router.sheet)
    sheet.lifetime.claimHost()
    router.context(for: sheet).push(.second)

    #expect(sheet.path == [.second])
    #expect(router.path(for: .primary).isEmpty)
}

@MainActor
@Test func dismissingChildReturnsToParentNode() throws {
    let router = NavigationRouter<TestScope, TestDestination, NoNavigationAlert>(
        rootDestination: .root,
        selectedScope: .primary, rootDestinations: [.primary: .first, .secondary: .second]
    )
    router.presentSheet(.first)
    let parent = try #require(router.sheet)
    parent.lifetime.claimHost()
    router.presentationContext(for: parent).present(.second)

    try router.dismissPresentation(id: #require(parent.sheet).id)

    #expect(router.sheet === parent)
    #expect(parent.sheet == nil)
}

@MainActor
@Test func navigationRequestCasesUpdateTheirTargetScope() {
    let router = NavigationRouter<TestScope, TestDestination, NoNavigationAlert>(
        rootDestination: .root, selectedScope: .primary,
        rootDestinations: [.primary: .first, .secondary: .first],
        paths: [.secondary: [.second]]
    )

    #expect(router.submit(.selectScope(.secondary)) == .applied)
    #expect(router.selectedScope == .secondary)

    #expect(router.submit(.setRoot(.third, on: .secondary)) == .applied)
    #expect(router.selectedScope == .secondary)
    #expect(router.rootDestination(for: .secondary) == .third)
    #expect(router.path(for: .secondary).isEmpty)

    #expect(router.submit(.replacePath([.first, .second], on: .scope(.primary))) == .applied)
    #expect(router.selectedScope == .primary)
    #expect(router.path(for: .primary) == [.first, .second])

    #expect(router.submit(.push(.third, on: .secondary)) == .applied)
    #expect(router.selectedScope == .secondary)
    #expect(router.path(for: .secondary) == [.third])
}

@MainActor
@Test func requestDismissesPresentationTreeAndWaitsForDismissalCompletion() throws {
    let router = NavigationRouter<TestScope, TestDestination, NoNavigationAlert>(
        rootDestination: .root, selectedScope: .primary,
        rootDestinations: [.primary: .first]
    )
    router.presentSheet(.second)
    let sheet = try #require(router.sheet)
    sheet.lifetime.claimHost()
    router.presentationContext(for: sheet).present(.third, style: .fullScreen)

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
    let router = NavigationRouter<TestScope, TestDestination, NoNavigationAlert>(
        rootDestination: .root,
        selectedScope: .primary, rootDestinations: [.primary: .first, .secondary: .second]
    )
    router.presentFullScreen(.first)
    router.frontmostPresentationNode?.lifetime.claimHost()

    #expect(router.submit(.push(.second, on: .scope(.primary))) == .deferredUntilPresentationDismisses)
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
    let router = NavigationRouter<TestScope, TestDestination, NoNavigationAlert>(
        rootDestination: .root,
        selectedScope: .primary, rootDestinations: [.primary: .first, .secondary: .second]
    )
    router.presentSheet(.first)
    router.frontmostPresentationNode?.lifetime.claimHost()
    router.submit(.push(.second, on: .scope(.primary)))

    #expect(router.applyDeferredRequestIfReady() == .push(.second, on: .scope(.primary)))
    #expect(router.applyDeferredRequestIfReady() == nil)
    #expect(router.path(for: .primary) == [.second])
}
