import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

struct CalendarHomeTabView<BottomStatusBar: View>: View {
    @Bindable var router: CalendarRouter
    let years: [ChineseLunarYear]
    let emptyStateDescription: String
    let settingsCoordinator: ChineseCalendarStoreCoordinator?
    let bottomStatusBar: () -> BottomStatusBar

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.yearsPath) {
                CalendarYearsListView(years: years)
                    .navigationDestination(for: CalendarRoute.self, destination: destination)
            }
            .safeAreaInset(edge: .bottom, spacing: 0, content: bottomStatusBar)
            .tabItem {
                Label(CalendarTab.years.title, systemSymbol: CalendarTab.years.systemSymbol)
            }
            .tag(CalendarTab.years)

            NavigationStack(path: $router.historyPath) {
                CalendarHistoryHomeView()
                    .navigationDestination(for: CalendarRoute.self, destination: destination)
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
    }

    private func destination(for route: CalendarRoute) -> some View {
        CalendarRouteDestinationView(
            route: route,
            year: year(for: route),
            selectedMonthIndex: $router.selectedMonthIndex,
            canSelectPreviousYear: router.canSelectPreviousYear(availableYearNumbers: yearNumbers),
            canSelectNextYear: router.canSelectNextYear(availableYearNumbers: yearNumbers),
            selectPreviousYear: { router.selectPreviousYear(availableYearNumbers: yearNumbers) },
            selectNextYear: { router.selectNextYear(availableYearNumbers: yearNumbers) },
            showYearList: { router.setPath([], for: .years) },
            emptyStateDescription: emptyStateDescription
        )
    }

    private var yearNumbers: [Int] {
        years.map(\.lunarYearNumber)
    }

    private func year(for route: CalendarRoute?) -> ChineseLunarYear? {
        guard let yearNumber = route?.lunarYearNumber else {
            return nil
        }

        return years.first { $0.lunarYearNumber == yearNumber }
    }
}
