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
@Test func changingSelectedYearClearsSelectedMonth() {
    let router = CalendarRouter(selectedRoute: .lunarYear(2024), selectedMonthIndex: 24001)

    router.selectYear(2025)

    #expect(router.selectedRoute == .lunarYear(2025))
    #expect(router.selectedMonthIndex == nil)
}

@MainActor
@Test func adjacentYearSelectionUsesAvailableYearNumbers() {
    let router = CalendarRouter(selectedRoute: .lunarYear(2025))
    let years = [2024, 2025, 2026]

    router.selectPreviousYear(availableYearNumbers: years)
    #expect(router.selectedRoute == .lunarYear(2024))

    router.selectNextYear(availableYearNumbers: years)
    #expect(router.selectedRoute == .lunarYear(2025))
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

    #expect(router.selectedRoute == router.sheet?.route)
}

@MainActor
@Test func presentedNodeCanPushInsideItsOwnNavigationStack() {
    let router = CalendarRouter()
    router.presentSheet(.lunarYear(2025))

    let sheet = router.sheet
    sheet?.push(.lunarYear(2026))

    #expect(router.selectedRoute == nil)
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
    #expect(router.selectedRoute == .lunarYear(2024))

    router.applyDeferredDeepLinkIfReady()

    #expect(router.deferredDeepLink == nil)
    #expect(router.selectedRoute == .lunarYear(2026))
    #expect(router.selectedMonthIndex == 26001)
}

@MainActor
@Test func coldLaunchDeepLinkAppliesImmediately() {
    let router = CalendarRouter()

    router.openColdLaunchDeepLink(.lunarYear(2026, monthIndex: 26001))

    #expect(router.deferredDeepLink == nil)
    #expect(router.selectedRoute == .lunarYear(2026))
    #expect(router.selectedMonthIndex == 26001)
}

@Test func parserSupportsYearURLs() throws {
    let url = try #require(URL(string: "chinesecalendar://year/2026?monthIndex=26001"))

    #expect(CalendarDeepLinkParser.deepLink(from: url) == .lunarYear(2026, monthIndex: 26001))
}

@Test func parserSupportsLaunchArguments() {
    let deepLink = CalendarDeepLinkParser.deepLink(from: [
        "ChineseCalendar",
        "--deep-link",
        "chinese-calendar://2026?month=26001"
    ])

    #expect(deepLink == .lunarYear(2026, monthIndex: 26001))
}
