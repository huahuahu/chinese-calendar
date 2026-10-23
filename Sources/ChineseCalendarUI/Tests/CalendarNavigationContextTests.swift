@testable import ChineseCalendarUI
import Foundation
import NavigationCore
import Testing

@MainActor
@Suite("App 使用局部导航框架", .serialized)
struct CalendarNavigationContextTests {
    @Test func rootSelectionProjectsTheCurrentTabDestination() {
        let router = CalendarRouter(selectedTab: .history, historyPath: [.dynasty(orthodoxPeriodID: "ming")])
        let root = router.navigation.rootPresentation
        #expect(router.selectedTab == .history)
        #expect(root.context(for: root.selectedStack).path.last == .dynasty(orthodoxPeriodID: "ming"))
        router.selectedTab = nil
        #expect(router.selectedTab == .history)
        #expect(root.context(for: root.selectedStack).path.last == .dynasty(orthodoxPeriodID: "ming"))
        router.selectedTab = .settings
        #expect(router.selectedTab == .settings)
        #expect(root.context(for: root.selectedStack).rootDestination == .settings)
    }

    @Test func primaryRootSelectionDoesNotInventATab() {
        let router = NavigationTestHost.Router(rootDestination: .calendarHome, paths: [.primary: [.lunarYear(2026)]])
        let root = router.rootPresentation
        let navigation = root.context(for: .primary)
        #expect(root.selectedStack == .primary)
        #expect(navigation.path == [.lunarYear(2026)])
        #expect(navigation.pop() == .applied)
        #expect(navigation.path.isEmpty)
        #expect(navigation.rootDestination == .calendarHome)
    }

    @Test(arguments: CalendarTab.allCases)
    func rootAndLocalOperationsUseTheSamePathForEveryTab(tab: CalendarTab) {
        let router = CalendarRouter()
        let context = router.navigation.rootPresentation.context(for: .scope(tab))
        #expect(router.navigation.submit(.push(.lunarYear(2025), on: tab)) == .applied)
        #expect(router.selectedTab == tab)
        #expect(context.path == [.lunarYear(2025)])
        #expect(context.push(.lunarYear(2026)) == .applied)
        #expect(context.path == [.lunarYear(2025), .lunarYear(2026)])
        #expect(router.navigation.rootPresentation.context(for: .scope(tab)) === context)
        #expect(context.setPath([]) == .applied)
        #expect(context.path.isEmpty)
        #expect(context.rootDestination == CalendarRouter.mainTabRoots[.scope(tab)])
    }

    @Test func historyModalPushAndNestedPresentationPreserveTabNavigation() async throws {
        let router = CalendarRouter(selectedTab: .history, historyPath: [.dynasty(orthodoxPeriodID: "ming")])
        let root = router.navigation.rootPresentation
        let history = root.context(for: .scope(.history))
        let host = try await NavigationTestHost.show(router: router.navigation)
        defer { host.removeFromWindow() }
        #expect(root.scoped(to: .scope(.history)).present(.dynasty(orthodoxPeriodID: "qing")).result == .applied)
        let modal = try await host.context(for: .dynasty(orthodoxPeriodID: "qing"))
        _ = try await host.waitForPresentation()
        #expect(modal.context(for: .primary).push(.emperorList(dynastyID: "qing")) == .applied)
        #expect(modal.present(.emperor("qing-shizu"), style: .fullScreen).result == .applied)
        let child = try await host.context(for: .emperor("qing-shizu"))
        _ = try await host.waitForPresentation()
        #expect(child.dismiss() == .applied)
        #expect(modal.context(for: .primary).path == [.emperorList(dynastyID: "qing")])
        #expect(history.path == [.dynasty(orthodoxPeriodID: "ming")])
        #expect(!child.dismiss().isAccepted)
        await host.close()
    }

    @Test func appDeepLinkWaitsForConfirmationWithoutChangingTheSourceNavigation() async throws {
        let coordinator = CalendarHomeCoordinator()
        let router = coordinator.router
        let root = router.navigation.rootPresentation
        let host = try await NavigationTestHost.show(router: router.navigation)
        defer { host.removeFromWindow() }
        #expect(root.scoped(to: .scope(.years)).present(.lunarYear(2025)).result == .applied)
        let original = try await host.context(for: .lunarYear(2025))
        let controller = try await host.waitForPresentation()
        coordinator.openDeepLink(.emperor("ming-taizu"))
        let alert = try await host.waitForAlert()
        #expect(alert.actions.count == 2)
        #expect(alert.actions.contains { $0.style == .cancel })
        #expect(alert.actions.contains { $0.style == .default })
        #expect(controller.viewIfLoaded?.window != nil)
        #expect(!controller.isBeingDismissed)
        #expect(original.context(for: .primary).rootDestination == .lunarYear(2025))
        #expect(original.context(for: .primary).path.isEmpty)
        #expect(router.selectedTab == .years)
        #expect(router.yearsPath.isEmpty)
        #expect(router.historyPath.isEmpty)
        await host.close()
    }

    @Test func appRootAndTabRootsAreExplicit() {
        let router = CalendarRouter()
        let root = router.navigation.rootPresentation
        #expect(root.context(for: .scope(.settings)).rootDestination == .settings)
        for tab in CalendarTab.allCases {
            let context = root.context(for: .scope(tab))
            #expect(context.rootDestination == CalendarRouter.mainTabRoots[.scope(tab)])
            #expect(context.setPath([]) == .applied)
        }
    }

    @Test(arguments: [CalendarDestination.mainTabs, .calendarHome, .historyHome, .settings])
    func navigationStateAcceptsAppDestinationsWithoutEntryAllowlist(destination: CalendarDestination) async throws {
        let router = CalendarRouter()
        let root = router.navigation.rootPresentation
        let years = root.context(for: .scope(.years))
        let host = try await NavigationTestHost.show(router: router.navigation)
        defer { host.removeFromWindow() }
        #expect(years.push(destination) == .applied)
        let accepted = switch destination {
        case .mainTabs: root.presentMainTabs()
        case .historyHome: root.present(.historyHome, rootDestinations: [.primary: .historyEmpty])
        default: root.present(destination)
        }
        #expect(accepted.result == .applied)
        let modal = try await host.context(for: destination)
        #expect(host.contexts[destination] === modal)
        let expectedRoot: CalendarDestination = switch destination {
        case .mainTabs: .calendarHome
        case .historyHome: .historyEmpty
        default: destination
        }
        #expect(modal.context(for: modal.selectedStack).rootDestination == expectedRoot)
        #expect(root.context(for: .scope(.settings)).rootDestination == .settings)
        #expect(years.path == [destination])
        await host.close()
    }

    #if DEBUG
        @Test func backgroundPresentationDoesNotLeaveADebugSessionBehind() async throws {
            let coordinator = CalendarHomeCoordinator()
            let feature = FullStoreDownloadPreviewFeature()
            let root = coordinator.router.navigation.rootPresentation
            let presentation = root.scoped(to: .scope(.settings))
            let host = try await NavigationTestHost.show(router: coordinator.router.navigation)
            defer { host.removeFromWindow() }
            feature.present(from: presentation, coordinator: coordinator)
            #expect(feature.session == nil)
            #expect(host.presentedViewController() == nil)

            coordinator.router.selectedTab = .settings
            feature.present(from: presentation, coordinator: coordinator)
            #expect(feature.session != nil)
            _ = try await host.waitForPresentation()
            #expect(coordinator.router.navigation.dismissAllPresentations().isAccepted)
            try await host.waitUntil { feature.session == nil }
            await host.close()
        }

        @Test func debugNavigationPushUsesTheSettingsStack() {
            let router = CalendarRouter(selectedTab: .settings)
            let destination = CalendarDestination.debugNavigation(id: UUID())
            let settings = router.navigation.rootPresentation.context(for: .scope(.settings))
            #expect(settings.push(destination) == .applied)
            #expect(settings.path == [destination])
            #expect(router.selectedTab == .settings)
            #expect(router.yearsPath.isEmpty)
            #expect(router.historyPath.isEmpty)
        }
    #endif
}

extension CalendarNavigationContextTests {
    @Test func mainTabsModalAndItsChildKeepRootSelectionsAndEveryTabPathIndependent() async throws {
        let router = CalendarRouter(
            selectedTab: .history, yearsPath: [.lunarYear(2025)], historyPath: [.dynasty(orthodoxPeriodID: "ming")]
        )
        let root = router.navigation.rootPresentation
        #expect(root.context(for: .scope(.settings)).setPath([.calendarHome]) == .applied)
        let rootPaths = CalendarTab.allCases.map { root.context(for: .scope($0)).path }
        let host = try await NavigationTestHost.show(router: router.navigation)
        defer { host.removeFromWindow() }
        #expect(root.presentMainTabs(selectedTab: .settings, paths: [.scope(.years): [.lunarYear(2026)]])
            .result == .applied)
        let modal = try await host.context(for: .mainTabs)
        _ = try await host.waitForPresentation()
        #expect(host.contexts[.mainTabs] === modal)
        #expect(modal.selectedStack == .scope(.settings))
        #expect(modal.context(for: .scope(.settings)).rootDestination == .settings)
        #expect(modal.context(for: .scope(.history)).push(.emperor("qing-shizu")) == .applied)
        #expect(modal.context(for: .scope(.settings)).push(.historyHome) == .applied)
        modal.selectedStack = .scope(.years)
        #expect(modal.scoped(to: .scope(.years)).presentMainTabs(style: .fullScreen, selectedTab: .history)
            .result == .applied)
        let child = try await host.context(for: .mainTabs, differentFrom: modal)
        _ = try await host.waitForPresentation()
        #expect(child.context(for: .scope(.history)).push(.dynasty(orthodoxPeriodID: "qing")) == .applied)
        #expect(child.selectedStack == .scope(.history))
        #expect(modal.selectedStack == .scope(.years))
        #expect(router.selectedTab == .history)
        #expect(CalendarTab.allCases.map { root.context(for: .scope($0)).path } == rootPaths)
        #expect(modal.context(for: .scope(.years)).path == [.lunarYear(2026)])
        #expect(modal.context(for: .scope(.history)).path == [.emperor("qing-shizu")])
        #expect(modal.context(for: .scope(.settings)).path == [.historyHome])
        #expect(child.context(for: .scope(.years)).path.isEmpty)
        #expect(child.context(for: .scope(.settings)).path.isEmpty)

        #expect(child.dismiss() == .applied)
        #expect(child.context(for: .scope(.history)).push(.settings) == .rejected(.inactiveContext))
        #expect(modal.context(for: .scope(.history)).path == [.emperor("qing-shizu")])
        #expect(CalendarTab.allCases.map { root.context(for: .scope($0)).path } == rootPaths)
        await host.close()
    }

    @Test func replacedRootAndModalTabRootsKeepIndependentPathsAndSelections() async throws {
        let router = CalendarRouter(yearsPath: [.lunarYear(2025)], historyPath: [.emperor("ming-taizu")])
        let root = router.navigation.rootPresentation
        let rootHistory = root.context(for: .scope(.history))
        #expect(rootHistory.setRootDestination(.dynasty(orthodoxPeriodID: "ming")) == .applied)
        #expect(rootHistory.path.isEmpty)
        #expect(rootHistory.push(.emperorList(dynastyID: "ming")) == .applied)
        let host = try await NavigationTestHost.show(router: router.navigation)
        defer { host.removeFromWindow() }
        #expect(root.presentMainTabs(selectedTab: .history, paths: [.scope(.history): [.emperor("qing-shizu")]])
            .result == .applied)
        let modal = try await host.context(for: .mainTabs)
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
        #expect(root.context(for: .scope(.settings)).rootDestination == .settings)
        #expect(host.contexts[.mainTabs] === modal)
        await host.close()
    }
}
