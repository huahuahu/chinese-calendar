import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

struct CalendarRouteDestinationView: View {
    let route: CalendarRoute?
    let year: ChineseLunarYear?
    let months: [ChineseLunarMonth]
    @Binding var selectedMonthIndex: Int?
    let canSelectPreviousYear: Bool
    let canSelectNextYear: Bool
    let selectPreviousYear: () -> Void
    let selectNextYear: () -> Void
    let showYearPicker: (() -> Void)?
    let selectMonth: ((ChineseLunarMonth) -> Void)?
    let selectToday: (() -> Void)?
    let bottomStatusBarIsPresented: Bool
    let emptyStateDescription: String

    init(
        route: CalendarRoute?,
        year: ChineseLunarYear?,
        months: [ChineseLunarMonth] = [],
        selectedMonthIndex: Binding<Int?>,
        canSelectPreviousYear: Bool,
        canSelectNextYear: Bool,
        selectPreviousYear: @escaping () -> Void,
        selectNextYear: @escaping () -> Void,
        showYearPicker: (() -> Void)? = nil,
        selectMonth: ((ChineseLunarMonth) -> Void)? = nil,
        selectToday: (() -> Void)? = nil,
        bottomStatusBarIsPresented: Bool = false,
        emptyStateDescription: String
    ) {
        self.route = route
        self.year = year
        self.months = months
        _selectedMonthIndex = selectedMonthIndex
        self.canSelectPreviousYear = canSelectPreviousYear
        self.canSelectNextYear = canSelectNextYear
        self.selectPreviousYear = selectPreviousYear
        self.selectNextYear = selectNextYear
        self.showYearPicker = showYearPicker
        self.selectMonth = selectMonth
        self.selectToday = selectToday
        self.bottomStatusBarIsPresented = bottomStatusBarIsPresented
        self.emptyStateDescription = emptyStateDescription
    }

    var body: some View {
        Group {
            switch route {
            case .lunarYear:
                if let year {
                    LunarYearDetailView(
                        year: year,
                        calendarMonths: months,
                        selectedMonthIndex: $selectedMonthIndex,
                        canSelectPreviousYear: canSelectPreviousYear,
                        canSelectNextYear: canSelectNextYear,
                        selectPreviousYear: selectPreviousYear,
                        selectNextYear: selectNextYear,
                        showYearPicker: showYearPicker,
                        selectMonth: selectMonth,
                        selectToday: selectToday,
                        bottomStatusBarIsPresented: bottomStatusBarIsPresented
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.calendarSystemBackground)
    }
}
