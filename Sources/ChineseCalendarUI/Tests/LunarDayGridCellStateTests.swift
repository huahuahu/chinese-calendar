@testable import ChineseCalendarUI
import Testing

@Test(
    "日期格状态由今天和选中组合唯一确定",
    arguments: [
        (false, false, LunarDayGridCellState.normal),
        (false, true, LunarDayGridCellState.selected),
        (true, false, LunarDayGridCellState.today),
        (true, true, LunarDayGridCellState.todaySelected)
    ]
)
func lunarDayGridCellStateMapping(
    isToday: Bool,
    isSelected: Bool,
    expectedState: LunarDayGridCellState
) {
    #expect(LunarDayGridCellState(isToday: isToday, isSelected: isSelected) == expectedState)
}
