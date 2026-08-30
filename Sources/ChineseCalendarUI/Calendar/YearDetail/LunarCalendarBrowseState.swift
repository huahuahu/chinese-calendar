import Observation

/// 保存农历年详情页当前浏览的年、月与日，不参与应用导航。
@MainActor
@Observable
final class LunarCalendarBrowseState {
    private(set) var displayedYearNumber: Int
    private var hasAppliedInitialLanding = false
    let yearTransitionContext = LunarYearTransitionContext()
    var yearTransitionDirection: LunarYearTransitionDirection {
        yearTransitionContext.direction
    }

    var selectedMonthIndex: Int? {
        didSet {
            guard oldValue != selectedMonthIndex else {
                return
            }

            daySelection.dayIndex = nil
        }
    }

    let daySelection: CalendarDaySelection

    init(displayedYearNumber: Int) {
        self.displayedYearNumber = displayedYearNumber
        daySelection = CalendarDaySelection()
    }

    /// 只在页面首次进入时应用导航地址，避免 View 重建覆盖后续浏览状态。
    func applyInitialLanding(
        monthIndex: Int?,
        dayIndex: Int?
    ) {
        guard !hasAppliedInitialLanding else {
            return
        }

        hasAppliedInitialLanding = true
        select(monthIndex: monthIndex, dayIndex: dayIndex)
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
            yearTransitionContext.direction = direction
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
