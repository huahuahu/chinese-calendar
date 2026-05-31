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
    let openSettings: (() -> Void)?

    init(
        route: CalendarRoute?,
        year: ChineseLunarYear?,
        selectedMonthIndex: Binding<Int?>,
        canSelectPreviousYear: Bool,
        canSelectNextYear: Bool,
        selectPreviousYear: @escaping () -> Void,
        selectNextYear: @escaping () -> Void,
        emptyStateDescription: String,
        openSettings: (() -> Void)? = nil
    ) {
        self.route = route
        self.year = year
        _selectedMonthIndex = selectedMonthIndex
        self.canSelectPreviousYear = canSelectPreviousYear
        self.canSelectNextYear = canSelectNextYear
        self.selectPreviousYear = selectPreviousYear
        self.selectNextYear = selectNextYear
        self.emptyStateDescription = emptyStateDescription
        self.openSettings = openSettings
    }

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
                        selectNextYear: selectNextYear,
                        openSettings: openSettings
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
