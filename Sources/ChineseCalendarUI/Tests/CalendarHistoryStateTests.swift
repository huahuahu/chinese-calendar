@testable import ChineseCalendarUI
@testable import NavigationCore
import SwiftUI
import Testing

@MainActor
@Suite("历史三栏选择与详情导航")
struct CalendarHistoryStateTests {
    @Test func upstreamSelectionClearsDependentSelectionAndPath() {
        let router = CalendarRouter(selectedTab: .history)
        let navigation = router.navigation.context(for: .history)
        let state = CalendarHistoryState(navigation: navigation)
        #expect(navigation.rootDestination == .historyEmpty)
        #expect(state.selectOrthodoxPeriod("ming-period"))
        #expect(state.section == nil)
        #expect(state.preferredCompactColumn == .content)
        #expect(state.selectSection(.emperors))
        #expect(navigation.push(.emperor("ming-taizu")) == .applied)

        #expect(state.selectOrthodoxPeriod("qing-period"))
        #expect(state.orthodoxPeriodID == "qing-period")
        #expect(state.section == nil)
        #expect(navigation.path.isEmpty)
        #expect(state.preferredCompactColumn == .content)
        #expect(state.selectSection(.reignEras))
        #expect(navigation.push(.reignEra(reignEraID: "qing-era")) == .applied)
        #expect(state.selectOrthodoxPeriod(nil))
        #expect(navigation.rootDestination == .historyEmpty)
        #expect(navigation.path.isEmpty)
        #expect(state.orthodoxPeriodID == nil)
        #expect(state.section == nil)
        #expect(state.preferredCompactColumn == .sidebar)
        #expect(!state.selectSection(.emperors))
    }

    @Test func repeatedSelectionPreservesPathAndChangingSectionClearsIt() {
        let router = CalendarRouter(selectedTab: .history)
        let navigation = router.navigation.context(for: .history)
        let state = CalendarHistoryState(navigation: navigation)
        #expect(state.selectOrthodoxPeriod("ming-period"))
        #expect(state.selectSection(.emperors))
        let path: [CalendarDestination] = [.emperor("ming-taizu"), .reignEra(reignEraID: "hongwu")]
        #expect(navigation.setPath(path) == .applied)
        #expect(state.selectOrthodoxPeriod("ming-period"))
        #expect(state.section == .emperors)
        #expect(navigation.path == path)
        #expect(state.selectSection(.emperors))
        #expect(navigation.path == path)
        #expect(state.preferredCompactColumn == .detail)

        #expect(state.selectSection(.orthodoxSpan))
        #expect(navigation.path.isEmpty)
        #expect(navigation.rootDestination == .historyDetail(orthodoxPeriodID: "ming-period", section: .orthodoxSpan))
        #expect(state.selectSection(nil))
        #expect(state.orthodoxPeriodID == "ming-period")
        #expect(state.section == nil)
        #expect(state.preferredCompactColumn == .content)
    }

    @Test func rootIsTheOnlySelectionSourceAcrossTabAndStoreChanges() {
        let coordinator = CalendarHomeCoordinator()
        let navigation = coordinator.router.navigation.context(for: .history)
        let state = coordinator.historyState(for: navigation)
        #expect(state.selectOrthodoxPeriod("ming-period"))
        #expect(state.selectSection(.reignEras))
        #expect(navigation.push(.reignEra(reignEraID: "hongwu")) == .applied)
        state.columnVisibility = .detailOnly
        coordinator.router.selectedTab = .years
        coordinator.storeIdentityDidChange("new-store")

        let retainedState = coordinator.historyState(for: navigation)
        #expect(retainedState === state)
        #expect(retainedState.orthodoxPeriodID == "ming-period")
        #expect(retainedState.section == .reignEras)
        #expect(retainedState.columnVisibility == .detailOnly)
        #expect(navigation.path == [.reignEra(reignEraID: "hongwu")])
        let rebuiltState = CalendarHistoryState(navigation: navigation)
        #expect(rebuiltState.orthodoxPeriodID == "ming-period")
        #expect(rebuiltState.section == .reignEras)
        #expect(rebuiltState.preferredCompactColumn == .detail)
    }

    @Test func activeAlertRejectsSelectionAndLayoutChangesIncludingRepeatedSelection() {
        let router = CalendarRouter(selectedTab: .history)
        let navigation = router.navigation.context(for: .history)
        let state = CalendarHistoryState(navigation: navigation)
        #expect(state.selectOrthodoxPeriod("ming-period"))
        #expect(state.selectSection(.emperors))
        #expect(navigation.push(.emperor("ming-taizu")) == .applied)
        state.preferredCompactColumn = .sidebar
        #expect(router.navigation.rootPresentation.presentAlert(.clearDownloadedData) == .applied)

        #expect(!state.selectOrthodoxPeriod("ming-period"))
        #expect(!state.selectOrthodoxPeriod("qing-period"))
        #expect(!state.selectOrthodoxPeriod(nil))
        #expect(!state.selectSection(.emperors))
        #expect(!state.selectSection(.reignEras))
        #expect(!state.synchronizeRoot())
        #expect(state.preferredCompactColumn == .sidebar)
        #expect(state.orthodoxPeriodID == "ming-period")
        #expect(state.section == .emperors)
        #expect(navigation.path == [.emperor("ming-taizu")])
    }
}

extension CalendarHistoryStateTests {
    @Test func dynastyLinkChangesSelectionOnlyAfterApprovedDismissalCompletes() throws {
        let coordinator = CalendarHomeCoordinator()
        let router = coordinator.router
        let navigation = router.navigation.context(for: .history)
        let state = coordinator.historyState(for: navigation)
        #expect(state.selectOrthodoxPeriod("ming-period"))
        #expect(state.selectSection(.emperors))
        #expect(navigation.push(.emperor("ming-taizu")) == .applied)
        router.presentSheet(.downloadDetails)
        let original = try #require(router.sheet)

        coordinator.openDeepLink(.dynasty(orthodoxPeriodID: "qing-period"))
        let cancelled = try #require(router.navigation.pendingConfirmation)
        #expect(!state.synchronizeRoot())
        #expect(state.orthodoxPeriodID == "ming-period")
        #expect(state.section == .emperors)
        router.navigation.cancelConfirmation(id: cancelled.id)
        #expect(router.sheet === original)
        #expect(navigation.path == [.emperor("ming-taizu")])

        coordinator.openDeepLink(.dynasty(orthodoxPeriodID: "qing-period"))
        try router.navigation.confirmNavigation(id: #require(router.navigation.pendingConfirmation).id)
        #expect(state.orthodoxPeriodID == "ming-period")
        #expect(navigation.path == [.emperor("ming-taizu")])
        #expect(!state.selectOrthodoxPeriod("tang-period"))
        #expect(!state.synchronizeRoot())
        coordinator.rootPresentationDidDismiss()
        #expect(state.orthodoxPeriodID == "qing-period")
        #expect(state.section == nil)
        #expect(navigation.path.isEmpty)
        #expect(state.synchronizeRoot())
        #expect(state.preferredCompactColumn == .content)
        #expect(router.selectedTab == .history)
    }

    @Test func emperorRootResolvesItsParentWithoutAcceptingStaleResults() {
        let router = CalendarRouter()
        let navigation = router.navigation.context(for: .history)
        let state = CalendarHistoryState(navigation: navigation)
        #expect(router.openDeepLink(.emperor("ming-taizu")) == .applied)
        #expect(navigation.rootDestination == .emperor("ming-taizu"))
        #expect(state.orthodoxPeriodID == nil)
        #expect(state.synchronizeRoot())
        #expect(state.preferredCompactColumn == .detail)

        #expect(state.resolveEmperorRoot(emperorID: "ming-taizu", orthodoxPeriodID: "ming-period"))
        #expect(state.orthodoxPeriodID == "ming-period")
        #expect(state.section == .emperors)
        #expect(navigation.rootDestination == .historyEmperor(orthodoxPeriodID: "ming-period", emperorID: "ming-taizu"))
        #expect(navigation.path.isEmpty)
        let rebuiltState = CalendarHistoryState(navigation: navigation)
        #expect(rebuiltState.orthodoxPeriodID == "ming-period")
        #expect(rebuiltState.section == .emperors)
        #expect(rebuiltState.preferredCompactColumn == .detail)
        #expect(!state.resolveEmperorRoot(emperorID: "ming-taizu", orthodoxPeriodID: "wrong-period"))
        #expect(router.openDeepLink(.emperor("qing-shizu")) == .applied)
        #expect(!state.resolveEmperorRoot(emperorID: "ming-taizu", orthodoxPeriodID: "ming-period"))
        #expect(navigation.rootDestination == .emperor("qing-shizu"))
        #expect(navigation.path.isEmpty)
    }

    @Test func waitingEmperorLinkCannotResolveBeforeTheRequestApplies() throws {
        let router = CalendarRouter()
        let navigation = router.navigation.context(for: .history)
        let state = CalendarHistoryState(navigation: navigation)
        #expect(state.selectOrthodoxPeriod("qing-period"))
        #expect(state.selectSection(.reignEras))
        router.presentSheet(.downloadDetails)
        #expect(router.openDeepLink(.emperor("ming-taizu"), confirmIfPresented: true) == .awaitingConfirmation)
        #expect(!state.resolveEmperorRoot(emperorID: "ming-taizu", orthodoxPeriodID: "ming-period"))
        try router.navigation.confirmNavigation(id: #require(router.navigation.pendingConfirmation).id)
        #expect(!state.resolveEmperorRoot(emperorID: "ming-taizu", orthodoxPeriodID: "ming-period"))
        #expect(state.orthodoxPeriodID == "qing-period")
        router.rootPresentationDidDismiss()
        #expect(state.resolveEmperorRoot(emperorID: "ming-taizu", orthodoxPeriodID: "ming-period"))
        #expect(state.orthodoxPeriodID == "ming-period")
        #expect(navigation.rootDestination == .historyEmperor(orthodoxPeriodID: "ming-period", emperorID: "ming-taizu"))
        #expect(navigation.path.isEmpty)
    }

    @Test func selectingEmperorsFromAnEmperorRootOpensTheList() {
        let router = CalendarRouter()
        let navigation = router.navigation.context(for: .history)
        let state = CalendarHistoryState(navigation: navigation)
        #expect(router.openDeepLink(.emperor("xin_emperor_0000")) == .applied)
        #expect(state.resolveEmperorRoot(emperorID: "xin_emperor_0000", orthodoxPeriodID: "xin-period"))
        #expect(state.section == .emperors)
        #expect(state.selectOrthodoxPeriod("xin-period"))
        #expect(navigation.rootDestination == .historyEmperor(
            orthodoxPeriodID: "xin-period", emperorID: "xin_emperor_0000"
        ))
        #expect(state.preferredCompactColumn == .content)

        #expect(state.selectSection(.emperors))
        #expect(navigation.rootDestination == .historyDetail(orthodoxPeriodID: "xin-period", section: .emperors))
        #expect(navigation.path.isEmpty)
        #expect(state.preferredCompactColumn == .detail)
    }

    @Test func activeAlertRejectsResolvingTheCurrentEmperorRoot() {
        let router = CalendarRouter()
        let navigation = router.navigation.context(for: .history)
        let state = CalendarHistoryState(navigation: navigation)
        #expect(router.openDeepLink(.emperor("ming-taizu")) == .applied)
        #expect(router.navigation.rootPresentation.presentAlert(.clearDownloadedData) == .applied)
        #expect(!state.resolveEmperorRoot(emperorID: "ming-taizu", orthodoxPeriodID: "ming-period"))
        #expect(navigation.rootDestination == .emperor("ming-taizu"))
        #expect(navigation.path.isEmpty)
        #expect(state.orthodoxPeriodID == nil)
        #expect(state.section == nil)
        #expect(state.preferredCompactColumn == .sidebar)
    }
}

extension CalendarHistoryStateTests {
    @Test func modalHistoryKeepsIndependentStateAndReleasesItAfterDismissal() throws {
        let coordinator = CalendarHomeCoordinator()
        let root = coordinator.router.navigation.context(for: .history)
        let rootState = coordinator.historyState(for: root)
        #expect(rootState.selectOrthodoxPeriod("ming-period"))
        #expect(rootState.selectSection(.emperors))
        #expect(coordinator.router.navigation.rootPresentation.presentHistory() == .applied)
        let original = try #require(coordinator.router.sheet)
        let presentation = coordinator.router.navigation.presentationContext(for: original)
        let navigation = presentation.context(for: .primary)
        weak let state = coordinator.historyState(for: navigation)
        #expect(state?.selectOrthodoxPeriod("qing-period") == true)
        #expect(state?.selectSection(.reignEras) == true)
        #expect(navigation.push(.reignEra(reignEraID: "qing-era")) == .applied)
        #expect(rootState.orthodoxPeriodID == "ming-period")
        #expect(rootState.section == .emperors)
        #expect(root.path.isEmpty)

        #expect(presentation.dismiss() == .applied)
        #expect(state?.orthodoxPeriodID == nil)
        #expect(state?.selectOrthodoxPeriod("tang-period") == false)
        #expect(coordinator.historyState(for: navigation) === state)
        coordinator.rootPresentationDidDismiss()
        #expect(state == nil)
        #expect(coordinator.router.navigation.rootPresentation.presentHistory(style: .fullScreen) == .applied)
        let reopened = try #require(coordinator.router.fullScreen)
        let reopenedNavigation = coordinator.router.navigation.context(for: reopened)
        let reopenedState = coordinator.historyState(for: reopenedNavigation)
        #expect(reopenedNavigation !== navigation)
        #expect(reopenedState.orthodoxPeriodID == nil)
        #expect(navigation.setRootDestination(.historyDetail(orthodoxPeriodID: "tang-period", section: nil))
            == .rejected(.inactiveContext))
        #expect(reopenedNavigation.rootDestination == .historyEmpty)
        #expect(rootState.orthodoxPeriodID == "ming-period")
    }

    @Test func cleanupDuringNestedDismissalKeepsHistoryStateUntilAncestorCompletes() throws {
        let coordinator = CalendarHomeCoordinator()
        let root = coordinator.router.navigation.rootPresentation
        #expect(root.presentHistory() == .applied)
        let parent = try #require(coordinator.router.sheet)
        let presentation = coordinator.router.navigation.presentationContext(for: parent)
        let navigation = presentation.context(for: .primary)
        weak var state = coordinator.historyState(for: navigation)
        #expect(state?.selectOrthodoxPeriod("ming-period") == true)
        #expect(state?.selectSection(.emperors) == true)
        state?.columnVisibility = .detailOnly
        #expect(presentation.present(.downloadDetails) == .applied)

        #expect(presentation.dismiss() == .applied)
        coordinator.releaseDismissedContexts()
        #expect(!navigation.isActive)
        #expect(state != nil)
        #expect(state?.columnVisibility == .detailOnly)
        #expect(state?.preferredCompactColumn == .detail)
        #expect(coordinator.historyState(for: navigation) === state)
        presentation.presentationDidDismiss()
        coordinator.releaseDismissedContexts()
        #expect(state != nil)

        root.presentationDidDismiss()
        coordinator.releaseDismissedContexts()
        #expect(state == nil)
        weak var inactiveState = coordinator.historyState(for: navigation)
        #expect(inactiveState == nil)
    }

    @Test func historyRoutesDeclareContainerAndStableIdentity() {
        #expect(CalendarDestination.historyHome.providesNavigationContainer)
        #expect(!CalendarDestination.historyEmpty.providesNavigationContainer)
        #expect(!CalendarDestination.historyDetail(orthodoxPeriodID: "ming-period", section: .emperors)
            .providesNavigationContainer)
        #expect(CalendarDestination.historyDetail(orthodoxPeriodID: "ming-period", section: nil).id
            != CalendarDestination.historyDetail(orthodoxPeriodID: "ming-period", section: .emperors).id)
        #expect(CalendarDestination.historyDetail(orthodoxPeriodID: "ming-period", section: .emperors).id
            != CalendarDestination.historyDetail(orthodoxPeriodID: "qing-period", section: .emperors).id)
        #expect(!CalendarDestination.historyEmperor(orthodoxPeriodID: "ming-period", emperorID: "ming-taizu")
            .providesNavigationContainer)
        #expect(CalendarDestination.historyEmperor(orthodoxPeriodID: "ming-period", emperorID: "ming-taizu").id
            != CalendarDestination.historyEmperor(orthodoxPeriodID: "other-period", emperorID: "ming-taizu").id)
        #expect(CalendarDestination.historyEmperor(orthodoxPeriodID: "ming-period", emperorID: "ming-taizu").id
            != CalendarDestination.historyEmperor(orthodoxPeriodID: "ming-period", emperorID: "ming-chengzu").id)
    }
}
