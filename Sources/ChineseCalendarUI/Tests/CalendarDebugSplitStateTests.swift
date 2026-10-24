#if DEBUG
    @testable import ChineseCalendarUI
    import Foundation
    import NavigationCore
    import SwiftUI
    import Testing

    @MainActor
    @Suite("App SplitView 选择与 SDK 单栈", .serialized)
    struct CalendarDebugSplitStateTests {
        @Test(arguments: CalendarDebugSplitLayout.allCases)
        func detailUsesItsLayerStackAndOnlyNewItemsClearThePath(layout: CalendarDebugSplitLayout) {
            let split = makeSplit(layout: layout)
            let firstPath: [CalendarDestination] = [
                .debugSplitDetail(item: .first, level: 1), .debugSplitDetail(item: .first, level: 2)
            ]
            #expect(split.navigation === split.presentation.context(for: .primary))
            #expect(split.navigation.rootDestination == .debugSplitEmpty)
            #expect(split.state.selectItem(.first))
            #expect(split.navigation.push(firstPath[0]) == .applied)
            #expect(split.navigation.push(firstPath[1]) == .applied)
            #expect(split.state.selectItem(.first))
            #expect(split.state.item == .first)
            #expect(split.navigation.path == firstPath)

            #expect(split.state.selectItem(.third))
            #expect(split.state.item == .third)
            #expect(split.state.category == .second)
            #expect(split.navigation.path.isEmpty)
            #expect(split.navigation.rootDestination == .debugSplitDetail(item: .third, level: 0))
            #expect(split.navigation.push(.debugSplitDetail(item: .third, level: 1)) == .applied)
            #expect(split.navigation.pop() == .applied)
            #expect(split.navigation.path.isEmpty)
        }

        @Test func changingCategoryClearsDetailWhileRepeatingItKeepsThePath() {
            let split = makeSplit(layout: .threeColumn)
            let destination = CalendarDestination.debugSplitDetail(item: .first, level: 1)
            #expect(split.state.selectItem(.first))
            #expect(split.navigation.push(destination) == .applied)
            #expect(split.state.selectCategory(.first))
            #expect(split.state.item == .first)
            #expect(split.navigation.path == [destination])

            #expect(split.state.selectCategory(.second))
            #expect(split.state.category == .second)
            #expect(split.state.item == nil)
            #expect(split.navigation.path.isEmpty)
            #expect(split.state.selectItem(.third))
            #expect(split.navigation.push(.debugSplitDetail(item: .third, level: 1)) == .applied)
            #expect(split.state.selectCategory(nil))
            #expect(split.state.category == nil)
            #expect(split.state.item == nil)
            #expect(split.navigation.path.isEmpty)
        }

        @Test func retainedDetailDoesNotMoveTheCategoryBackWhenSelectedAgain() {
            let split = makeSplit(layout: .threeColumn)
            let destination = CalendarDestination.debugSplitDetail(item: .first, level: 1)
            split.state.retainsDetail = true
            #expect(split.state.selectItem(.first))
            #expect(split.navigation.push(destination) == .applied)
            #expect(split.state.selectCategory(.second))
            #expect(split.state.category == .second)
            #expect(split.state.item == .first)
            #expect(split.navigation.path == [destination])

            #expect(split.state.selectCategory(.second))
            #expect(split.state.selectItem(.first))
            #expect(split.state.category == .second)
            #expect(split.state.item == .first)
            #expect(split.navigation.path == [destination])
        }

        @Test(arguments: [false, true])
        func clearingItemAlwaysClearsItsPath(retainsDetail: Bool) {
            let split = makeSplit()
            split.state.retainsDetail = retainsDetail
            #expect(split.state.selectItem(.first))
            #expect(split.navigation.push(.debugSplitDetail(item: .first, level: 1)) == .applied)
            #expect(split.state.selectItem(nil))
            #expect(split.state.item == nil)
            #expect(split.navigation.path.isEmpty)
        }
    }

    extension CalendarDebugSplitStateTests {
        @Test func namedStacksKeepIndependentSelectionAndLayout() {
            let destination = CalendarDestination.debugNavigationTabs(id: UUID())
            let router = NavigationTestHost.Router(
                rootDestination: destination, initialStack: .scope(.history), rootDestinations: roots(for: destination)
            )
            let presentation = router.rootPresentation
            let firstNavigation = presentation.context(for: .scope(.history))
            let secondNavigation = presentation.context(for: .scope(.settings))
            let first = CalendarDebugSplitState(navigation: firstNavigation)
            let second = CalendarDebugSplitState(navigation: secondNavigation)
            #expect(firstNavigation !== secondNavigation)
            #expect(first.selectItem(.first))
            #expect(firstNavigation.push(.debugSplitDetail(item: .first, level: 1)) == .applied)
            presentation.selectedStack = .scope(.settings)
            #expect(second.selectItem(.third))
            #expect(secondNavigation.push(.debugSplitDetail(item: .third, level: 1)) == .applied)
            second.retainsDetail = true
            first.columnVisibility = .detailOnly
            #expect(first.item == .first)
            #expect(second.item == .third)
            #expect(!first.retainsDetail)
            #expect(second.retainsDetail)
            #expect(first.columnVisibility == .detailOnly)
            #expect(second.columnVisibility == .all)
            #expect(firstNavigation.path == [.debugSplitDetail(item: .first, level: 1)])
            #expect(secondNavigation.path == [.debugSplitDetail(item: .third, level: 1)])
        }

        @Test func closedModalRejectsStaleSelectionAndReopensWithIndependentState() async throws {
            let router = NavigationTestHost.Router(rootDestination: .settings)
            let root = router.rootPresentation
            let host = try await NavigationTestHost.show(router: router)
            defer { host.removeFromWindow() }
            let destination = CalendarDestination.debugSplit(layout: .twoColumn)
            var finishCount = 0
            let submission = root.present(destination, rootDestinations: roots(for: destination)) { finishCount += 1 }
            #expect(submission.result == .applied)
            let context = try await host.context(for: destination)
            let navigation = context.context(for: .primary)
            let state = CalendarDebugSplitState(navigation: navigation)
            #expect(state.selectItem(.first))
            #expect(navigation.push(.debugSplitDetail(item: .first, level: 1)) == .applied)
            _ = try await host.waitForPresentation()
            #expect(try #require(submission.handle).dismiss().isAccepted)
            #expect(!state.selectItem(.third))
            #expect(!state.selectCategory(.second))
            #expect(state.category == .first)
            try await host.waitUntil { finishCount == 1 }

            #expect(root.present(destination, rootDestinations: roots(for: destination)).result == .applied)
            let reopened = try await host.context(for: destination, differentFrom: context)
            let reopenedNavigation = reopened.context(for: .primary)
            let reopenedState = CalendarDebugSplitState(navigation: reopenedNavigation)
            #expect(reopenedNavigation !== navigation)
            #expect(reopenedState.item == nil)
            #expect(reopenedState.category == nil)
            #expect(reopenedNavigation.path.isEmpty)
            #expect(reopenedState.selectItem(.third))
            #expect(!state.selectItem(nil))
            #expect(reopenedState.item == .third)
            await host.close()
        }

        @Test func activeAlertRejectsItemAndCategoryChangesWithoutChangingDetail() async throws {
            let split = makeSplit()
            let host = try await NavigationTestHost.show(router: split.router)
            defer { host.removeFromWindow() }
            let destination = CalendarDestination.debugSplitDetail(item: .first, level: 1)
            #expect(split.state.selectItem(.first))
            #expect(split.navigation.push(destination) == .applied)
            #expect(split.presentation.presentAlert(.debugNotice(1)).result == .applied)
            _ = try await host.waitForAlert()
            #expect(!split.state.selectItem(.third))
            #expect(!split.state.selectItem(nil))
            #expect(!split.state.selectCategory(.second))
            #expect(split.state.item == .first)
            #expect(split.state.category == .first)
            #expect(split.navigation.path == [destination])
            await host.close()
        }

        @Test(arguments: CalendarDebugSplitLayout.allCases)
        func newSplitStateReadsDetailRootAndKeepsTheExistingPath(layout: CalendarDebugSplitLayout) {
            let split = makeSplit(layout: layout)
            #expect(split.state.selectItem(.third))
            let path: [CalendarDestination] = [.debugSplitDetail(item: .third, level: 1)]
            #expect(split.navigation.setPath(path) == .applied)
            let state = CalendarDebugSplitState(navigation: split.navigation)
            #expect(state.item == .third)
            #expect(split.navigation.rootDestination == .debugSplitDetail(item: .third, level: 0))
            #expect(split.navigation.path == path)
            #expect(state.category == nil)
            #expect(state.preferredCompactColumn == .sidebar)
            #expect(state.selectItem(.third))
            #expect(split.navigation.path == path)
            #expect(state.selectItem(nil))
            #expect(split.navigation.rootDestination == .debugSplitEmpty)
            #expect(split.navigation.path.isEmpty)
            #expect(split.presentation.selectedStack == .primary)
            #expect(split.presentation.setSelectedStack(.scope(.years)) == .rejected(.undeclaredStack))
            #expect(split.navigation === split.presentation.context(for: .primary))
        }

        @Test(arguments: debugDestinations)
        func debugRoutesAreAcceptedAtEveryEntry(destination: CalendarDestination) async throws {
            let pathSource = CalendarRouter()
            let navigation = pathSource.navigation.rootPresentation.context(for: .scope(.years))
            #expect(navigation.push(destination) == .applied)
            #expect(navigation.path == [destination])
            let rootSource = CalendarRouter(yearsPath: [.lunarYear(2024)])
            let rootNavigation = rootSource.navigation.rootPresentation.context(for: .scope(.years))
            #expect(rootNavigation.setRootDestination(destination) == .applied)
            #expect(rootNavigation.rootDestination == destination)
            #expect(rootNavigation.path.isEmpty)

            let modalSource = CalendarRouter()
            let host = try await NavigationTestHost.show(router: modalSource.navigation)
            defer { host.removeFromWindow() }
            #expect(modalSource.navigation.rootPresentation.present(
                destination, initialStack: initialStack(for: destination), rootDestinations: roots(for: destination)
            ).result == .applied)
            let modal = try await host.context(for: destination)
            #expect(host.contexts[destination.id] === modal)
            #expect(modal.selectedStack == initialStack(for: destination))
            let expectedRoots = destination
                .providesNavigationContainer ? roots(for: destination) : [.primary: destination]
            for (stack, expectedRoot) in expectedRoots {
                #expect(modal.context(for: stack).rootDestination == expectedRoot)
                #expect(modal.context(for: stack).path.isEmpty)
            }
            for (stack, expectedRoot) in CalendarRouter.mainTabRoots {
                #expect(modalSource.navigation.rootPresentation.context(for: stack).rootDestination == expectedRoot)
            }
            await host.close()
        }

        @Test(arguments: debugDestinations)
        func debugRoutesCanStartCoreLayers(destination: CalendarDestination) {
            let source = NavigationTestHost.Router(
                rootDestination: destination, initialStack: initialStack(for: destination),
                rootDestinations: roots(for: destination)
            )
            #expect(source.rootPresentation.context(for: initialStack(for: destination)).setPath([]) == .applied)
            #expect(source.rootPresentation.selectedStack == initialStack(for: destination))
            let expectedRoots = destination
                .providesNavigationContainer ? roots(for: destination) : [.primary: destination]
            for (stack, root) in expectedRoots {
                let navigation = source.rootPresentation.context(for: stack)
                #expect(navigation.rootDestination == root)
                #expect(navigation.path.isEmpty)
            }
        }
    }

    private extension CalendarDebugSplitStateTests {
        nonisolated static var debugDestinations: [CalendarDestination] {
            [
                .debugSplit(layout: .twoColumn), .debugSplit(layout: .threeColumn),
                .debugSplitEmpty, .debugSplitDetail(item: .first, level: 1),
                .debugNavigationTabs(id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)))
            ]
        }

        func roots(for destination: CalendarDestination) -> [NavigationStackID<CalendarTab>: CalendarDestination] {
            switch destination {
            case let .debugNavigationTabs(id):
                [
                    .scope(.years): .debugNavigation(id: id),
                    .scope(.history): .debugSplitEmpty, .scope(.settings): .debugSplitEmpty
                ]
            case .debugSplit: [.primary: .debugSplitEmpty]
            default: [:]
            }
        }

        func initialStack(for destination: CalendarDestination) -> NavigationStackID<CalendarTab> {
            if case .debugNavigationTabs = destination { return .scope(.years) }
            return .primary
        }

        struct SplitSession {
            let router: NavigationTestHost.Router
            let presentation: CalendarPresentationContext
            let navigation: CalendarNavigationContext
            let state: CalendarDebugSplitState
        }

        func makeSplit(layout: CalendarDebugSplitLayout = .twoColumn) -> SplitSession {
            let router = NavigationTestHost.Router(
                rootDestination: .debugSplit(layout: layout), rootDestinations: [.primary: .debugSplitEmpty]
            )
            let presentation = router.rootPresentation
            let navigation = presentation.context(for: .primary)
            return SplitSession(
                router: router, presentation: presentation, navigation: navigation,
                state: CalendarDebugSplitState(navigation: navigation)
            )
        }
    }
#endif
