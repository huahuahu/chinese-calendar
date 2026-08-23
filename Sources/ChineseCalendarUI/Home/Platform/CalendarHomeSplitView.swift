import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftUI

/// 供 macOS 的 CalendarHomeView 使用，以分栏方式组织年份与日历详情。
struct CalendarHomeSplitView: View {
    @Bindable var coordinator: CalendarHomeCoordinator
    let years: [ChineseLunarYear]

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
                LunarYearDetailView(initialYearNumber: ChineseLunarCalendar.yearNumber())
                    .calendarDestinations()
            }
        }
    }

    private var selection: Binding<CalendarDestination?> {
        Binding {
            coordinator.router.currentDestination(on: .years)
                ?? .lunarYear(ChineseLunarCalendar.yearNumber())
        } set: { destination in
            guard case let .lunarYear(yearNumber, _, _)? = destination else {
                coordinator.router.setPath([], for: .years)
                return
            }

            if yearNumber == ChineseLunarCalendar.yearNumber() {
                coordinator.router.setPath([], for: .years)
            } else {
                coordinator.router.setPath([.lunarYear(yearNumber)], for: .years)
            }
        }
    }
}
