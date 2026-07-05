import ChineseCalendarCore
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

struct CalendarHomeTabView<BottomStatusBar: View>: View {
    @Bindable var router: CalendarRouter
    let years: [ChineseLunarYear]
    let months: [ChineseLunarMonth]
    let emptyStateDescription: String
    let settingsCoordinator: ChineseCalendarStoreCoordinator?
    let bottomStatusBarIsPresented: Bool
    let bottomStatusBar: () -> BottomStatusBar

    var body: some View {
        let yearsRoute = router.currentRoute(on: .years)
        let yearNumbers = years.map(\.lunarYearNumber)

        TabView(selection: $router.selectedTab) {
            NavigationStack {
                calendarDestination(
                    for: yearsRoute,
                    year: year(for: yearsRoute),
                    yearNumbers: yearNumbers
                )
            }
            .safeAreaInset(edge: .bottom, spacing: 0, content: bottomStatusBar)
            .tabItem {
                Label(CalendarTab.years.title, systemSymbol: CalendarTab.years.systemSymbol)
            }
            .tag(CalendarTab.years)

            NavigationStack(path: $router.historyPath) {
                CalendarHistoryHomeView()
                    .navigationDestination(for: CalendarRoute.self) { route in
                        calendarDestination(for: route, year: year(for: route), yearNumbers: yearNumbers)
                    }
            }
            .safeAreaInset(edge: .bottom, spacing: 0, content: bottomStatusBar)
            .tabItem {
                Label(CalendarTab.history.title, systemSymbol: CalendarTab.history.systemSymbol)
            }
            .tag(CalendarTab.history)

            NavigationStack {
                if let settingsCoordinator {
                    CalendarSettingsView(coordinator: settingsCoordinator, showsDoneButton: false)
                } else {
                    ContentUnavailableView {
                        Label("无法打开设置", systemSymbol: .gearshape)
                    } description: {
                        Text("当前日历数据尚未准备完成。")
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0, content: bottomStatusBar)
            .tabItem {
                Label(CalendarTab.settings.title, systemSymbol: CalendarTab.settings.systemSymbol)
            }
            .tag(CalendarTab.settings)
        }
        .background(.calendarSystemBackground)
    }

    private func calendarDestination(
        for route: CalendarRoute?,
        year: ChineseLunarYear?,
        yearNumbers: [Int]
    ) -> some View {
        CalendarRouteDestinationView(
            route: route,
            year: year,
            months: months,
            selectedMonthIndex: $router.selectedMonthIndex,
            selectedDayIndex: $router.selectedDayIndex,
            canSelectPreviousYear: router.canSelectPreviousYear(availableYearNumbers: yearNumbers),
            canSelectNextYear: router.canSelectNextYear(availableYearNumbers: yearNumbers),
            selectPreviousYear: { router.selectPreviousYear(availableYearNumbers: yearNumbers) },
            selectNextYear: { router.selectNextYear(availableYearNumbers: yearNumbers) },
            showYearPicker: router.presentYearPicker,
            selectMonth: { month in
                router.selectMonth(
                    lunarYearNumber: month.lunarYearNumber,
                    monthIndex: month.lunarMonthIndex
                )
            },
            selectToday: { todaySelection in
                router.selectToday(todaySelection, preferredYearNumber: ChineseLunarCalendar.yearNumber())
            },
            bottomStatusBarIsPresented: bottomStatusBarIsPresented,
            emptyStateDescription: emptyStateDescription
        )
    }

    private func year(for route: CalendarRoute?) -> ChineseLunarYear? {
        guard let yearNumber = route?.lunarYearNumber else {
            return nil
        }

        return years.first { $0.lunarYearNumber == yearNumber }
    }
}
