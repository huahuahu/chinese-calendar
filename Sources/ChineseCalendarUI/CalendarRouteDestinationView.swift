import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

struct CalendarRouteDestinationView: View {
    let route: CalendarRoute?
    let year: ChineseLunarYear?
    @Binding var selectedMonthIndex: Int?
    let canSelectPreviousYear: Bool
    let canSelectNextYear: Bool
    let selectPreviousYear: () -> Void
    let selectNextYear: () -> Void
    let showYearList: (() -> Void)?
    let emptyStateDescription: String

    init(
        route: CalendarRoute?,
        year: ChineseLunarYear?,
        selectedMonthIndex: Binding<Int?>,
        canSelectPreviousYear: Bool,
        canSelectNextYear: Bool,
        selectPreviousYear: @escaping () -> Void,
        selectNextYear: @escaping () -> Void,
        showYearList: (() -> Void)? = nil,
        emptyStateDescription: String
    ) {
        self.route = route
        self.year = year
        _selectedMonthIndex = selectedMonthIndex
        self.canSelectPreviousYear = canSelectPreviousYear
        self.canSelectNextYear = canSelectNextYear
        self.selectPreviousYear = selectPreviousYear
        self.selectNextYear = selectNextYear
        self.showYearList = showYearList
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
                        selectNextYear: selectNextYear,
                        showYearList: showYearList
                    )
                } else {
                    ContentUnavailableView {
                        Label("Chinese Calendar", systemSymbol: .calendarBadgeExclamationmark)
                    } description: {
                        Text("没有找到这个农历年。")
                    }
                }
            case let .dynasty(dynastyID):
                DynastyDetailView(dynastyID: dynastyID)
            case let .emperor(emperorID):
                EmperorDetailView(emperorID: emperorID)
            case nil:
                ContentUnavailableView {
                    Label("Chinese Calendar", systemSymbol: .calendar)
                } description: {
                    Text(emptyStateDescription)
                }
            }
        }
    }
}
