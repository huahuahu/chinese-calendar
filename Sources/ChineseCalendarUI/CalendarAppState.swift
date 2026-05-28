import ChineseCalendarCore
import Observation
import SwiftUI

@MainActor
@Observable
public final class CalendarAppState {
    public typealias Route = CalendarNavigationState.Route

    public let navigation: CalendarNavigationState
    public let lunarSelection: LunarSelectionState
    public let dynastySelection: DynastySelectionState

    public init(
        navigation: CalendarNavigationState = CalendarNavigationState(),
        lunarSelection: LunarSelectionState = LunarSelectionState(),
        dynastySelection: DynastySelectionState = DynastySelectionState()
    ) {
        self.navigation = navigation
        self.lunarSelection = lunarSelection
        self.dynastySelection = dynastySelection
        synchronizeSelectionsFromRoute()
    }

    public convenience init(
        route: Route? = nil,
        selectedMonthIndex: Int? = nil,
        selectedDayIndex: Int? = nil,
        selectedDynastyID: String? = nil,
        columnVisibility: NavigationSplitViewVisibility = .automatic
    ) {
        self.init(
            navigation: CalendarNavigationState(route: route, columnVisibility: columnVisibility),
            lunarSelection: LunarSelectionState(
                selectedYearNumber: route?.lunarYearNumber,
                selectedMonthIndex: selectedMonthIndex,
                selectedDayIndex: selectedDayIndex
            ),
            dynastySelection: DynastySelectionState(selectedDynastyID: selectedDynastyID ?? route?.dynastyID)
        )
    }

    public var columnVisibility: NavigationSplitViewVisibility {
        get { navigation.columnVisibility }
        set { navigation.columnVisibility = newValue }
    }

    public var route: Route? {
        get { navigation.route }
        set {
            let oldRoute = navigation.route
            navigation.route = newValue

            guard newValue != oldRoute else {
                return
            }

            synchronizeSelectionsFromRoute()
        }
    }

    public var selectedYearNumber: Int? {
        get { lunarSelection.selectedYearNumber }
        set { selectLunarYear(number: newValue) }
    }

    public var selectedMonthIndex: Int? {
        get { lunarSelection.selectedMonthIndex }
        set { lunarSelection.selectMonth(index: newValue) }
    }

    public var selectedDayIndex: Int? {
        get { lunarSelection.selectedDayIndex }
        set { lunarSelection.selectDay(index: newValue) }
    }

    public var selectedDynastyID: String? {
        get { dynastySelection.selectedDynastyID }
        set { selectDynasty(id: newValue) }
    }

    public func selectLunarYear(number: Int?) {
        lunarSelection.selectYear(number: number)
        navigation.route = number.map(Route.lunarYear)
    }

    public func selectDynasty(id: String?) {
        dynastySelection.selectDynasty(id: id)
        navigation.route = id.map(Route.dynasty)
    }

    @discardableResult
    public func selectDefaultYearIfNeeded(
        from yearNumbers: [Int],
        fallbackYearNumber: Int = ChineseLunarCalendar.yearNumber()
    ) -> Int? {
        guard let selectedYearNumber = lunarSelection.selectDefaultYearIfNeeded(
            from: yearNumbers,
            fallbackYearNumber: fallbackYearNumber
        ) else {
            return nil
        }

        if navigation.route?.dynastyID == nil {
            navigation.route = .lunarYear(selectedYearNumber)
        }

        return selectedYearNumber
    }

    public func canSelectPreviousYear(in yearNumbers: [Int]) -> Bool {
        lunarSelection.canSelectPreviousYear(in: yearNumbers)
    }

    public func canSelectNextYear(in yearNumbers: [Int]) -> Bool {
        lunarSelection.canSelectNextYear(in: yearNumbers)
    }

    public func selectPreviousYear(in yearNumbers: [Int]) {
        lunarSelection.selectPreviousYear(in: yearNumbers)
        navigation.route = lunarSelection.selectedYearNumber.map(Route.lunarYear)
    }

    public func selectNextYear(in yearNumbers: [Int]) {
        lunarSelection.selectNextYear(in: yearNumbers)
        navigation.route = lunarSelection.selectedYearNumber.map(Route.lunarYear)
    }

    public func selectMonth(index: Int?) {
        lunarSelection.selectMonth(index: index)
    }

    public func selectDefaultMonthIfNeeded(from monthIndexes: [Int]) {
        lunarSelection.selectDefaultMonthIfNeeded(from: monthIndexes)
    }

    public func canSelectPreviousMonth(in monthIndexes: [Int]) -> Bool {
        lunarSelection.canSelectPreviousMonth(in: monthIndexes)
    }

    public func canSelectNextMonth(in monthIndexes: [Int]) -> Bool {
        lunarSelection.canSelectNextMonth(in: monthIndexes)
    }

    public func selectPreviousMonth(in monthIndexes: [Int]) {
        lunarSelection.selectPreviousMonth(in: monthIndexes)
    }

    public func selectNextMonth(in monthIndexes: [Int]) {
        lunarSelection.selectNextMonth(in: monthIndexes)
    }

    private func synchronizeSelectionsFromRoute() {
        switch navigation.route {
        case let .lunarYear(yearNumber):
            lunarSelection.selectYear(number: yearNumber)
        case let .dynasty(dynastyID):
            dynastySelection.selectDynasty(id: dynastyID)
        case nil:
            lunarSelection.selectYear(number: nil)
        }
    }
}

private extension CalendarNavigationState.Route {
    var lunarYearNumber: Int? {
        guard case let .lunarYear(yearNumber) = self else {
            return nil
        }

        return yearNumber
    }

    var dynastyID: String? {
        guard case let .dynasty(dynastyID) = self else {
            return nil
        }

        return dynastyID
    }
}
