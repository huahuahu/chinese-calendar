import SwiftUI

/// 供导航容器使用，将 CalendarDestination 分发到对应页面。
struct CalendarDestinationView: View {
    let destination: CalendarDestination

    var body: some View {
        Group {
            switch destination {
            case let .lunarYear(yearNumber, monthIndex, dayIndex):
                LunarYearDetailView(
                    initialYearNumber: yearNumber,
                    initialMonthIndex: monthIndex,
                    initialDayIndex: dayIndex
                )
                .id(destination)
            case let .dynasty(dynastyID):
                DynastyDetailView(dynastyID: dynastyID)
            case let .emperor(emperorID):
                EmperorDetailView(emperorID: emperorID)
            case let .yearPicker(yearPicker):
                CalendarYearPickerDestinationView(destination: yearPicker)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.calendarSystemBackground)
    }
}
