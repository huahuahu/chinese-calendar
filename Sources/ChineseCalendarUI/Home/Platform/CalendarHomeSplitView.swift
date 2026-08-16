import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftUI

/// 供 macOS 的 CalendarHomeView 使用，以分栏方式组织年份与日历详情。
struct CalendarHomeSplitView: View {
    @Bindable var coordinator: CalendarHomeCoordinator
    let years: [ChineseLunarYear]
    let emptyStateDescription: String

    var body: some View {
        @Bindable var router = coordinator.router

        NavigationSplitView {
            List(selection: selection) {
                Section("农历年") {
                    ForEach(years, id: \.lunarYearNumber) { year in
                        LunarYearRow(year: year)
                            .tag(CalendarDestination.lunarYear(year.lunarYearNumber))
                    }
                }
            }
            .navigationTitle("年份")
        } detail: {
            NavigationStack(path: $router.yearsPath) {
                CalendarDestinationView(
                    destination: router.yearsRootDestination,
                    emptyStateDescription: emptyStateDescription
                )
                .calendarDestinations(emptyStateDescription: emptyStateDescription)
            }
        }
    }

    private var selection: Binding<CalendarDestination?> {
        Binding {
            coordinator.router.yearsRootDestination?.lunarYearNumber.map {
                .lunarYear($0)
            }
        } set: { destination in
            guard case .lunarYear? = destination else {
                coordinator.router.setYearsRootDestination(nil)
                return
            }

            coordinator.router.setYearsRootDestination(destination)
        }
    }
}
