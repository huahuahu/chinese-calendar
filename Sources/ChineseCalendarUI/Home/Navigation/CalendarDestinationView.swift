import SFSafeSymbols
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

/// 承载允许尚未选择 CalendarDestination 的根页面，并在未选择时显示空状态。
struct CalendarDestinationRootView: View {
    let destination: CalendarDestination?
    let emptyStateDescription: String

    var body: some View {
        Group {
            if let destination {
                CalendarDestinationView(destination: destination)
            } else {
                ContentUnavailableView {
                    Label("Chinese Calendar", systemSymbol: .calendar)
                } description: {
                    Text(emptyStateDescription)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.calendarSystemBackground)
    }
}
