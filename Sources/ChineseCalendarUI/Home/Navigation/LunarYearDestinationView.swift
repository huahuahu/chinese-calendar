import SwiftUI

/// 把年份 destination 的可选月、日地址转换为一次性的页面初始落点。
struct LunarYearDestinationView: View {
    @State private var browseState: LunarCalendarBrowseState

    init(
        yearNumber: Int,
        monthIndex: Int? = nil,
        dayIndex: Int? = nil
    ) {
        let browseState = LunarCalendarBrowseState(displayedYearNumber: yearNumber)
        browseState.applyInitialLanding(monthIndex: monthIndex, dayIndex: dayIndex)
        _browseState = State(initialValue: browseState)
    }

    var body: some View {
        LunarYearDetailView(
            yearNumber: browseState.displayedYearNumber,
            browseState: browseState
        )
    }
}
