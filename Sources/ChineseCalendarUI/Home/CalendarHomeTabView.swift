import ChineseCalendarCore
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
            Tab(
                CalendarTab.years.title,
                systemSymbol: CalendarTab.years.systemSymbol,
                value: CalendarTab.years
            ) {
                NavigationStack(path: $router.yearsPath) {
                    LunarYearDestinationView(yearNumber: ChineseLunarCalendar.yearNumber())
                        .calendarDestinations()
                }
            }

            Tab(
                CalendarTab.history.title,
                systemSymbol: CalendarTab.history.systemSymbol,
                value: CalendarTab.history
            ) {
                NavigationStack(path: $router.historyPath) {
                    CalendarHistoryHomeView()
                        .calendarDestinations()
                }
            }

            Tab(
                CalendarTab.settings.title,
                systemSymbol: CalendarTab.settings.systemSymbol,
                value: CalendarTab.settings
            ) {
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
            }
        }
        .calendarTabViewBottomAccessory(isEnabled: bottomStatusBarIsPresented, content: bottomStatusBar)
        .background(.calendarSystemBackground)
    }
}
