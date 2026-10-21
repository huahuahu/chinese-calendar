#if DEBUG
    @testable import ChineseCalendarUI
    import Foundation
    import NavigationCore
    import SwiftUI
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

        @Test(arguments: debugDestinations)
        func debugRoutesAreAcceptedAtEveryEntryButCannotBecomeRestorableAppState(
            destination: CalendarDestination
        ) throws {
            #expect(!destination.supportsStateRestoration)
            let pathSource = CalendarRouter()
            let navigation = pathSource.navigation.context(for: .years)
            #expect(navigation.push(destination))
            #expect(navigation.path == [destination])

            let stackRootSource = CalendarRouter(yearsPath: [.lunarYear(2024)])
            let stackRoot = stackRootSource.navigation.context(for: .years)
            #expect(stackRoot.setRootDestination(destination))
            #expect(stackRoot.rootDestination == destination)
            #expect(stackRoot.path.isEmpty)

            let modalSource = CalendarRouter()
            #expect(modalSource.navigation.rootPresentation.present(destination))
            #expect(modalSource.sheet?.destination == destination)

            for source in [pathSource, stackRootSource, modalSource] {
                #expect(source.navigation.snapshot.rootDestination == .mainTabs)
                #expect(source.restorableSnapshot == nil)
                let data = try JSONEncoder().encode(source.navigation.snapshot)
                let snapshot = try JSONDecoder().decode(
                    NavigationSnapshot<CalendarTab, CalendarDestination, CalendarAlert>.self, from: data
                )
                let target = CalendarRouter(selectedTab: .history, historyPath: [.emperor("ming-taizu")])
                let before = target.navigation.snapshot
                #expect(!target.restore(snapshot))
                #expect(target.navigation.snapshot == before)
            }
        }

        @Test(arguments: debugDestinations)
        func debugRoutesCanStartCoreLayersButAppRejectsTheirRestoration(destination: CalendarDestination) throws {
            let source = NavigationRouter<CalendarTab, CalendarDestination, CalendarAlert>(
                rootDestination: destination
            )
            let snapshot = source.snapshot
            #expect(snapshot.rootDestination == destination)
            #expect(snapshot.layer.selectedStack == .primary)
            #expect(snapshot.layer.rootDestinations[.primary] == (
                destination.providesNavigationContainer ? nil : destination
            ))
            let data = try JSONEncoder().encode(snapshot)
            let decoded = try JSONDecoder().decode(
                NavigationSnapshot<CalendarTab, CalendarDestination, CalendarAlert>.self, from: data
            )
            let target = CalendarRouter(yearsPath: [.lunarYear(2024)])
            let before = target.navigation.snapshot
            #expect(!target.restore(decoded))
            #expect(target.navigation.snapshot == before)
        }
    }

    extension CalendarDebugSplitStateTests {
        @Test(arguments: CalendarDebugSplitLayout.allCases)
        func storeReplacementKeepsSplitSelectionLayoutAndPath(layout: CalendarDebugSplitLayout) throws {
            let coordinator = CalendarHomeCoordinator()
            coordinator.storeIdentityDidChange("base")
            #expect(coordinator.router.navigation.rootPresentation.present(.debugSplit(layout: layout)))
            let node = try #require(coordinator.router.sheet)
            let presentation = coordinator.router.navigation.presentationContext(for: node)
            let navigation = presentation.context(for: .primary)
            let state = coordinator.debugSplitState(for: navigation)
            #expect(state.selectItem(.first, navigation: navigation))
            let destination = CalendarDestination.debugSplitDetail(item: .first, level: 1)
            #expect(navigation.push(destination))
            state.retainsDetail = true
            state.columnVisibility = .detailOnly
            state.preferredCompactColumn = .detail

            coordinator.storeIdentityDidChange("full")
            let rebuiltNavigation = presentation.context(for: .primary)
            let rebuiltState = coordinator.debugSplitState(for: rebuiltNavigation)
            #expect(rebuiltNavigation === navigation)
            #expect(rebuiltState === state)
            #expect(rebuiltState.item == .first)
            #expect(rebuiltState.category == .first)
            #expect(rebuiltState.retainsDetail)
            #expect(rebuiltState.columnVisibility == .detailOnly)
            #expect(rebuiltState.preferredCompactColumn == .detail)
            #expect(rebuiltNavigation.path == [destination])
        }

        @Test func storeReplacementKeepsMixedTabSplitStatesIndependent() throws {
            let coordinator = CalendarHomeCoordinator()
            coordinator.storeIdentityDidChange("base")
            let id = UUID()
            #expect(coordinator.router.navigation.rootPresentation.present(
                .debugNavigationTabs(id: id), style: .fullScreen, initialStack: .scope(.history),
                rootDestinations: [.scope(.years): .debugNavigation(id: id)]
            ))
            let node = try #require(coordinator.router.fullScreen)
            let presentation = coordinator.router.navigation.presentationContext(for: node)
            let twoColumn = presentation.context(for: .scope(.history))
            let threeColumn = presentation.context(for: .scope(.settings))
            let firstState = coordinator.debugSplitState(for: twoColumn)
            let secondState = coordinator.debugSplitState(for: threeColumn)
            #expect(firstState !== secondState)
            #expect(firstState.selectItem(.first, navigation: twoColumn))
            #expect(secondState.selectItem(.third, navigation: threeColumn))
            #expect(twoColumn.push(.debugSplitDetail(item: .first, level: 1)))
            #expect(threeColumn.push(.debugSplitDetail(item: .third, level: 1)))
            secondState.retainsDetail = true
            firstState.columnVisibility = .detailOnly
            secondState.columnVisibility = .all
            presentation.selectedStack = .scope(.settings)

            coordinator.storeIdentityDidChange("full")
            #expect(coordinator.debugSplitState(for: twoColumn) === firstState)
            #expect(coordinator.debugSplitState(for: threeColumn) === secondState)
            #expect(firstState.item == .first)
            #expect(secondState.item == .third)
            #expect(!firstState.retainsDetail)
            #expect(secondState.retainsDetail)
            #expect(firstState.columnVisibility == .detailOnly)
            #expect(secondState.columnVisibility == .all)
            #expect(twoColumn.path == [.debugSplitDetail(item: .first, level: 1)])
            #expect(threeColumn.path == [.debugSplitDetail(item: .third, level: 1)])
            #expect(presentation.selectedStack == .scope(.settings))
        }

        @Test func dismissalReleasesSplitStateAndSameIDRestorationDoesNotReviveIt() throws {
            let coordinator = CalendarHomeCoordinator()
            #expect(coordinator.router.navigation.rootPresentation.present(.debugSplit(layout: .twoColumn)))
            let original = try #require(coordinator.router.sheet)
            let presentation = coordinator.router.navigation.presentationContext(for: original)
            let navigation = presentation.context(for: .primary)
            let snapshot = coordinator.router.navigation.snapshot
            weak var state = coordinator.debugSplitState(for: navigation)
            #expect(state?.selectItem(.first, navigation: navigation) == true)
            #expect(navigation.push(.debugSplitDetail(item: .first, level: 1)))
            #expect(presentation.dismiss())
            #expect(!navigation.isActive)
            #expect(state != nil)
            #expect(coordinator.debugSplitState(for: navigation) === state)
            #expect(state?.item == .first)

            coordinator.rootPresentationDidDismiss()
            #expect(state == nil)
            weak var inactiveState = coordinator.debugSplitState(for: navigation)
            #expect(inactiveState == nil)

            // 直接恢复 Core 快照重建相同层 ID，验证缓存不按路由 ID 复活旧选择。
            #expect(coordinator.router.navigation.restore(snapshot))
            let reopened = try #require(coordinator.router.sheet)
            let reopenedNavigation = coordinator.router.navigation.context(for: reopened)
            let reopenedState = coordinator.debugSplitState(for: reopenedNavigation)
            #expect(reopened.id == original.id)
            #expect(reopenedNavigation.id == navigation.id)
            #expect(reopenedNavigation !== navigation)
            #expect(!navigation.isActive)
            #expect(reopenedState.item == nil)
            #expect(reopenedState.category == nil)
            #expect(reopenedNavigation.path.isEmpty)
        }
    }

    private extension CalendarDebugSplitStateTests {
        nonisolated static var debugDestinations: [CalendarDestination] {
            [
                .debugSplit(layout: .twoColumn), .debugSplit(layout: .threeColumn),
                .debugSplitDetail(item: .first, level: 1), .debugNavigationTabs(id: UUID())
            ]
        }

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
