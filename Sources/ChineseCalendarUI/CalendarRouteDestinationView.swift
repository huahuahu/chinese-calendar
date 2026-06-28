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

    init(
        route: CalendarRoute?,
        year: ChineseLunarYear?,
        selectedMonthIndex: Binding<Int?>,
        canSelectPreviousYear: Bool,
        canSelectNextYear: Bool,
        selectPreviousYear: @escaping () -> Void,
        selectNextYear: @escaping () -> Void,
        emptyStateDescription: String
    ) {
        self.route = route
        self.year = year
        _selectedMonthIndex = selectedMonthIndex
        self.canSelectPreviousYear = canSelectPreviousYear
        self.canSelectNextYear = canSelectNextYear
        self.selectPreviousYear = selectPreviousYear
        self.selectNextYear = selectNextYear
        self.emptyStateDescription = emptyStateDescription
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
                        selectNextYear: selectNextYear
                    )
                } else {
                    ContentUnavailableView {
                        Label("Chinese Calendar", systemImage: "calendar.badge.exclamationmark")
                    } description: {
                        Text("没有找到这个农历年。")
                    }
                }
            case let .dynasty(dynastyID):
                DynastyDetailView(dynastyID: dynastyID)
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
