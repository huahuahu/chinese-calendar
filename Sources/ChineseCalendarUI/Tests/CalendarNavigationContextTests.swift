@testable import ChineseCalendarUI
import Foundation
import NavigationCore
import Testing

@MainActor
@Suite("App 使用局部导航框架")
struct CalendarNavigationContextTests {
    @Test(arguments: CalendarTab.allCases)
    func rootAndLocalOperationsUseTheSamePathForEveryTab(tab: CalendarTab) {
        let router = CalendarRouter()
        let context = router.navigation.context(for: tab)
        router.push(.lunarYear(2025), on: tab)
        #expect(router.selectedTab == tab)
        #expect(context.path == [.lunarYear(2025)])
        #expect(context.push(.lunarYear(2026)))
        #expect(router.path(for: tab) == [.lunarYear(2025), .lunarYear(2026)])
        #expect(router.currentDestination(on: tab) == .lunarYear(2026))
        router.setPath([], for: tab)
        #expect(context.path.isEmpty)
        #expect(router.currentDestination(on: tab) == router.navigation.rootDestination(for: tab))
    }

    @Test func historyModalPushAndNestedPresentationPreserveTabNavigation() throws {
        let router = CalendarRouter(selectedTab: .history, historyPath: [.dynasty(orthodoxPeriodID: "ming")])
        let history = router.navigation.context(for: .history)
        #expect(router.navigation.rootPresentation.scoped(to: .scope(.history))
            .present(.dynasty(orthodoxPeriodID: "qing")))
        let dynasty = try #require(router.sheet)
        let modal = router.navigation.context(for: dynasty)
        #expect(modal.push(.emperorList(dynastyID: "qing")))
        #expect(router.navigation.presentationContext(for: dynasty).present(.emperor("qing-shizu"), style: .fullScreen))
        let child = try router.navigation.presentationContext(for: #require(dynasty.fullScreen))
        #expect(child.dismiss())
        #expect(dynasty.path == [.emperorList(dynastyID: "qing")])
        #expect(history.path == [.dynasty(orthodoxPeriodID: "ming")])
        #expect(router.sheet === dynasty)
    }

    @Test func appDeepLinkCancelAndApprovalUseTheCoreTransaction() throws {
        let coordinator = CalendarHomeCoordinator()
        coordinator.router.navigation.rootPresentation.scoped(to: .scope(.years)).present(.lunarYear(2025))
        let before = coordinator.router.navigation.snapshot
        coordinator.openDeepLink(.emperor("ming-taizu"))
        let first = try #require(coordinator.router.navigation.pendingConfirmation)
        coordinator.router.navigation.cancelConfirmation(id: first.id)
        #expect(coordinator.router.navigation.snapshot == before)
        coordinator.openDeepLink(.emperor("ming-taizu"))
        try coordinator.router.navigation
            .confirmNavigation(id: #require(coordinator.router.navigation.pendingConfirmation).id)
        #expect(coordinator.router.historyPath.isEmpty)
        coordinator.rootPresentationDidDismiss()
        #expect(coordinator.router.historyPath == [.emperor("ming-taizu")])
        #expect(coordinator.router.selectedTab == .history)
    }

    @Test func persistentAddressesRoundTripButTemporarySessionsAreRejected() throws {
        let router = CalendarRouter(selectedTab: .history, historyPath: [.dynasty(orthodoxPeriodID: "ming")])
        router.navigation.rootPresentation.scoped(to: .scope(.history)).present(.emperorList(dynastyID: "ming"))
        let data = try JSONEncoder().encode(#require(router.restorableSnapshot))
        let decoded = try JSONDecoder().decode(
            NavigationSnapshot<CalendarTab, CalendarDestination, CalendarAlert>.self,
            from: data
        )
        let restored = CalendarRouter()
        #expect(restored.restore(decoded))
        #expect(restored.navigation.snapshot == decoded)

        let temporary = CalendarRouter(yearsPath: [.yearPicker(sessionID: UUID())])
        #expect(temporary.restorableSnapshot == nil)
        #expect(!CalendarRouter().restore(temporary.navigation.snapshot))
        temporary.yearsPath = []
        temporary.presentSheet(.downloadDetails)
        #expect(temporary.restorableSnapshot == nil)
        #expect(!CalendarRouter().restore(temporary.navigation.snapshot))
    }

    @Test func appRootAndTabRootsAreExplicitAndRestoreRequiresEveryTab() {
        let router = CalendarRouter()
        #expect(router.navigation.rootPresentation.destination == .mainTabs)
        #expect(router.navigation.rootDestinations == [
            .years: .calendarHome, .history: .historyHome, .settings: .settings
        ])
        let before = router.navigation.snapshot
        #expect(!router.restore(.init(rootDestination: .mainTabs, layer: .init(selectedStack: .scope(.years)))))
        #expect(router.navigation.snapshot == before)
    }

    @Test(arguments: [CalendarDestination.mainTabs, .calendarHome, .historyHome, .settings])
    func navigationStateAcceptsAppDestinationsWithoutEntryAllowlist(destination: CalendarDestination) throws {
        let router = CalendarRouter()
        let years = router.navigation.context(for: .years)
        #expect(years.push(destination))
        #expect(years.path == [destination])
        let accepted = destination == .mainTabs
            ? router.navigation.rootPresentation.presentMainTabs()
            : router.navigation.rootPresentation.present(destination)
        #expect(accepted)
        let node = try #require(router.navigation.presentedNode)
        #expect(node.destination == destination)
        #expect(router.navigation.rootPresentation.destination == .mainTabs)
        #expect(years.path == [destination])
    }

    @Test func mainTabsModalAndItsChildKeepRootSelectionsAndEveryTabPathIndependent() throws {
        let router = CalendarRouter(
            selectedTab: .history, yearsPath: [.lunarYear(2025)],
            historyPath: [.dynasty(orthodoxPeriodID: "ming")]
        )
        router.setPath([.calendarHome], for: .settings)
        let rootPaths = router.navigation.snapshot.layer.paths
        #expect(router.navigation.rootPresentation.presentMainTabs(
            selectedTab: .settings, paths: [.scope(.years): [.lunarYear(2026)]]
        ))
        let node = try #require(router.sheet)
        let modal = router.navigation.presentationContext(for: node)
        #expect(modal.destination == .mainTabs)
        #expect(modal.selectedStack == .scope(.settings))
        #expect(modal.context(for: .scope(.settings)).rootDestination == .settings)
        #expect(modal.context(for: .scope(.history)).push(.emperor("qing-shizu")))
        #expect(modal.context(for: .scope(.settings)).push(.historyHome))
        modal.selectedStack = .scope(.years)
        #expect(modal.scoped(to: .scope(.years)).presentMainTabs(style: .fullScreen, selectedTab: .history))
        let childNode = try #require(node.fullScreen)
        let child = router.navigation.presentationContext(for: childNode)
        #expect(child.context(for: .scope(.history)).push(.dynasty(orthodoxPeriodID: "qing")))
        #expect(child.selectedStack == .scope(.history))
        #expect(modal.selectedStack == .scope(.years))
        #expect(router.selectedTab == .history)
        #expect(router.navigation.snapshot.layer.paths == rootPaths)
        #expect(modal.context(for: .scope(.years)).path == [.lunarYear(2026)])
        #expect(modal.context(for: .scope(.history)).path == [.emperor("qing-shizu")])
        #expect(modal.context(for: .scope(.settings)).path == [.historyHome])
        #expect(child.context(for: .scope(.years)).path.isEmpty)
        #expect(child.context(for: .scope(.settings)).path.isEmpty)

        let encoded = try JSONEncoder().encode(#require(router.restorableSnapshot))
        let saved = try JSONDecoder().decode(
            NavigationSnapshot<CalendarTab, CalendarDestination, CalendarAlert>.self, from: encoded
        )
        let restored = CalendarRouter()
        #expect(restored.restore(saved))
        #expect(restored.navigation.snapshot == saved)
        let restoredModal = try restored.navigation.presentationContext(for: #require(restored.sheet))
        #expect(restoredModal.selectedStack == .scope(.years))
        #expect(restoredModal.context(for: .scope(.settings)).path == [.historyHome])
        #expect(restored.selectedTab == .history)
        #expect(restored.navigation.snapshot.layer.paths == rootPaths)
        #expect(child.dismiss())
        #expect(!child.isActive)
        #expect(modal.isActive)
        #expect(modal.context(for: .scope(.history)).path == [.emperor("qing-shizu")])
        #expect(router.navigation.snapshot.layer.paths == rootPaths)
    }

    @Test func invalidNestedMainTabsCannotBeSavedOrRestored() {
        typealias Layer = NavigationLayerSnapshot<CalendarTab, CalendarDestination, CalendarAlert>
        typealias Snapshot = NavigationSnapshot<CalendarTab, CalendarDestination, CalendarAlert>
        let invalidLayers: [Layer] = [
            .init(selectedStack: .scope(.years)),
            .init(
                selectedStack: .scope(.years),
                rootDestinations: [
                    .scope(.years): .calendarHome,
                    .scope(.history): .historyHome
                ]
            ),
            .init(rootDestinations: CalendarRouter.mainTabRoots),
            .init(
                selectedStack: .scope(.years), rootDestinations: CalendarRouter.mainTabRoots,
                paths: [.primary: [.lunarYear(2025)]]
            )
        ]
        let router = CalendarRouter(selectedTab: .history, historyPath: [.emperor("ming-taizu")])
        let before = router.navigation.snapshot
        for layer in invalidLayers {
            let snapshot = Snapshot(rootDestination: .mainTabs, layer: Layer(
                selectedStack: .scope(.years), rootDestinations: CalendarRouter.mainTabRoots,
                presentation: .node(id: UUID(), destination: .lunarYear(2026), style: .sheet, layer: Layer(
                    rootDestinations: [.primary: .lunarYear(2026)],
                    presentation: .node(id: UUID(), destination: .mainTabs, style: .fullScreen, layer: layer)
                ))
            ))
            for invalidSnapshot in [Snapshot(rootDestination: .mainTabs, layer: layer), snapshot] {
                #expect(!router.restore(invalidSnapshot))
                #expect(router.navigation.snapshot == before)
                let source = CalendarRouter()
                #expect(source.navigation.restore(invalidSnapshot))
                #expect(source.restorableSnapshot == nil)
            }
        }
    }

    #if DEBUG
        @Test func backgroundPresentationDoesNotLeaveADebugSessionBehind() {
            let coordinator = CalendarHomeCoordinator()
            let presentation = coordinator.router.navigation.rootPresentation.scoped(to: .scope(.settings))
            coordinator.presentDownloadPreview(presentation: presentation)
            #expect(coordinator.downloadPreviewSessions.isEmpty)
            #expect(coordinator.router.presentations.isEmpty)

            coordinator.router.selectedTab = .settings
            coordinator.presentDownloadPreview(presentation: presentation)
            #expect(coordinator.downloadPreviewSessions.count == 1)
            #expect(coordinator.router.presentations.count == 1)
        }

        @Test func debugRoutesCannotBecomePersistentNavigationState() throws {
            let source = CalendarRouter(selectedTab: .settings)
            let route = CalendarDestination.debugNavigation(id: UUID())
            #expect(source.navigation.context(for: .settings).push(route))
            #expect(source.restorableSnapshot == nil)

            let data = try JSONEncoder().encode(source.navigation.snapshot)
            let decoded = try JSONDecoder().decode(
                NavigationSnapshot<CalendarTab, CalendarDestination, CalendarAlert>.self, from: data
            )
            let target = CalendarRouter()
            let original = target.navigation.snapshot
            #expect(!target.restore(decoded))
            #expect(target.navigation.snapshot == original)
        }
    #endif
}

extension CalendarNavigationContextTests {
    @Test func replacedRootAndModalTabRootsRemainRestorable() throws {
        let router = CalendarRouter(yearsPath: [.lunarYear(2025)], historyPath: [.emperor("ming-taizu")])
        let rootHistory = router.navigation.context(for: .history)
        #expect(rootHistory.setRootDestination(.dynasty(orthodoxPeriodID: "ming")))
        #expect(rootHistory.path.isEmpty)
        #expect(rootHistory.push(.emperorList(dynastyID: "ming")))
        #expect(router.navigation.rootPresentation.presentMainTabs(
            selectedTab: .history, paths: [.scope(.history): [.emperor("qing-shizu")]]
        ))
        let modal = try router.navigation.presentationContext(for: #require(router.sheet))
        let modalHistory = modal.context(for: .scope(.history))
        #expect(modalHistory.setRootDestination(.dynasty(orthodoxPeriodID: "qing")))
        #expect(modalHistory.path.isEmpty)
        #expect(modalHistory.push(.emperorList(dynastyID: "qing")))
        #expect(rootHistory.rootDestination == .dynasty(orthodoxPeriodID: "ming"))
        #expect(rootHistory.path == [.emperorList(dynastyID: "ming")])
        let snapshot = try #require(router.restorableSnapshot)
        let encoded = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(
            NavigationSnapshot<CalendarTab, CalendarDestination, CalendarAlert>.self, from: encoded
        )
        let restored = CalendarRouter()
        #expect(restored.restore(decoded))
        #expect(restored.restorableSnapshot == snapshot)
        #expect(restored.navigation.context(for: .history).rootDestination == .dynasty(orthodoxPeriodID: "ming"))
        #expect(restored.historyPath == [.emperorList(dynastyID: "ming")])
        #expect(restored.yearsPath == [.lunarYear(2025)])
        #expect(restored.selectedTab == .years)
        let restoredModal = try restored.navigation.presentationContext(for: #require(restored.sheet))
        #expect(restoredModal.context(for: .scope(.history)).rootDestination == .dynasty(orthodoxPeriodID: "qing"))
        #expect(restoredModal.context(for: .scope(.history)).path == [.emperorList(dynastyID: "qing")])
        #expect(restoredModal.selectedStack == .scope(.history))
        #expect(restored.navigation.rootPresentation.destination == .mainTabs)
        #expect(restoredModal.destination == .mainTabs)
    }
}
