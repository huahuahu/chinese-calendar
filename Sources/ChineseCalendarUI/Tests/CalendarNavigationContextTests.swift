@testable import ChineseCalendarUI
import Foundation
import NavigationCore
import Testing

@MainActor
@Suite("App 使用局部导航框架")
struct CalendarNavigationContextTests {
    @Test func rootSelectionProjectsTheCurrentTabDestination() {
        let router = CalendarRouter(selectedTab: .history, historyPath: [.dynasty(orthodoxPeriodID: "ming")])
        #expect(router.selectedTab == .history)
        #expect(router.selectedDestination == .dynasty(orthodoxPeriodID: "ming"))
        router.selectedTab = nil
        #expect(router.selectedTab == .history)
        #expect(router.selectedDestination == .dynasty(orthodoxPeriodID: "ming"))
        router.selectedTab = .settings
        #expect(router.selectedTab == .settings)
        #expect(router.selectedDestination == .settings)
    }

    @Test func primaryRootSelectionDoesNotInventATab() {
        let router = NavigationRouter<CalendarTab, CalendarDestination, CalendarAlert>(
            rootDestination: .calendarHome, paths: [.primary: [.lunarYear(2026)]]
        )
        #expect(router.selectedScope == nil)
        #expect(router.selectedDestination == .lunarYear(2026))
        router.selectedScope = nil
        #expect(router.selectedScope == nil)
        #expect(router.rootPresentation.context(for: .primary).path == [.lunarYear(2026)])
        #expect(router.rootPresentation.context(for: .primary).pop() == .applied)
        #expect(router.selectedDestination == .calendarHome)
    }

    @Test(arguments: CalendarTab.allCases)
    func rootAndLocalOperationsUseTheSamePathForEveryTab(tab: CalendarTab) {
        let router = CalendarRouter()
        let context = router.navigation.context(for: tab)
        router.push(.lunarYear(2025), on: tab)
        #expect(router.selectedTab == tab)
        #expect(context.path == [.lunarYear(2025)])
        #expect(context.push(.lunarYear(2026)) == .applied)
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
            .present(.dynasty(orthodoxPeriodID: "qing")) == .applied)
        let dynasty = try #require(router.sheet)
        let modal = router.navigation.context(for: dynasty)
        #expect(modal.push(.emperorList(dynastyID: "qing")) == .applied)
        #expect(router.navigation.presentationContext(for: dynasty)
            .present(.emperor("qing-shizu"), style: .fullScreen) == .applied)
        let child = try router.navigation.presentationContext(for: #require(dynasty.fullScreen))
        #expect(child.dismiss() == .applied)
        #expect(dynasty.path == [.emperorList(dynastyID: "qing")])
        #expect(history.path == [.dynasty(orthodoxPeriodID: "ming")])
        #expect(router.sheet === dynasty)
    }

    @Test func appDeepLinkCancelAndApprovalUseTheCoreTransaction() throws {
        let coordinator = CalendarHomeCoordinator()
        coordinator.router.navigation.rootPresentation.scoped(to: .scope(.years)).present(.lunarYear(2025))
        let original = try #require(coordinator.router.sheet)
        coordinator.openDeepLink(.emperor("ming-taizu"))
        let first = try #require(coordinator.router.navigation.pendingConfirmation)
        coordinator.router.navigation.cancelConfirmation(id: first.id)
        #expect(coordinator.router.sheet === original)
        #expect(original.destination == .lunarYear(2025))
        #expect(original.path.isEmpty)
        #expect(coordinator.router.selectedTab == .years)
        #expect(coordinator.router.navigation.paths.isEmpty)
        coordinator.openDeepLink(.emperor("ming-taizu"))
        try coordinator.router.navigation
            .confirmNavigation(id: #require(coordinator.router.navigation.pendingConfirmation).id)
        #expect(coordinator.router.historyPath.isEmpty)
        coordinator.rootPresentationDidDismiss()
        #expect(coordinator.router.navigation.rootDestination(for: .history) == .emperor("ming-taizu"))
        #expect(coordinator.router.historyPath.isEmpty)
        #expect(coordinator.router.selectedTab == .history)
    }

    @Test func appRootAndTabRootsAreExplicit() {
        let router = CalendarRouter()
        #expect(router.navigation.rootPresentation.destination == .mainTabs)
        #expect(router.navigation.rootDestinations == [
            .years: .calendarHome, .history: .historyEmpty, .settings: .settings
        ])
        for tab in CalendarTab.allCases {
            #expect(router.navigation.context(for: tab).isActive)
        }
    }

    @Test(arguments: [CalendarDestination.mainTabs, .calendarHome, .historyHome, .settings])
    func navigationStateAcceptsAppDestinationsWithoutEntryAllowlist(destination: CalendarDestination) throws {
        let router = CalendarRouter()
        let years = router.navigation.context(for: .years)
        #expect(years.push(destination) == .applied)
        #expect(years.path == [destination])
        let accepted = switch destination {
        case .mainTabs: router.navigation.rootPresentation.presentMainTabs()
        case .historyHome: router.navigation.rootPresentation.presentHistory()
        default: router.navigation.rootPresentation.present(destination)
        }
        #expect(accepted == .applied)
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
        let rootPaths = router.navigation.paths
        #expect(router.navigation.rootPresentation.presentMainTabs(
            selectedTab: .settings, paths: [.scope(.years): [.lunarYear(2026)]]
        ) == .applied)
        let node = try #require(router.sheet)
        let modal = router.navigation.presentationContext(for: node)
        #expect(modal.destination == .mainTabs)
        #expect(modal.selectedStack == .scope(.settings))
        #expect(modal.context(for: .scope(.settings)).rootDestination == .settings)
        #expect(modal.context(for: .scope(.history)).push(.emperor("qing-shizu")) == .applied)
        #expect(modal.context(for: .scope(.settings)).push(.historyHome) == .applied)
        modal.selectedStack = .scope(.years)
        #expect(modal.scoped(to: .scope(.years)).presentMainTabs(style: .fullScreen, selectedTab: .history) == .applied)
        let childNode = try #require(node.fullScreen)
        let child = router.navigation.presentationContext(for: childNode)
        #expect(child.context(for: .scope(.history)).push(.dynasty(orthodoxPeriodID: "qing")) == .applied)
        #expect(child.selectedStack == .scope(.history))
        #expect(modal.selectedStack == .scope(.years))
        #expect(router.selectedTab == .history)
        #expect(router.navigation.paths == rootPaths)
        #expect(modal.context(for: .scope(.years)).path == [.lunarYear(2026)])
        #expect(modal.context(for: .scope(.history)).path == [.emperor("qing-shizu")])
        #expect(modal.context(for: .scope(.settings)).path == [.historyHome])
        #expect(child.context(for: .scope(.years)).path.isEmpty)
        #expect(child.context(for: .scope(.settings)).path.isEmpty)

        #expect(child.dismiss() == .applied)
        #expect(!child.isActive)
        #expect(modal.isActive)
        #expect(modal.context(for: .scope(.history)).path == [.emperor("qing-shizu")])
        #expect(router.navigation.paths == rootPaths)
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

        @Test func debugNavigationPushUsesTheSettingsStack() {
            let router = CalendarRouter(selectedTab: .settings)
            let destination = CalendarDestination.debugNavigation(id: UUID())
            #expect(router.navigation.context(for: .settings).push(destination) == .applied)
            #expect(router.path(for: .settings) == [destination])
            #expect(router.selectedDestination == destination)
            #expect(router.yearsPath.isEmpty)
            #expect(router.historyPath.isEmpty)
        }
    #endif
}

extension CalendarNavigationContextTests {
    @Test func replacedRootAndModalTabRootsKeepIndependentPathsAndSelections() throws {
        let router = CalendarRouter(yearsPath: [.lunarYear(2025)], historyPath: [.emperor("ming-taizu")])
        let rootHistory = router.navigation.context(for: .history)
        #expect(rootHistory.setRootDestination(.dynasty(orthodoxPeriodID: "ming")) == .applied)
        #expect(rootHistory.path.isEmpty)
        #expect(rootHistory.push(.emperorList(dynastyID: "ming")) == .applied)
        #expect(router.navigation.rootPresentation.presentMainTabs(
            selectedTab: .history, paths: [.scope(.history): [.emperor("qing-shizu")]]
        ) == .applied)
        let modal = try router.navigation.presentationContext(for: #require(router.sheet))
        let modalHistory = modal.context(for: .scope(.history))
        #expect(modalHistory.setRootDestination(.dynasty(orthodoxPeriodID: "qing")) == .applied)
        #expect(modalHistory.path.isEmpty)
        #expect(modalHistory.push(.emperorList(dynastyID: "qing")) == .applied)
        #expect(rootHistory.rootDestination == .dynasty(orthodoxPeriodID: "ming"))
        #expect(rootHistory.path == [.emperorList(dynastyID: "ming")])
        #expect(router.historyPath == [.emperorList(dynastyID: "ming")])
        #expect(router.yearsPath == [.lunarYear(2025)])
        #expect(router.selectedTab == .years)
        #expect(modalHistory.rootDestination == .dynasty(orthodoxPeriodID: "qing"))
        #expect(modalHistory.path == [.emperorList(dynastyID: "qing")])
        #expect(modal.selectedStack == .scope(.history))
        #expect(router.navigation.rootPresentation.destination == .mainTabs)
        #expect(modal.destination == .mainTabs)
    }
}
