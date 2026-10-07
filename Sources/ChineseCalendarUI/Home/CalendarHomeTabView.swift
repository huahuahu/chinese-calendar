import ChineseCalendarCore
import ChineseCalendarLocalization
import SFSafeSymbols
import SwiftUI

/// 供 CalendarHomeView 使用，以标签页组织日历、历史和设置界面。
struct CalendarHomeTabView<BottomStatusBar: View>: View {
    @Bindable var coordinator: CalendarHomeCoordinator
    let settingsCoordinator: ChineseCalendarStoreCoordinator?
    let bottomStatusBarIsPresented: Bool
    let bottomStatusBar: () -> BottomStatusBar

    var body: some View {
        @Bindable var router = coordinator.router

        TabView(selection: $router.selectedTab) {
            Tab(value: CalendarTab.years) {
                NavigationStack(path: $router.yearsPath) {
                    LunarYearDestinationView(landing: .year(number: ChineseLunarCalendar.yearNumber()))
                        .calendarDestinations()
                }
            } label: {
                Label(CalendarTab.years.title, systemSymbol: CalendarTab.years.systemSymbol)
            }

            Tab(value: CalendarTab.history) {
                NavigationStack(path: $router.historyPath) {
                    CalendarHistoryHomeView()
                        .calendarDestinations()
                }
            } label: {
                Label(CalendarTab.history.title, systemSymbol: CalendarTab.history.systemSymbol)
            }

            Tab(value: CalendarTab.settings) {
                NavigationStack {
                    if let settingsCoordinator {
                        CalendarSettingsView(coordinator: settingsCoordinator, showsDoneButton: false)
                    } else {
                        ContentUnavailableView {
                            Label(CalendarStringKey.Settings.Unavailable.title, systemSymbol: .gearshape)
                        } description: {
                            Text(CalendarStringKey.Settings.Unavailable.message)
                        }
                    }
                }
            } label: {
                Label(CalendarTab.settings.title, systemSymbol: CalendarTab.settings.systemSymbol)
            }
        }
        .calendarTabViewBottomAccessory(isEnabled: bottomStatusBarIsPresented, content: bottomStatusBar)
        .background(.calendarSystemBackground)
    }
}
