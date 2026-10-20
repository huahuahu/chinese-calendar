#if DEBUG
    @testable import ChineseCalendarUI
    import Foundation
    import NavigationCore
    import Testing

    @MainActor
    @Suite("App SplitView 选择与 SDK 单栈")
    struct CalendarDebugSplitStateTests {
        @Test(arguments: CalendarDebugSplitLayout.allCases)
        func detailUsesItsLayerStackAndOnlyNewItemsClearThePath(layout: CalendarDebugSplitLayout) throws {
            let split = try makeSplit(layout: layout)
            let firstPath: [CalendarDestination] = [
                .debugSplitDetail(item: .first, level: 1), .debugSplitDetail(item: .first, level: 2)
            ]
            #expect(split.navigation === split.presentation.context(for: .primary))
            #expect(split.navigation.isActive)
            #expect(split.navigation.rootDestination == nil)
            #expect(split.state.selectItem(.first, navigation: split.navigation))
            #expect(split.navigation.push(firstPath[0]))
            #expect(split.navigation.push(firstPath[1]))
            #expect(split.state.selectItem(.first, navigation: split.navigation))
            #expect(split.state.item == .first)
            #expect(split.navigation.path == firstPath)

            #expect(split.state.selectItem(.third, navigation: split.navigation))
            #expect(split.state.item == .third)
            #expect(split.state.category == .second)
            #expect(split.navigation.path.isEmpty)
            #expect(split.navigation.rootDestination == nil)
            #expect(split.navigation.push(.debugSplitDetail(item: .third, level: 1)))
            #expect(split.navigation.pop())
            #expect(split.navigation.path.isEmpty)
        }

        @Test func changingCategoryClearsDetailWhileRepeatingItKeepsThePath() throws {
            let split = try makeSplit(layout: .threeColumn)
            let destination = CalendarDestination.debugSplitDetail(item: .first, level: 1)
            #expect(split.state.selectItem(.first, navigation: split.navigation))
            #expect(split.navigation.push(destination))
            #expect(split.state.selectCategory(.first, navigation: split.navigation))
            #expect(split.state.item == .first)
            #expect(split.navigation.path == [destination])

            #expect(split.state.selectCategory(.second, navigation: split.navigation))
            #expect(split.state.category == .second)
            #expect(split.state.item == nil)
            #expect(split.navigation.path.isEmpty)
            #expect(split.state.selectItem(.third, navigation: split.navigation))
            #expect(split.navigation.push(.debugSplitDetail(item: .third, level: 1)))
            #expect(split.state.selectCategory(nil, navigation: split.navigation))
            #expect(split.state.category == nil)
            #expect(split.state.item == nil)
            #expect(split.navigation.path.isEmpty)
        }

        @Test func retainedDetailDoesNotMoveTheCategoryBackWhenSelectedAgain() throws {
            let split = try makeSplit(layout: .threeColumn)
            let destination = CalendarDestination.debugSplitDetail(item: .first, level: 1)
            split.state.retainsDetail = true
            #expect(split.state.selectItem(.first, navigation: split.navigation))
            #expect(split.navigation.push(destination))
            #expect(split.state.selectCategory(.second, navigation: split.navigation))
            #expect(split.state.category == .second)
            #expect(split.state.item == .first)
            #expect(split.navigation.path == [destination])

            #expect(split.state.selectCategory(.second, navigation: split.navigation))
            #expect(split.state.selectItem(.first, navigation: split.navigation))
            #expect(split.state.category == .second)
            #expect(split.state.item == .first)
            #expect(split.navigation.path == [destination])
        }

        @Test(arguments: [false, true])
        func clearingItemAlwaysClearsItsPath(retainsDetail: Bool) throws {
            let split = try makeSplit()
            split.state.retainsDetail = retainsDetail
            #expect(split.state.selectItem(.first, navigation: split.navigation))
            #expect(split.navigation.push(.debugSplitDetail(item: .first, level: 1)))
            #expect(split.state.selectItem(nil, navigation: split.navigation))
            #expect(split.state.item == nil)
            #expect(split.navigation.path.isEmpty)
        }
    }

    extension CalendarDebugSplitStateTests {
        @Test func modalTabsAndNestedSplitKeepIndependentSelectionAndPaths() throws {
            let router = CalendarRouter(historyPath: [.emperor("ming-taizu")])
            #expect(router.navigation.rootPresentation.present(
                .debugNavigationTabs(id: UUID()), style: .fullScreen, initialStack: .scope(.history)
            ))
            let tabs = try router.navigation.presentationContext(for: #require(router.fullScreen))
            let twoColumn = tabs.context(for: .scope(.history))
            let threeColumn = tabs.context(for: .scope(.settings))
            let firstState = CalendarDebugSplitState()
            let secondState = CalendarDebugSplitState()
            let firstDestination = CalendarDestination.debugSplitDetail(item: .first, level: 1)
            let secondDestination = CalendarDestination.debugSplitDetail(item: .third, level: 1)
            #expect(twoColumn !== threeColumn)
            #expect(twoColumn !== router.navigation.context(for: .history))
            #expect(firstState.selectItem(.first, navigation: twoColumn))
            #expect(twoColumn.push(firstDestination))
            tabs.selectedStack = .scope(.settings)
            secondState.retainsDetail = true
            #expect(secondState.selectItem(.third, navigation: threeColumn))
            #expect(threeColumn.push(secondDestination))
            #expect(tabs.scoped(to: .scope(.settings)).present(.debugSplit(layout: .twoColumn)))
            let child = try router.navigation.presentationContext(for: #require(tabs.presentedNode))
            let childNavigation = child.context(for: .primary)
            let childState = CalendarDebugSplitState()
            #expect(childNavigation !== twoColumn)
            #expect(childState.selectItem(.second, navigation: childNavigation))
            #expect(childNavigation.push(.debugSplitDetail(item: .second, level: 1)))
            #expect(child.dismiss())

            #expect(firstState.item == .first)
            #expect(secondState.item == .third)
            #expect(!firstState.retainsDetail)
            #expect(secondState.retainsDetail)
            #expect(twoColumn.path == [firstDestination])
            #expect(threeColumn.path == [secondDestination])
            #expect(router.historyPath == [.emperor("ming-taizu")])
        }

        @Test func closedModalRejectsStaleSelectionAndReopensWithIndependentState() throws {
            let split = try makeSplit()
            let original = try #require(split.router.sheet)
            let destination = CalendarDestination.debugSplitDetail(item: .first, level: 1)
            #expect(split.state.selectItem(.first, navigation: split.navigation))
            #expect(split.navigation.push(destination))
            #expect(split.presentation.dismiss())
            #expect(!split.navigation.isActive)
            #expect(!split.state.selectItem(.third, navigation: split.navigation))
            #expect(!split.state.selectCategory(.second, navigation: split.navigation))
            #expect(split.state.item == .first)
            #expect(split.state.category == .first)
            #expect(original.path == [destination])

            split.router.rootPresentationDidDismiss()
            #expect(split.router.navigation.rootPresentation.present(.debugSplit(layout: .twoColumn)))
            let reopened = try #require(split.router.sheet)
            let navigation = split.router.navigation.context(for: reopened)
            let state = CalendarDebugSplitState()
            #expect(reopened.id != original.id)
            #expect(navigation !== split.navigation)
            #expect(state.item == nil)
            #expect(state.category == nil)
            #expect(navigation.path.isEmpty)
            #expect(state.selectItem(.third, navigation: navigation))
            #expect(navigation.push(.debugSplitDetail(item: .third, level: 1)))
            #expect(!split.state.selectItem(nil, navigation: split.navigation))
            #expect(split.state.item == .first)
            #expect(original.path == [destination])
            #expect(state.item == .third)
            #expect(navigation.path == [.debugSplitDetail(item: .third, level: 1)])
        }

        @Test func externalNavigationPreservesSelectionUntilConfirmedAndActuallyDismissed() throws {
            let split = try makeSplit()
            let original = try #require(split.router.sheet)
            let destination = CalendarDestination.debugSplitDetail(item: .first, level: 1)
            #expect(split.state.selectItem(.first, navigation: split.navigation))
            #expect(split.navigation.push(destination))
            let before = split.router.navigation.snapshot
            #expect(split.router
                .openDeepLink(.emperor("ming-taizu"), confirmIfPresented: true) == .awaitingConfirmation)
            let cancelled = try #require(split.presentation.confirmation)
            #expect(!split.state.selectItem(.third, navigation: split.navigation))
            split.presentation.cancelNavigation(id: cancelled.id)
            #expect(split.router.navigation.snapshot == before)
            #expect(split.state.item == .first)
            #expect(split.state.category == .first)
            #expect(split.navigation.path == [destination])

            #expect(split.router
                .openDeepLink(.emperor("ming-taizu"), confirmIfPresented: true) == .awaitingConfirmation)
            try split.presentation.confirmNavigation(id: #require(split.presentation.confirmation).id)
            #expect(split.router.sheet == nil)
            #expect(split.router.isAwaitingPresentationDismissal)
            #expect(split.router.selectedTab == .years)
            #expect(split.router.yearsPath == [.lunarYear(2024)])
            #expect(split.router.historyPath.isEmpty)
            #expect(!split.state.selectItem(.third, navigation: split.navigation))
            #expect(!split.state.selectCategory(.second, navigation: split.navigation))
            #expect(split.state.item == .first)
            #expect(split.state.category == .first)
            #expect(original.path == [destination])
            split.router.rootPresentationDidDismiss()
            #expect(split.router.selectedTab == .history)
            #expect(split.router.historyPath == [.emperor("ming-taizu")])
            #expect(split.router.yearsPath == [.lunarYear(2024)])
        }

        @Test func activeAlertRejectsItemAndCategoryChangesWithoutChangingDetail() throws {
            let split = try makeSplit()
            let destination = CalendarDestination.debugSplitDetail(item: .first, level: 1)
            #expect(split.state.selectItem(.first, navigation: split.navigation))
            #expect(split.navigation.push(destination))
            #expect(split.presentation.presentAlert(.debugNotice(1)))
            #expect(split.router.navigation.hasActiveAlert)
            #expect(!split.state.selectItem(.third, navigation: split.navigation))
            #expect(!split.state.selectItem(nil, navigation: split.navigation))
            #expect(!split.state.selectCategory(.second, navigation: split.navigation))
            #expect(split.state.item == .first)
            #expect(split.state.category == .first)
            #expect(split.navigation.path == [destination])
        }

        @Test func debugRoutesCannotRestoreAndContainersCannotEnterPushPaths() {
            let destinations: [CalendarDestination] = [
                .debugSplit(layout: .twoColumn), .debugSplit(layout: .threeColumn),
                .debugSplitDetail(item: .first, level: 1), .debugNavigationTabs(id: UUID())
            ]
            for destination in destinations {
                let source = CalendarRouter()
                let navigation = source.navigation.context(for: .years)
                #expect(!destination.supportsStateRestoration)
                if destination.providesNavigationContainer {
                    #expect(!navigation.push(destination))
                    #expect(navigation.path.isEmpty)
                    #expect(source.navigation.rootPresentation.present(destination))
                } else {
                    #expect(navigation.push(destination))
                }
                #expect(source.restorableSnapshot == nil)
                let target = CalendarRouter()
                let before = target.navigation.snapshot
                #expect(!target.restore(source.navigation.snapshot))
                #expect(target.navigation.snapshot == before)
            }
        }
    }

    private extension CalendarDebugSplitStateTests {
        struct SplitSession {
            let router: CalendarRouter
            let presentation: CalendarPresentationContext
            let navigation: CalendarNavigationContext
            let state: CalendarDebugSplitState
        }

        func makeSplit(layout: CalendarDebugSplitLayout = .twoColumn) throws -> SplitSession {
            let router = CalendarRouter(yearsPath: [.lunarYear(2024)])
            #expect(router.navigation.rootPresentation.present(.debugSplit(layout: layout)))
            let presentation = try router.navigation.presentationContext(for: #require(router.sheet))
            return SplitSession(
                router: router, presentation: presentation,
                navigation: presentation.context(for: .primary), state: CalendarDebugSplitState()
            )
        }
    }
#endif
