import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

struct CalendarHomeTabView: View {
    @Bindable var router: CalendarRouter
    let years: [ChineseLunarYear]
    let emptyStateDescription: String
    let openSettings: (() -> Void)?

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.yearsPath) {
                CalendarYearsListView(years: years)
                    .navigationDestination(for: CalendarRoute.self, destination: destination)
                    .toolbar(content: settingsToolbar)
            }
            .tabItem {
                Label(CalendarTab.years.title, systemSymbol: CalendarTab.years.systemSymbol)
            }
            .tag(CalendarTab.years)

            NavigationStack(path: $router.historyPath) {
                CalendarHistoryHomeView()
                    .navigationDestination(for: CalendarRoute.self, destination: destination)
                    .toolbar(content: settingsToolbar)
            }
            .tabItem {
                Label(CalendarTab.history.title, systemSymbol: CalendarTab.history.systemSymbol)
            }
            .tag(CalendarTab.history)
        }
    }

    @ToolbarContentBuilder
    private func settingsToolbar() -> some ToolbarContent {
        if let openSettings {
            ToolbarItem(placement: .primaryAction) {
                Button("设置", systemSymbol: .gearshape, action: openSettings)
            }
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
