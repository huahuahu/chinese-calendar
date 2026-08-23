import Observation

/// 保存农历年详情页当前浏览的年、月与日，不参与应用导航。
@MainActor
@Observable
final class LunarCalendarBrowseState {
    private(set) var displayedYearNumber: Int
    private(set) var yearTransitionDirection = LunarYearTransitionDirection.later
    var selectedMonthIndex: Int? {
        didSet {
            guard oldValue != selectedMonthIndex else {
                return
            }

            daySelection.dayIndex = nil
        }
    }

    let daySelection: CalendarDaySelection

    init(
        displayedYearNumber: Int,
        selectedMonthIndex: Int? = nil,
        selectedDayIndex: Int? = nil
    ) {
        self.displayedYearNumber = displayedYearNumber
        self.selectedMonthIndex = selectedMonthIndex
        daySelection = CalendarDaySelection(dayIndex: selectedDayIndex)
    }

    func selectYear(_ yearNumber: Int) {
        select(yearNumber: yearNumber)
    }

    func select(
        yearNumber: Int,
        monthIndex: Int? = nil,
        dayIndex: Int? = nil
    ) {
        if let direction = LunarYearTransitionDirection(
            from: displayedYearNumber,
            to: yearNumber
        ) {
            yearTransitionDirection = direction
        }

        displayedYearNumber = yearNumber
        select(monthIndex: monthIndex, dayIndex: dayIndex)
    }

    func select(monthIndex: Int?, dayIndex: Int? = nil) {
        selectedMonthIndex = monthIndex
        daySelection.dayIndex = dayIndex
    }

    func clear() {
        select(monthIndex: nil)
    }
}
