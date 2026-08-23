@testable import ChineseCalendarUI
import Foundation
import Testing

@MainActor
@Test func defaultSelectionPrefersCurrentLunarYearWhenAvailable() {
    let coordinator = CalendarHomeCoordinator()

    let selectedYear = coordinator.selectDefaultYearIfNeeded(
        availableYearNumbers: [2024, 2025, 2026],
        preferredYearNumber: 2025
    )

    #expect(selectedYear == 2025)
    #expect(coordinator.router.selectedDestination == .lunarYear(2025))
    #expect(coordinator.router.yearsRootDestination == .lunarYear(2025))
    #expect(coordinator.router.yearsPath.isEmpty)
}

@MainActor
@Test func defaultSelectionKeepsExistingValidRoute() {
    let router = CalendarRouter(yearsRootDestination: .lunarYear(2024))
    let coordinator = CalendarHomeCoordinator(router: router)

    let selectedYear = coordinator.selectDefaultYearIfNeeded(
        availableYearNumbers: [2024, 2025, 2026],
        preferredYearNumber: 2025
    )

    #expect(selectedYear == nil)
    #expect(router.selectedDestination == .lunarYear(2024))
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

    router.setYearsRootDestination(.lunarYear(2024))
    router.push(.lunarYear(2025), on: .years)
    router.push(.dynasty("qin"), on: .history)

    #expect(router.yearsRootDestination == .lunarYear(2024))
    #expect(router.yearsPath == [.lunarYear(2025)])
    #expect(router.historyPath == [.dynasty("qin")])
    #expect(router.selectedDestination == .dynasty("qin"))
    #expect(router.currentDestination(on: .years) == .lunarYear(2025))
}

@MainActor
@Test func changingYearsRootClearsItsPushPath() {
    let router = CalendarRouter(
        yearsRootDestination: .lunarYear(2024),
        yearsPath: [.lunarYear(2025)]
    )

    router.setYearsRootDestination(.lunarYear(2026))

    #expect(router.yearsRootDestination == .lunarYear(2026))
    #expect(router.yearsPath.isEmpty)
    #expect(router.currentDestination(on: .years) == .lunarYear(2026))
}

@MainActor
@Test func browseStateTreatsYearMonthAndDayAsPageState() {
    let browseState = LunarCalendarBrowseState(
        displayedYearNumber: 2024,
        selectedMonthIndex: 24001,
        selectedDayIndex: 2_400_101
    )

    browseState.selectYear(2025)

    #expect(browseState.displayedYearNumber == 2025)
    #expect(browseState.yearTransitionDirection == .later)
    #expect(browseState.selectedMonthIndex == nil)
    #expect(browseState.daySelection.dayIndex == nil)
}

@MainActor
@Test func browseStateCanMoveAcrossYearsWithoutChangingRouter() {
    let router = CalendarRouter(yearsRootDestination: .lunarYear(2024))
    let browseState = LunarCalendarBrowseState(
        displayedYearNumber: 2024,
        selectedDayIndex: 2_400_101
    )

    browseState.select(yearNumber: 2025, monthIndex: 25006)

    #expect(router.currentDestination(on: .years) == .lunarYear(2024))
    #expect(browseState.displayedYearNumber == 2025)
    #expect(browseState.yearTransitionDirection == .later)
    #expect(browseState.selectedMonthIndex == 25006)
    #expect(browseState.daySelection.dayIndex == nil)
}

@MainActor
@Test func browseStateCanSelectAnExactDay() {
    let browseState = LunarCalendarBrowseState(
        displayedYearNumber: 2024,
        selectedMonthIndex: 24001,
        selectedDayIndex: 2_400_101
    )

    browseState.select(
        yearNumber: 2026,
        monthIndex: 26005,
        dayIndex: 2_600_512
    )

    #expect(browseState.displayedYearNumber == 2026)
    #expect(browseState.yearTransitionDirection == .later)
    #expect(browseState.selectedMonthIndex == 26005)
    #expect(browseState.daySelection.dayIndex == 2_600_512)
}

@MainActor
@Test func browseStateTracksDirectionForEveryYearChangingSelection() {
    let browseState = LunarCalendarBrowseState(displayedYearNumber: 2026)
    let transitionContext = browseState.yearTransitionContext

    browseState.select(yearNumber: 2025, monthIndex: 25012)
    #expect(browseState.yearTransitionDirection == .earlier)
    #expect(browseState.yearTransitionContext === transitionContext)

    browseState.select(
        yearNumber: 2027,
        monthIndex: 27001,
        dayIndex: 2_700_101
    )
    #expect(browseState.yearTransitionDirection == .later)
    #expect(browseState.yearTransitionContext === transitionContext)
}

@MainActor
@Test func sameYearMonthSelectionKeepsTheLastYearTransitionDirection() {
    let browseState = LunarCalendarBrowseState(displayedYearNumber: 2026)
    browseState.selectYear(2025)

    browseState.select(yearNumber: 2025, monthIndex: 25006)

    #expect(browseState.yearTransitionDirection == .earlier)
}

@MainActor
@Test func browseStateClearsItsDaySelectionWhenMonthChanges() {
    let browseState = LunarCalendarBrowseState(
        displayedYearNumber: 2026,
        selectedMonthIndex: 26005,
        selectedDayIndex: 2_600_501
    )

    browseState.selectedMonthIndex = 26006

    #expect(browseState.daySelection.dayIndex == nil)
}

@MainActor
@Test func yearPickerDestinationReturnsSelectionToItsPresenter() throws {
    let router = CalendarRouter()
    var selectedYearNumber: Int?
    let yearPicker = CalendarYearPickerDestination(
        initialYearNumber: 2026,
        onSelect: { selectedYearNumber = $0 }
    )

    router.presentSheet(.yearPicker(yearPicker))
    let presentation = try #require(router.sheet)
    guard case let .yearPicker(presentedYearPicker) = presentation.destination else {
        Issue.record("Expected a year picker destination")
        return
    }
    presentedYearPicker.select(2025)

    #expect(presentedYearPicker.id == yearPicker.id)
    #expect(presentedYearPicker.initialYearNumber == 2026)
    #expect(selectedYearNumber == 2025)
}

@MainActor
@Test func yearPickerIsNestedUnderAnActivePresentation() throws {
    let router = CalendarRouter()
    router.presentSheet(.lunarYear(2025))
    let parentSheet = try #require(router.sheet)

    let yearPicker = CalendarYearPickerDestination(initialYearNumber: 2025) { _ in }
    router.presentSheet(.yearPicker(yearPicker))

    #expect(router.sheet === parentSheet)
    #expect(parentSheet.sheet?.destination == .yearPicker(yearPicker))
}

@MainActor
@Test func hotDeepLinkDismissesActivePresentationTreeBeforeRouting() {
    let router = CalendarRouter(yearsRootDestination: .lunarYear(2024))
    let coordinator = CalendarHomeCoordinator(router: router)
    router.presentSheet(.lunarYear(2025))

    coordinator.openDeepLink(.lunarYear(2026, monthIndex: 26001))

    #expect(router.sheet == nil)
    #expect(
        router.navigation.deferredRequest
            == .setRoot(.lunarYear(2026, monthIndex: 26001), on: .years)
    )
    #expect(router.currentDestination(on: .years) == .lunarYear(2024))

    router.navigation.applyDeferredRequestIfReady()

    #expect(router.navigation.deferredRequest == nil)
    #expect(router.currentDestination(on: .years) == .lunarYear(2026, monthIndex: 26001))
    #expect(router.yearsRootDestination == .lunarYear(2026, monthIndex: 26001))
    #expect(router.yearsPath.isEmpty)
}

@MainActor
@Test func coldLaunchDeepLinkAppliesImmediately() {
    let coordinator = CalendarHomeCoordinator()

    coordinator.openColdLaunchDeepLink(.lunarYear(2026, monthIndex: 26001))

    #expect(coordinator.router.navigation.deferredRequest == nil)
    #expect(coordinator.router.yearsRootDestination == .lunarYear(2026, monthIndex: 26001))
    #expect(coordinator.router.yearsPath.isEmpty)
    #expect(
        coordinator.router.currentDestination(on: .years)
            == .lunarYear(2026, monthIndex: 26001)
    )
}

@MainActor
@Test func dynastyDeepLinkSelectsHistoryTab() {
    let coordinator = CalendarHomeCoordinator()

    coordinator.openColdLaunchDeepLink(.dynasty("qin"))

    #expect(coordinator.router.selectedTab == .history)
    #expect(coordinator.router.historyPath == [.dynasty("qin")])
}

@MainActor
@Test func defaultSelectionInitializesYearsRootWithoutOverridingDynastyDeepLink() {
    let coordinator = CalendarHomeCoordinator()

    coordinator.openColdLaunchDeepLink(.dynasty("ming"))
    let selectedYear = coordinator.selectDefaultYearIfNeeded(
        availableYearNumbers: [2024, 2025, 2026],
        preferredYearNumber: 2025
    )

    #expect(selectedYear == 2025)
    #expect(coordinator.router.yearsRootDestination == .lunarYear(2025))
    #expect(coordinator.router.yearsPath.isEmpty)
    #expect(coordinator.router.selectedTab == .history)
    #expect(coordinator.router.historyPath == [.dynasty("ming")])
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
