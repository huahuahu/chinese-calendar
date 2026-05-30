import ChineseCalendarPersistence
import SwiftUI

struct CalendarRouteDestinationView: View {
    let route: CalendarRoute?
    let year: ChineseLunarYear?
    @Binding var selectedMonthIndex: Int?
    let canSelectPreviousYear: Bool
    let canSelectNextYear: Bool
    let selectPreviousYear: () -> Void
    let selectNextYear: () -> Void
    let emptyStateDescription: String

    var body: some View {
        Group {
            switch route {
            case .lunarYear:
                if let year {
                    LunarYearDetailView(
                        year: year,
                        selectedMonthIndex: $selectedMonthIndex,
                        canSelectPreviousYear: canSelectPreviousYear,
                        canSelectNextYear: canSelectNextYear,
                        selectPreviousYear: selectPreviousYear,
                        selectNextYear: selectNextYear
                    )
                } else {
                    ContentUnavailableView {
                        Label("Chinese Calendar", systemImage: "calendar.badge.exclamationmark")
                    } description: {
                        Text("没有找到这个农历年。")
                    }
                }
            case nil:
                ContentUnavailableView {
                    Label("Chinese Calendar", systemImage: "calendar")
                } description: {
                    Text(emptyStateDescription)
                }
            }
        }
    }
}
