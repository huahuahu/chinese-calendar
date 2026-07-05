import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftUI

struct CalendarHomeSplitView: View {
    @Bindable var router: CalendarRouter
    let years: [ChineseLunarYear]
    let months: [ChineseLunarMonth]
    let emptyStateDescription: String

    var body: some View {
        let yearsRoute = router.currentRoute(on: .years)
        let yearNumbers = years.map(\.lunarYearNumber)

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
                route: yearsRoute,
                year: year(for: yearsRoute),
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

    private func year(for route: CalendarRoute?) -> ChineseLunarYear? {
        guard let yearNumber = route?.lunarYearNumber else {
            return nil
        }

        return years.first { $0.lunarYearNumber == yearNumber }
    }
}
