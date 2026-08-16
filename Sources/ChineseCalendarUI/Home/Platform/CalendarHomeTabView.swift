import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

#if os(iOS)
    /// 供 iOS 的 CalendarHomeView 使用，以标签页组织日历、历史和设置界面。
    struct CalendarHomeTabView<BottomStatusBar: View>: View {
        @Bindable var coordinator: CalendarHomeCoordinator
        let emptyStateDescription: String
        let settingsCoordinator: ChineseCalendarStoreCoordinator?
        let bottomStatusBarIsPresented: Bool
        let bottomStatusBar: () -> BottomStatusBar

        var body: some View {
            @Bindable var router = coordinator.router

            TabView(selection: $router.selectedTab) {
                NavigationStack(path: $router.yearsPath) {
                    calendarDestination(for: router.yearsRootDestination)
                        .calendarDestinations(emptyStateDescription: emptyStateDescription)
                }
                .tabItem {
                    Label(CalendarTab.years.title, systemSymbol: CalendarTab.years.systemSymbol)
                }
                .tag(CalendarTab.years)

                NavigationStack(path: $router.historyPath) {
                    CalendarHistoryHomeView()
                        .calendarDestinations(emptyStateDescription: emptyStateDescription)
                }
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
                .tabItem {
                    Label(CalendarTab.settings.title, systemSymbol: CalendarTab.settings.systemSymbol)
                }
                .tag(CalendarTab.settings)
            }
            .calendarTabViewBottomAccessory(isEnabled: bottomStatusBarIsPresented, content: bottomStatusBar)
            .background(.calendarSystemBackground)
        }

        private func calendarDestination(for destination: CalendarDestination?) -> some View {
            CalendarDestinationView(
                destination: destination,
                emptyStateDescription: emptyStateDescription
            )
        }
    }
#endif
