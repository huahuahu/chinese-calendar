@testable import ChineseCalendarUI
import NavigationCore
import SwiftUI
import Testing

@MainActor
@Suite("历史三栏选择与详情导航", .serialized)
struct CalendarHistoryStateTests {
    @Test func upstreamSelectionClearsDependentSelectionAndPath() {
        let router = CalendarRouter(selectedTab: .history)
        let navigation = router.navigation.rootPresentation.context(for: .scope(.history))
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
        let navigation = router.navigation.rootPresentation.context(for: .scope(.history))
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
}

extension CalendarHistoryStateTests {
    @Test func emperorRootResolvesItsParentWithoutAcceptingStaleResults() {
        let router = CalendarRouter()
        let navigation = router.navigation.rootPresentation.context(for: .scope(.history))
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

    @Test func selectingEmperorsFromAnEmperorRootOpensTheList() {
        let router = CalendarRouter()
        let navigation = router.navigation.rootPresentation.context(for: .scope(.history))
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
}

extension CalendarHistoryStateTests {
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

extension CalendarHistoryStateTests {
    @Test func modalSelectionIsIndependentAndStaleStateCannotChangeAReopenedPage() async throws {
        let router = CalendarRouter(selectedTab: .history)
        let root = router.navigation.rootPresentation
        let rootState = CalendarHistoryState(navigation: root.context(for: .scope(.history)))
        #expect(rootState.selectOrthodoxPeriod("ming-period"))
        let host = try await NavigationTestHost.show(router: router.navigation)
        defer { host.removeFromWindow() }
        var finishCount = 0
        let first = root.present(.historyHome, rootDestinations: [.primary: .historyEmpty]) { finishCount += 1 }
        #expect(first.result == .applied)
        let context = try await host.context(for: .historyHome)
        let navigation = context.context(for: .primary)
        let state = CalendarHistoryState(navigation: navigation)
        #expect(state.selectOrthodoxPeriod("qing-period"))
        #expect(state.selectSection(.emperors))
        #expect(navigation.push(.emperor("qing-shizu")) == .applied)
        #expect(rootState.orthodoxPeriodID == "ming-period")
        _ = try await host.waitForPresentation()
        #expect(try #require(first.handle).dismiss().isAccepted)
        #expect(!state.selectOrthodoxPeriod("other-period"))
        try await host.waitUntil { finishCount == 1 }

        let reopened = root.present(.historyHome, rootDestinations: [.primary: .historyEmpty])
        #expect(reopened.result == .applied)
        let nextContext = try await host.context(for: .historyHome, differentFrom: context)
        let nextNavigation = nextContext.context(for: .primary)
        let nextState = CalendarHistoryState(navigation: nextNavigation)
        #expect(nextNavigation !== navigation)
        #expect(nextState.orthodoxPeriodID == nil)
        #expect(nextState.preferredCompactColumn == .sidebar)
        #expect(nextState.selectOrthodoxPeriod("han-period"))
        #expect(!state.selectSection(.reignEras))
        #expect(nextState.orthodoxPeriodID == "han-period")
        #expect(rootState.orthodoxPeriodID == "ming-period")
        await host.close()
    }

    @Test func activeAlertRejectsSelectionWithoutChangingTheVisibleLayout() async throws {
        let router = CalendarRouter(selectedTab: .history)
        let root = router.navigation.rootPresentation
        let navigation = root.context(for: .scope(.history))
        let state = CalendarHistoryState(navigation: navigation)
        #expect(state.selectOrthodoxPeriod("ming-period"))
        #expect(state.selectSection(.emperors))
        #expect(navigation.push(.emperor("ming-taizu")) == .applied)
        state.columnVisibility = .detailOnly
        let host = try await NavigationTestHost.show(router: router.navigation)
        defer { host.removeFromWindow() }
        #expect(root.presentAlert(.clearDataSucceeded).result == .applied)
        _ = try await host.waitForAlert()

        #expect(!state.selectOrthodoxPeriod("qing-period"))
        #expect(!state.selectSection(.reignEras))
        #expect(!state.synchronizeRoot())
        #expect(state.orthodoxPeriodID == "ming-period")
        #expect(state.section == .emperors)
        #expect(state.columnVisibility == .detailOnly)
        #expect(state.preferredCompactColumn == .detail)
        #expect(navigation.path == [.emperor("ming-taizu")])
        await host.close()
    }

    @Test func externalRootWaitsForTheActualModalDismissal() async throws {
        let router = CalendarRouter(selectedTab: .history)
        let root = router.navigation.rootPresentation
        let navigation = root.context(for: .scope(.history))
        let state = CalendarHistoryState(navigation: navigation)
        #expect(state.selectOrthodoxPeriod("ming-period"))
        let host = try await NavigationTestHost.show(router: router.navigation)
        defer { host.removeFromWindow() }
        var finishCount = 0
        #expect(root.present(.settings, onDismiss: { finishCount += 1 }).result == .applied)
        _ = try await host.waitForPresentation()
        #expect(router
            .openDeepLink(.emperor("qing-shizu"), confirmIfPresented: false) == .deferredUntilPresentationDismisses)
        #expect(state.orthodoxPeriodID == "ming-period")
        #expect(finishCount == 0)
        try await host.waitUntil { navigation.rootDestination == .emperor("qing-shizu") }
        #expect(finishCount == 1)
        #expect(state.synchronizeRoot())
        #expect(state.preferredCompactColumn == .detail)
        await host.close()
    }
}
