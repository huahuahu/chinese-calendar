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
        #expect(router.navigation.rootPresentation.destination == .root)
        #expect(router.navigation.rootDestinations == [
            .years: .calendarHome, .history: .historyHome, .settings: .settings
        ])
        #expect(!router.navigation.context(for: .years).push(.root))
        #expect(!router.navigation.rootPresentation.present(.root))
        let before = router.navigation.snapshot
        #expect(!router.restore(.init(rootDestination: .root, selectedScope: .years)))
        #expect(router.navigation.snapshot == before)
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
