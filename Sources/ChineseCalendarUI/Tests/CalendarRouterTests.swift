@testable import ChineseCalendarUI
import Foundation
import Testing

@MainActor
@Test func defaultSelectionPrefersCurrentLunarYearWhenAvailable() {
    let router = CalendarRouter()

    let selectedYear = router.selectDefaultYearIfNeeded(
        availableYearNumbers: [2024, 2025, 2026],
        preferredYearNumber: 2025
    )

    #expect(selectedYear == 2025)
    #expect(router.selectedRoute == .lunarYear(2025))
    #expect(router.yearsPath == [.lunarYear(2025)])
}

@MainActor
@Test func defaultSelectionKeepsExistingValidRoute() {
    let router = CalendarRouter(selectedRoute: .lunarYear(2024))

    let selectedYear = router.selectDefaultYearIfNeeded(
        availableYearNumbers: [2024, 2025, 2026],
        preferredYearNumber: 2025
    )

    #expect(selectedYear == nil)
    #expect(router.selectedRoute == .lunarYear(2024))
}

@MainActor
@Test func pushUpdatesSelectedTabPath() {
    let router = CalendarRouter()

    router.push(.dynasty("qin"), on: .history)

    #expect(router.selectedTab == .history)
    #expect(router.historyPath == [.dynasty("qin")])
    #expect(router.yearsPath.isEmpty)
}

@MainActor
@Test func tabPathsDoNotPolluteEachOther() {
    let router = CalendarRouter()

    router.push(.lunarYear(2025), on: .years)
    router.push(.dynasty("qin"), on: .history)

    #expect(router.yearsPath == [.lunarYear(2025)])
    #expect(router.historyPath == [.dynasty("qin")])
    #expect(router.selectedRoute == .dynasty("qin"))
    #expect(router.currentRoute(on: .years) == .lunarYear(2025))
}

@MainActor
@Test func changingSelectedYearClearsSelectedMonth() {
    let router = CalendarRouter(selectedRoute: .lunarYear(2024), selectedMonthIndex: 24001)

    router.selectYear(2025)

    #expect(router.selectedRoute == .lunarYear(2025))
    #expect(router.selectedMonthIndex == nil)
}

@MainActor
@Test func selectingMonthUpdatesYearAndMonthTogether() {
    let router = CalendarRouter(selectedRoute: .lunarYear(2024))

    router.selectMonth(lunarYearNumber: 2025, monthIndex: 25006)

    #expect(router.currentRoute(on: .years) == .lunarYear(2025))
    #expect(router.selectedMonthIndex == 25006)
}

@MainActor
@Test func todaySelectionReturnsToPreferredYearAndClearsMonth() {
    let router = CalendarRouter(selectedRoute: .lunarYear(2024), selectedMonthIndex: 24001)

    router.selectToday(preferredYearNumber: 2026)

    #expect(router.currentRoute(on: .years) == .lunarYear(2026))
    #expect(router.selectedMonthIndex == nil)
}

@MainActor
@Test func yearPickerSelectionDismissesPicker() {
    let router = CalendarRouter()

    router.presentYearPicker()
    router.selectYearFromPicker(2026)

    #expect(router.isYearPickerPresented == false)
    #expect(router.currentRoute(on: .years) == .lunarYear(2026))
}

@MainActor
@Test func adjacentYearSelectionUsesAvailableYearNumbers() {
    let router = CalendarRouter(selectedRoute: .lunarYear(2025))
    let years = [2024, 2025, 2026]

    router.selectPreviousYear(availableYearNumbers: years)
    #expect(router.currentRoute(on: .years) == .lunarYear(2024))

    router.selectNextYear(availableYearNumbers: years)
    #expect(router.currentRoute(on: .years) == .lunarYear(2025))
}

@MainActor
@Test func rootPresentationCreatesPresentationNode() {
    let router = CalendarRouter()

    router.presentSheet(.lunarYear(2025))
    router.presentFullScreen(.lunarYear(2026))

    #expect(router.sheet?.route == .lunarYear(2025))
    #expect(router.sheet?.path.isEmpty == true)
    #expect(router.fullScreen?.route == .lunarYear(2026))
    #expect(router.fullScreen?.path.isEmpty == true)
}

@MainActor
@Test func routeIdentityIsIndependentFromPresentationStyle() {
    let router = CalendarRouter()

    router.selectYear(2025)
    router.presentSheet(.lunarYear(2025))

    #expect(router.currentRoute(on: .years) == router.sheet?.route)
}

@MainActor
@Test func presentedNodeCanPushInsideItsOwnNavigationStack() {
    let router = CalendarRouter()
    router.presentSheet(.lunarYear(2025))

    let sheet = router.sheet
    sheet?.push(.lunarYear(2026))

    #expect(router.yearsPath.isEmpty)
    #expect(sheet?.path == [.lunarYear(2026)])
}

@MainActor
@Test func closingNestedSheetReturnsToParentSheet() throws {
    let router = CalendarRouter()
    router.presentSheet(.lunarYear(2025))
    let parentSheet = try #require(router.sheet)

    parentSheet.presentSheet(.lunarYear(2026))
    parentSheet.dismissSheet()

    #expect(router.sheet === parentSheet)
    #expect(router.sheet?.route == .lunarYear(2025))
    #expect(parentSheet.sheet == nil)
}

@MainActor
@Test func hotDeepLinkDismissesActivePresentationTreeBeforeRouting() {
    let router = CalendarRouter(selectedRoute: .lunarYear(2024))
    router.presentSheet(.lunarYear(2025))

    router.openDeepLink(.lunarYear(2026, monthIndex: 26001))

    #expect(router.sheet == nil)
    #expect(router.deferredDeepLink == .lunarYear(2026, monthIndex: 26001))
    #expect(router.currentRoute(on: .years) == .lunarYear(2024))

    router.applyDeferredDeepLinkIfReady()

    #expect(router.deferredDeepLink == nil)
    #expect(router.currentRoute(on: .years) == .lunarYear(2026))
    #expect(router.selectedMonthIndex == 26001)
}

@MainActor
@Test func coldLaunchDeepLinkAppliesImmediately() {
    let router = CalendarRouter()

    router.openColdLaunchDeepLink(.lunarYear(2026, monthIndex: 26001))

    #expect(router.deferredDeepLink == nil)
    #expect(router.currentRoute(on: .years) == .lunarYear(2026))
    #expect(router.selectedMonthIndex == 26001)
}

@MainActor
@Test func dynastyDeepLinkSelectsHistoryTab() {
    let router = CalendarRouter()

    router.openColdLaunchDeepLink(.dynasty("qin"))

    #expect(router.selectedTab == .history)
    #expect(router.historyPath == [.dynasty("qin")])
    #expect(router.selectedMonthIndex == nil)
}

@MainActor
@Test func defaultSelectionDoesNotOverrideDynastyDeepLink() {
    let router = CalendarRouter()

    router.openColdLaunchDeepLink(.dynasty("ming"))
    let selectedYear = router.selectDefaultYearIfNeeded(
        availableYearNumbers: [2024, 2025, 2026],
        preferredYearNumber: 2025
    )

    #expect(selectedYear == nil)
    #expect(router.selectedTab == .history)
    #expect(router.historyPath == [.dynasty("ming")])
}

@MainActor
@Test func emperorDeepLinkSelectsHistoryTab() {
    let router = CalendarRouter()

    router.openColdLaunchDeepLink(.emperor("ming-taizu"))

    #expect(router.selectedTab == .history)
    #expect(router.historyPath == [.emperor("ming-taizu")])
    #expect(router.selectedMonthIndex == nil)
}

@Test func parserSupportsYearURLs() throws {
    let url = try #require(URL(string: "chinesecalendar://year/2026?monthIndex=26001"))

    #expect(CalendarDeepLinkParser.deepLink(from: url) == .lunarYear(2026, monthIndex: 26001))
}

@Test func parserSupportsDynastyURLs() throws {
    let url = try #require(URL(string: "chinesecalendar://dynasty/qin"))

    #expect(CalendarDeepLinkParser.deepLink(from: url) == .dynasty("qin"))
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
