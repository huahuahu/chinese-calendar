import ChineseCalendarCore
import Observation

@MainActor
@Observable
public final class LunarSelectionState {
    public var selectedYearNumber: Int? {
        didSet {
            guard selectedYearNumber != oldValue else {
                return
            }

            clearMonthAndDaySelection()
        }
    }

    public var selectedMonthIndex: Int? {
        didSet {
            guard selectedMonthIndex != oldValue else {
                return
            }

            selectedDayIndex = nil
        }
    }

    public var selectedDayIndex: Int?

    public init(
        selectedYearNumber: Int? = nil,
        selectedMonthIndex: Int? = nil,
        selectedDayIndex: Int? = nil
    ) {
        self.selectedYearNumber = selectedYearNumber
        self.selectedMonthIndex = selectedMonthIndex
        self.selectedDayIndex = selectedDayIndex
    }

    public func selectYear(number: Int?) {
        selectedYearNumber = number
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

    public func selectDay(index: Int?) {
        selectedDayIndex = index
    }

    public func selectDefaultDayIfNeeded(from dayIndexes: [Int]) {
        guard !dayIndexes.isEmpty else {
            selectedDayIndex = nil
            return
        }

        guard dayIndexes.contains(where: { $0 == selectedDayIndex }) == false else {
            return
        }

        selectedDayIndex = dayIndexes.first
    }

    public func clearMonthAndDaySelection() {
        selectedMonthIndex = nil
        selectedDayIndex = nil
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
