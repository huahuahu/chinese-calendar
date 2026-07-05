import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftUI

struct CalendarHomeSplitView: View {
    @Bindable var router: CalendarRouter
    let years: [ChineseLunarYear]
    let months: [ChineseLunarMonth]
    let emptyStateDescription: String

    var body: some View {
        NavigationSplitView {
            List(selection: selection) {
                Section("农历年") {
                    ForEach(years, id: \.lunarYearNumber) { year in
                        LunarYearRow(year: year)
                            .tag(CalendarRoute.lunarYear(year.lunarYearNumber))
                    }
                }
            }
            .navigationTitle("年份")
        } detail: {
            CalendarRouteDestinationView(
                route: router.currentRoute(on: .years),
                year: selectedYear,
                months: months,
                selectedMonthIndex: $router.selectedMonthIndex,
                selectedDayIndex: $router.selectedDayIndex,
                canSelectPreviousYear: router.canSelectPreviousYear(availableYearNumbers: yearNumbers),
                canSelectNextYear: router.canSelectNextYear(availableYearNumbers: yearNumbers),
                selectPreviousYear: { router.selectPreviousYear(availableYearNumbers: yearNumbers) },
                selectNextYear: { router.selectNextYear(availableYearNumbers: yearNumbers) },
                showYearPicker: nil,
                selectMonth: { month in
                    router.selectMonth(
                        lunarYearNumber: month.lunarYearNumber,
                        monthIndex: month.lunarMonthIndex
                    )
                },
                selectToday: { todaySelection in
                    router.selectToday(todaySelection, preferredYearNumber: ChineseLunarCalendar.yearNumber())
                },
                emptyStateDescription: emptyStateDescription
            )
        }
    }

    private var selection: Binding<CalendarRoute?> {
        Binding {
            router.currentRoute(on: .years)
        } set: { route in
            router.selectedTab = .years
            router.setPath(route.map { [$0] } ?? [], for: .years)
        }
    }

    private var yearNumbers: [Int] {
        years.map(\.lunarYearNumber)
    }

    private var selectedYear: ChineseLunarYear? {
        guard let selectedYearNumber = router.selectedYearNumber else {
            return nil
        }

        return years.first { $0.lunarYearNumber == selectedYearNumber }
    }
}
