import ChineseCalendarPersistence
import SwiftUI

#Preview("四种日期状态") {
    let day = ChineseLunarDay(
        dayIndex: 0,
        lunarMonthIndex: 0,
        dayNumberInMonth: 4,
        dayStemIndex: 8,
        dayBranchIndex: 10,
        calendarDay: CalendarDay(
            dayIndex: 0,
            julianDayNumber: 0,
            civilDate: CivilDate(
                dayIndex: 0,
                year: 2026,
                month: 8,
                dayOfMonth: 16,
                calendarStyle: .gregorian
            )
        )
    )

    Grid(horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
            Text("普通")
            Text("选中")
            Text("今天")
            Text("今天且选中")
        }
        .font(.caption)
        .foregroundStyle(.secondary)

        GridRow {
            LunarDayGridCell(day: day, isSelected: false, isToday: false)
            LunarDayGridCell(day: day, isSelected: true, isToday: false)
            LunarDayGridCell(day: day, isSelected: false, isToday: true)
            LunarDayGridCell(day: day, isSelected: true, isToday: true)
        }
    }
    .padding()
}
