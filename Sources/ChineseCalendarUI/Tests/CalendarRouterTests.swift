@testable import ChineseCalendarUI
import Foundation
import NavigationCore
import Testing

@MainActor
@Test func pushUpdatesSelectedTabPath() {
    let router = CalendarRouter()

    router.navigation.submit(.push(.dynasty(orthodoxPeriodID: "qin-period"), on: .history))

    #expect(router.selectedTab == .history)
    #expect(router.historyPath == [.dynasty(orthodoxPeriodID: "qin-period")])
    #expect(router.yearsPath.isEmpty)
}

@MainActor
@Test func tabPathsDoNotPolluteEachOther() {
    let router = CalendarRouter()

    router.navigation.submit(.push(.lunarYear(2025), on: .years))
    router.navigation.submit(.push(.dynasty(orthodoxPeriodID: "qin-period"), on: .history))

    #expect(router.yearsPath == [.lunarYear(2025)])
    #expect(router.historyPath == [.dynasty(orthodoxPeriodID: "qin-period")])
    #expect(router.selectedTab == .history)
    #expect(router.navigation.rootPresentation.context(for: .scope(.years)).path.last == .lunarYear(2025))
}

@MainActor
@Test func historyRoutePreservesOrthodoxPeriodIdentity() {
    let router = CalendarRouter(selectedTab: .history)
    let destination = CalendarDestination.dynasty(orthodoxPeriodID: "orthodox-ming")

    router.navigation.rootPresentation.context(for: .scope(.history)).push(destination)

    #expect(router.historyPath == [destination])
    #expect(destination.id == "dynasty-orthodox-ming")
}

@MainActor
@Test func historyPathPushPopAndTabRestorationKeepIndependentDestinations() {
    let dynasty = CalendarDestination.dynasty(orthodoxPeriodID: "orthodox-ming")
    let emperorList = CalendarDestination.emperorList(dynastyID: "ming")
    let router = CalendarRouter(selectedTab: .history)

    router.navigation.rootPresentation.context(for: .scope(.history)).push(dynasty)
    router.navigation.rootPresentation.context(for: .scope(.history)).push(emperorList)
    router.selectedTab = .years
    router.navigation.submit(.push(.lunarYear(2026), on: .years))
    router.selectedTab = .history

    #expect(router.historyPath == [dynasty, emperorList])
    #expect(router.navigation.rootPresentation.context(for: .scope(.history)).path.last == emperorList)

    router.historyPath.removeLast()

    #expect(router.historyPath == [dynasty])
    #expect(router.navigation.rootPresentation.context(for: .scope(.history)).path.last == dynasty)
    #expect(router.yearsPath == [.lunarYear(2026)])
}

@Test func historyDestinationIDsIncludeEveryStableRecordID() {
    #expect(
        CalendarDestination.dynastySpan(
            orthodoxPeriodID: "orthodox-ming"
        ).id == "dynasty-span-orthodox-ming"
    )
    #expect(
        CalendarDestination.reignEra(reignEraID: "ming-era-yongle").id
            == "reign-era-ming-era-yongle"
    )
}

@MainActor
@Test func replacingYearsPathChangesItsCurrentDestination() {
    let router = CalendarRouter(yearsPath: [.lunarYear(2025)])

    router.yearsPath = [.lunarYear(2026)]

    #expect(router.yearsPath == [.lunarYear(2026)])
    #expect(router.navigation.rootPresentation.context(for: .scope(.years)).path.last == .lunarYear(2026))
}

@MainActor
@Test func externalDeepLinkKeepsTheRootPathAndModalAliveWhileWaitingForConfirmation() async throws {
    let router = CalendarRouter(yearsPath: [.lunarYear(2024)])
    let coordinator = CalendarHomeCoordinator(router: router)
    let host = try await NavigationTestHost.show(router: router.navigation)
    defer { host.removeFromWindow() }
    var finishCount = 0
    #expect(router.navigation.rootPresentation.present(.lunarYear(2025), onDismiss: { finishCount += 1 })
        .result == .applied)
    let modal = try await host.context(for: .lunarYear(2025))
    let controller = try await host.waitForPresentation()

    coordinator.openDeepLink(.lunarYear(2026, monthIndex: 26001))
    let alert = try await host.waitForAlert()

    #expect(alert.actions.count == 2)
    #expect(alert.actions.contains { $0.style == .cancel })
    #expect(alert.actions.contains { $0.style == .default })
    #expect(controller.viewIfLoaded?.window != nil)
    #expect(!controller.isBeingDismissed)
    #expect(modal.context(for: .primary).rootDestination == .lunarYear(2025))
    #expect(router.yearsPath == [.lunarYear(2024)])
    #expect(router.selectedTab == .years)
    #expect(finishCount == 0)
    await host.close()
}

@MainActor
@Test func deepLinkWithoutPresentationAppliesImmediately() {
    let coordinator = CalendarHomeCoordinator()

    coordinator.openDeepLink(.lunarYear(2026, monthIndex: 26001))

    #expect(coordinator.router.yearsPath == [.lunarYear(2026, monthIndex: 26001)])
    #expect(
        coordinator.router.navigation.rootPresentation.context(for: .scope(.years)).path.last
            == .lunarYear(2026, monthIndex: 26001)
    )
}

@MainActor
@Test func dynastyDeepLinkSelectsHistoryTab() {
    let router = CalendarRouter()

    #expect(router.openDeepLink(.dynasty(orthodoxPeriodID: "qin-period")) == .applied)

    #expect(router.selectedTab == .history)
    #expect(
        router.navigation.rootPresentation.context(for: .scope(.history)).rootDestination
            == .historyDetail(orthodoxPeriodID: "qin-period", section: nil)
    )
    #expect(router.historyPath.isEmpty)
}

@MainActor
@Test func emperorDeepLinkSelectsHistoryTab() {
    let router = CalendarRouter()

    #expect(router.openDeepLink(.emperor("ming-taizu")) == .applied)

    #expect(router.selectedTab == .history)
    #expect(router.navigation.rootPresentation.context(for: .scope(.history))
        .rootDestination == .emperor("ming-taizu"))
    #expect(router.historyPath.isEmpty)
}

@MainActor
@Test func laterDeepLinkCanReturnToCalendarAfterHistoryNavigation() {
    let coordinator = CalendarHomeCoordinator()
    coordinator.openDeepLink(.lunarYear(2025))
    coordinator.openDeepLink(.emperor("ming-taizu"))
    #expect(coordinator.router.selectedTab == .history)

    coordinator.openDeepLink(.lunarYear(2025))
    #expect(coordinator.router.selectedTab == .years)
    #expect(coordinator.router.yearsPath == [.lunarYear(2025)])
    #expect(coordinator.router.navigation.rootPresentation.context(for: .scope(.history)).rootDestination
        == .emperor("ming-taizu"))
}

@MainActor
@Test(arguments: [
    "chinesecalendar://year/2026",
    "https://example.com/year/2026",
    "chinesecalendar://unsupported/2026",
    "chinesecalendar://year/not-a-year"
])
func systemURLParsingOnlySubmitsSupportedLinks(urlString: String) throws {
    let coordinator = CalendarHomeCoordinator(router: CalendarRouter(yearsPath: [.lunarYear(2024)]))
    let url = try #require(URL(string: urlString))
    if let deepLink = CalendarDeepLinkParser.deepLink(from: url) {
        coordinator.openDeepLink(deepLink)
    }

    let expectedYear = urlString == "chinesecalendar://year/2026" ? 2026 : 2024
    #expect(coordinator.router.yearsPath == [.lunarYear(expectedYear)])
    #expect(coordinator.router.selectedTab == .years)
}

@Test func parserSupportsYearURLs() throws {
    let url = try #require(URL(string: "chinesecalendar://year/2026?monthIndex=26001"))

    #expect(CalendarDeepLinkParser.deepLink(from: url) == .lunarYear(2026, monthIndex: 26001))
}

@Test func parserSupportsDynastyURLs() throws {
    let url = try #require(URL(string: "chinesecalendar://dynasty/qin-period"))

    #expect(
        CalendarDeepLinkParser.deepLink(from: url)
            == .dynasty(orthodoxPeriodID: "qin-period")
    )
}

@Test func parserSupportsEmperorURLs() throws {
    let url = try #require(URL(string: "chinesecalendar://emperor/ming-taizu"))

    #expect(CalendarDeepLinkParser.deepLink(from: url) == .emperor("ming-taizu"))
}

@Test func parserSupportsAlternateSchemeAndMonthQuery() throws {
    let url = try #require(URL(string: "chinese-calendar://2026?month=26001"))

    #expect(CalendarDeepLinkParser.deepLink(from: url) == .lunarYear(2026, monthIndex: 26001))
}
