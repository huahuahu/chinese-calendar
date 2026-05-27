import ChineseCalendarCore
import Observation
import SwiftUI

@MainActor
@Observable
public final class CalendarAppState {
    public enum Route: Hashable, Sendable {
        case lunarYear(Int)
    }

    public var columnVisibility: NavigationSplitViewVisibility
    public var route: Route? {
        didSet {
            guard route != oldValue else {
                return
            }

            selectedMonthIndex = nil
        }
    }

    public var selectedMonthIndex: Int?

    public init(
        route: Route? = nil,
        selectedMonthIndex: Int? = nil,
        columnVisibility: NavigationSplitViewVisibility = .automatic
    ) {
        self.route = route
        self.selectedMonthIndex = selectedMonthIndex
        self.columnVisibility = columnVisibility
    }

    public var selectedYearNumber: Int? {
        get {
            guard case let .lunarYear(yearNumber) = route else {
                return nil
            }

            return yearNumber
        }
        set {
            route = newValue.map(Route.lunarYear)
        }
    }

    @discardableResult
    public func selectDefaultYearIfNeeded(
        from yearNumbers: [Int],
        fallbackYearNumber: Int = ChineseLunarCalendar.yearNumber()
    ) -> Int? {
        guard !yearNumbers.isEmpty else {
            return nil
        }

        if let selectedYearNumber, yearNumbers.contains(selectedYearNumber) {
            return nil
        }

        guard let defaultYearNumber = yearNumbers.first(where: { $0 == fallbackYearNumber }) ?? yearNumbers.last else {
            return nil
        }

        selectedYearNumber = defaultYearNumber
        return defaultYearNumber
    }

    public func canSelectPreviousYear(in yearNumbers: [Int]) -> Bool {
        guard let selectedYearIndex = selectedYearIndex(in: yearNumbers) else {
            return false
        }

        return selectedYearIndex > yearNumbers.startIndex
    }

    public func canSelectNextYear(in yearNumbers: [Int]) -> Bool {
        guard let selectedYearIndex = selectedYearIndex(in: yearNumbers) else {
            return false
        }

        return selectedYearIndex < yearNumbers.index(before: yearNumbers.endIndex)
    }

    public func selectPreviousYear(in yearNumbers: [Int]) {
        guard let selectedYearIndex = selectedYearIndex(in: yearNumbers),
              selectedYearIndex > yearNumbers.startIndex
        else {
            return
        }

        selectedYearNumber = yearNumbers[yearNumbers.index(before: selectedYearIndex)]
    }

    public func selectNextYear(in yearNumbers: [Int]) {
        guard let selectedYearIndex = selectedYearIndex(in: yearNumbers),
              selectedYearIndex < yearNumbers.index(before: yearNumbers.endIndex)
        else {
            return
        }

        selectedYearNumber = yearNumbers[yearNumbers.index(after: selectedYearIndex)]
    }

    public func selectMonth(index: Int?) {
        selectedMonthIndex = index
    }

    public func selectDefaultMonthIfNeeded(from monthIndexes: [Int]) {
        guard !monthIndexes.isEmpty else {
            selectedMonthIndex = nil
            return
        }

        guard monthIndexes.contains(where: { $0 == selectedMonthIndex }) == false else {
            return
        }

        selectedMonthIndex = monthIndexes.first
    }

    public func canSelectPreviousMonth(in monthIndexes: [Int]) -> Bool {
        guard let selectedMonthIndex = selectedMonthIndex(in: monthIndexes) else {
            return false
        }

        return selectedMonthIndex > monthIndexes.startIndex
    }

    public func canSelectNextMonth(in monthIndexes: [Int]) -> Bool {
        guard let selectedMonthIndex = selectedMonthIndex(in: monthIndexes) else {
            return false
        }

        return selectedMonthIndex < monthIndexes.index(before: monthIndexes.endIndex)
    }

    public func selectPreviousMonth(in monthIndexes: [Int]) {
        guard let selectedMonthIndex = selectedMonthIndex(in: monthIndexes),
              selectedMonthIndex > monthIndexes.startIndex
        else {
            return
        }

        self.selectedMonthIndex = monthIndexes[monthIndexes.index(before: selectedMonthIndex)]
    }

    public func selectNextMonth(in monthIndexes: [Int]) {
        guard let selectedMonthIndex = selectedMonthIndex(in: monthIndexes),
              selectedMonthIndex < monthIndexes.index(before: monthIndexes.endIndex)
        else {
            return
        }

        self.selectedMonthIndex = monthIndexes[monthIndexes.index(after: selectedMonthIndex)]
    }

    private func selectedYearIndex(in yearNumbers: [Int]) -> [Int].Index? {
        guard let selectedYearNumber else {
            return nil
        }

        return yearNumbers.firstIndex(of: selectedYearNumber)
    }

    private func selectedMonthIndex(in monthIndexes: [Int]) -> [Int].Index? {
        guard let selectedMonthIndex else {
            return nil
        }

        return monthIndexes.firstIndex(of: selectedMonthIndex)
    }
}
