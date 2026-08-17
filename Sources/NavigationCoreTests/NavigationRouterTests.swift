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
@Test func presentationHostAcceptsAnArbitraryDestinationBuilder() {
    let node = NavigationPresentationNode(destination: TestDestination.first)

    _ = NavigationPresentationNodeView(node: node) { destination, _ in
        Text(String(describing: destination))
    }
}
