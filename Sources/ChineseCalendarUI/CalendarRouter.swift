import Foundation
import Observation

@MainActor
@Observable
final class CalendarRouter {
    var selectedTab: CalendarTab
    var yearsPath: [CalendarRoute] {
        didSet {
            clearSelectedMonthIfSelectedYearChanged(from: oldValue, to: yearsPath)
        }
    }

    var historyPath: [CalendarRoute]
    var selectedMonthIndex: Int?
    var sheet: CalendarPresentationNode?
    var fullScreen: CalendarPresentationNode?
    private(set) var deferredDeepLink: CalendarDeepLink?

    var selectedRoute: CalendarRoute? {
        get { currentRoute(on: selectedTab) }
        set {
            if let newValue {
                setPath([newValue], for: selectedTab)
            } else {
                setPath([], for: selectedTab)
            }
        }
    }

    var selectedYearNumber: Int? {
        currentRoute(on: .years)?.lunarYearNumber
    }

    var hasActivePresentation: Bool {
        sheet != nil || fullScreen != nil
    }

    init(
        selectedTab: CalendarTab = .years,
        selectedRoute: CalendarRoute? = nil,
        yearsPath: [CalendarRoute]? = nil,
        historyPath: [CalendarRoute] = [],
        selectedMonthIndex: Int? = nil
    ) {
        self.selectedTab = selectedTab
        self.yearsPath = yearsPath ?? selectedRoute.map { [$0] } ?? []
        self.historyPath = historyPath
        self.selectedMonthIndex = selectedMonthIndex
    }

    func path(for tab: CalendarTab) -> [CalendarRoute] {
        switch tab {
        case .years:
            yearsPath
        case .history:
            historyPath
        }
    }

    func setPath(_ path: [CalendarRoute], for tab: CalendarTab) {
        switch tab {
        case .years:
            yearsPath = path
        case .history:
            historyPath = path
        }
    }

    func currentRoute(on tab: CalendarTab) -> CalendarRoute? {
        path(for: tab).last
    }

    func push(_ route: CalendarRoute, on tab: CalendarTab? = nil) {
        let targetTab = tab ?? selectedTab
        selectedTab = targetTab
        var path = path(for: targetTab)
        path.append(route)
        setPath(path, for: targetTab)
    }

    func selectYear(_ yearNumber: Int, monthIndex: Int? = nil) {
        selectedTab = .years
        setPath([.lunarYear(yearNumber)], for: .years)
        selectedMonthIndex = monthIndex
    }

    func selectDefaultYearIfNeeded(availableYearNumbers yearNumbers: [Int], preferredYearNumber: Int) -> Int? {
        guard !yearNumbers.isEmpty else {
            return nil
        }

        if let selectedYearNumber, yearNumbers.contains(selectedYearNumber) {
            return nil
        }

        let defaultYearNumber = yearNumbers.first { $0 == preferredYearNumber } ?? yearNumbers.last
        guard let defaultYearNumber else {
            return nil
        }

        selectYear(defaultYearNumber)
        return defaultYearNumber
    }

    func canSelectPreviousYear(availableYearNumbers yearNumbers: [Int]) -> Bool {
        guard let selectedYearIndex = selectedYearIndex(in: yearNumbers) else {
            return false
        }

        return selectedYearIndex > yearNumbers.startIndex
    }

    func canSelectNextYear(availableYearNumbers yearNumbers: [Int]) -> Bool {
        guard let selectedYearIndex = selectedYearIndex(in: yearNumbers) else {
            return false
        }

        return selectedYearIndex < yearNumbers.index(before: yearNumbers.endIndex)
    }

    func selectPreviousYear(availableYearNumbers yearNumbers: [Int]) {
        guard let selectedYearIndex = selectedYearIndex(in: yearNumbers),
              selectedYearIndex > yearNumbers.startIndex
        else {
            return
        }

        selectYear(yearNumbers[yearNumbers.index(before: selectedYearIndex)])
    }

    func selectNextYear(availableYearNumbers yearNumbers: [Int]) {
        guard let selectedYearIndex = selectedYearIndex(in: yearNumbers),
              selectedYearIndex < yearNumbers.index(before: yearNumbers.endIndex)
        else {
            return
        }

        selectYear(yearNumbers[yearNumbers.index(after: selectedYearIndex)])
    }

    func presentSheet(_ route: CalendarRoute) {
        sheet = CalendarPresentationNode(route: route)
    }

    func presentFullScreen(_ route: CalendarRoute) {
        fullScreen = CalendarPresentationNode(route: route)
    }

    func dismissSheet() {
        sheet = nil
    }

    func dismissFullScreen() {
        fullScreen = nil
    }

    func openDeepLink(_ deepLink: CalendarDeepLink) {
        if hasActivePresentation {
            deferredDeepLink = deepLink
            sheet = nil
            fullScreen = nil
            return
        }

        apply(deepLink)
    }

    func openColdLaunchDeepLink(_ deepLink: CalendarDeepLink?) {
        guard let deepLink else {
            return
        }

        apply(deepLink)
    }

    func applyDeferredDeepLinkIfReady() {
        guard !hasActivePresentation, let deferredDeepLink else {
            return
        }

        self.deferredDeepLink = nil
        apply(deferredDeepLink)
    }

    private func selectedYearIndex(in yearNumbers: [Int]) -> [Int].Index? {
        guard let selectedYearNumber else {
            return nil
        }

        return yearNumbers.firstIndex(of: selectedYearNumber)
    }

    private func apply(_ deepLink: CalendarDeepLink) {
        switch deepLink {
        case let .lunarYear(yearNumber, monthIndex):
            selectYear(yearNumber, monthIndex: monthIndex)
        case let .dynasty(dynastyID):
            selectedTab = .history
            setPath([.dynasty(dynastyID)], for: .history)
            selectedMonthIndex = nil
        }
    }

    private func clearSelectedMonthIfSelectedYearChanged(from oldPath: [CalendarRoute], to newPath: [CalendarRoute]) {
        guard oldPath.last?.lunarYearNumber != newPath.last?.lunarYearNumber else {
            return
        }

        selectedMonthIndex = nil
    }
}

@MainActor
@Observable
final class CalendarPresentationNode: Identifiable {
    let id = UUID()
    let route: CalendarRoute
    var path: [CalendarRoute]
    var selectedMonthIndex: Int?
    var sheet: CalendarPresentationNode?
    var fullScreen: CalendarPresentationNode?

    init(route: CalendarRoute, path: [CalendarRoute] = [], selectedMonthIndex: Int? = nil) {
        self.route = route
        self.path = path
        self.selectedMonthIndex = selectedMonthIndex
    }

    func push(_ route: CalendarRoute) {
        path.append(route)
    }

    func presentSheet(_ route: CalendarRoute) {
        sheet = CalendarPresentationNode(route: route)
    }

    func presentFullScreen(_ route: CalendarRoute) {
        fullScreen = CalendarPresentationNode(route: route)
    }

    func dismissSheet() {
        sheet = nil
    }

    func dismissFullScreen() {
        fullScreen = nil
    }
}
