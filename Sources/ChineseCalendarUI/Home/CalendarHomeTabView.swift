import ChineseCalendarCore
import ChineseCalendarLocalization
import NavigationCore
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
                NavigationScopeView(
                    context: router.navigation.context(for: .years),
                    presentation: router.navigation.rootPresentation
                ) {
                    LunarYearDestinationView(landing: .year(number: ChineseLunarCalendar.yearNumber()))
                } destinationContent: { destination in
                    CalendarDestinationView(destination: destination)
                }
            } label: {
                Label(CalendarTab.years.title, systemSymbol: CalendarTab.years.systemSymbol)
            }

            Tab(value: CalendarTab.history) {
                NavigationScopeView(
                    context: router.navigation.context(for: .history),
                    presentation: router.navigation.rootPresentation
                ) {
                    CalendarHistoryHomeView()
                } destinationContent: { destination in
                    CalendarDestinationView(destination: destination)
                }
            } label: {
                Label(CalendarTab.history.title, systemSymbol: CalendarTab.history.systemSymbol)
            }

            Tab(value: CalendarTab.settings) {
                NavigationScopeView(
                    context: router.navigation.context(for: .settings),
                    presentation: router.navigation.rootPresentation
                ) {
                    if let settingsCoordinator {
                        CalendarSettingsView(coordinator: settingsCoordinator, showsDoneButton: false)
                    } else {
                        ContentUnavailableView {
                            Label(CalendarStringKey.Settings.Unavailable.title, systemSymbol: .gearshape)
                        } description: {
                            Text(CalendarStringKey.Settings.Unavailable.message)
                        }
                    }
                } destinationContent: { destination in
                    CalendarDestinationView(destination: destination)
                }
            } label: {
                Label(CalendarTab.settings.title, systemSymbol: CalendarTab.settings.systemSymbol)
            }
        }
        .calendarTabViewBottomAccessory(isEnabled: bottomStatusBarIsPresented, content: bottomStatusBar)
        .background(.calendarSystemBackground)
    }
}
