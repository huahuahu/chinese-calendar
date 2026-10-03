@testable import ChineseCalendarUI
import Foundation
import Testing

@MainActor
@Test func pushUpdatesSelectedTabPath() {
    let router = CalendarRouter()

    router.push(.dynasty(orthodoxPeriodID: "qin-period"), on: .history)

    #expect(router.selectedTab == .history)
    #expect(router.historyPath == [.dynasty(orthodoxPeriodID: "qin-period")])
    #expect(router.yearsPath.isEmpty)
}

@MainActor
@Test func tabPathsDoNotPolluteEachOther() {
    let router = CalendarRouter()

    router.push(.lunarYear(2025), on: .years)
    router.push(.dynasty(orthodoxPeriodID: "qin-period"), on: .history)

    #expect(router.yearsPath == [.lunarYear(2025)])
    #expect(router.historyPath == [.dynasty(orthodoxPeriodID: "qin-period")])
    #expect(router.selectedDestination == .dynasty(orthodoxPeriodID: "qin-period"))
    #expect(router.currentDestination(on: .years) == .lunarYear(2025))
}

@MainActor
@Test func historyRoutePreservesOrthodoxPeriodIdentity() {
    let router = CalendarRouter(selectedTab: .history)
    let destination = CalendarDestination.dynasty(orthodoxPeriodID: "orthodox-ming")

    router.push(destination)

    #expect(router.historyPath == [destination])
    #expect(destination.id == "dynasty-orthodox-ming")
}

@MainActor
@Test func historyPathPushPopAndTabRestorationKeepIndependentDestinations() {
    let dynasty = CalendarDestination.dynasty(orthodoxPeriodID: "orthodox-ming")
    let emperorList = CalendarDestination.emperorList(dynastyID: "ming")
    let router = CalendarRouter(selectedTab: .history)

    router.push(dynasty)
    router.push(emperorList)
    router.selectedTab = .years
    router.push(.lunarYear(2026), on: .years)
    router.selectedTab = .history

    #expect(router.historyPath == [dynasty, emperorList])
    #expect(router.currentDestination(on: .history) == emperorList)

    router.historyPath.removeLast()

    #expect(router.historyPath == [dynasty])
    #expect(router.currentDestination(on: .history) == dynasty)
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

    router.setPath([.lunarYear(2026)], for: .years)

    #expect(router.yearsPath == [.lunarYear(2026)])
    #expect(router.currentDestination(on: .years) == .lunarYear(2026))
}

@MainActor
@Test func hotDeepLinkDismissesActivePresentationTreeBeforeRouting() {
    let router = CalendarRouter(yearsPath: [.lunarYear(2024)])
    let coordinator = CalendarHomeCoordinator(router: router)
    router.presentSheet(.lunarYear(2025))

    coordinator.openDeepLink(.lunarYear(2026, monthIndex: 26001))

    #expect(router.sheet == nil)
    #expect(
        router.navigation.deferredRequest
            == .replacePath([.lunarYear(2026, monthIndex: 26001)], on: .years)
    )
    #expect(router.currentDestination(on: .years) == .lunarYear(2024))

    router.navigation.applyDeferredRequestIfReady()

    #expect(router.navigation.deferredRequest == nil)
    #expect(router.currentDestination(on: .years) == .lunarYear(2026, monthIndex: 26001))
    #expect(router.yearsPath == [.lunarYear(2026, monthIndex: 26001)])
}

@MainActor
@Test func coldLaunchDeepLinkAppliesImmediately() {
    let coordinator = CalendarHomeCoordinator()

    coordinator.openColdLaunchDeepLink(.lunarYear(2026, monthIndex: 26001))

    #expect(coordinator.router.navigation.deferredRequest == nil)
    #expect(coordinator.router.yearsPath == [.lunarYear(2026, monthIndex: 26001)])
    #expect(
        coordinator.router.currentDestination(on: .years)
            == .lunarYear(2026, monthIndex: 26001)
    )
}

@MainActor
@Test func dynastyDeepLinkSelectsHistoryTab() {
    let coordinator = CalendarHomeCoordinator()

    coordinator.openColdLaunchDeepLink(.dynasty(orthodoxPeriodID: "qin-period"))

    #expect(coordinator.router.selectedTab == .history)
    #expect(
        coordinator.router.historyPath
            == [.dynasty(orthodoxPeriodID: "qin-period")]
    )
}

@MainActor
@Test func emperorDeepLinkSelectsHistoryTab() {
    let coordinator = CalendarHomeCoordinator()

    coordinator.openColdLaunchDeepLink(.emperor("ming-taizu"))

    #expect(coordinator.router.selectedTab == .history)
    #expect(coordinator.router.historyPath == [.emperor("ming-taizu")])
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

@Test func parserSupportsLaunchArguments() {
    let deepLink = CalendarDeepLinkParser.deepLink(from: [
        "ChineseCalendar",
        "--deep-link",
        "chinese-calendar://2026?month=26001"
    ])

    #expect(deepLink == .lunarYear(2026, monthIndex: 26001))
}
