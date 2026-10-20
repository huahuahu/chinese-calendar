import ChineseCalendarCore
import ChineseCalendarLocalization
import NavigationCore
import SFSafeSymbols
import SwiftUI

/// 供 CalendarHomeView 使用，以标签页组织日历、历史和设置界面。
struct CalendarHomeTabView<BottomStatusBar: View>: View {
    @Bindable var coordinator: CalendarHomeCoordinator
    let bottomStatusBarIsPresented: Bool
    let bottomStatusBar: () -> BottomStatusBar

    var body: some View {
        @Bindable var router = coordinator.router

        TabView(selection: $router.selectedTab) {
            Tab(value: CalendarTab.years) {
                NavigationScopeView(
                    stack: .scope(.years),
                    presentation: router.navigation.rootPresentation
                )
            } label: {
                Label(CalendarTab.years.title, systemSymbol: CalendarTab.years.systemSymbol)
            }

            Tab(value: CalendarTab.history) {
                NavigationScopeView(
                    stack: .scope(.history),
                    presentation: router.navigation.rootPresentation
                )
            } label: {
                Label(CalendarTab.history.title, systemSymbol: CalendarTab.history.systemSymbol)
            }

            Tab(value: CalendarTab.settings) {
                NavigationScopeView(
                    stack: .scope(.settings),
                    presentation: router.navigation.rootPresentation
                )
            } label: {
                Label(CalendarTab.settings.title, systemSymbol: CalendarTab.settings.systemSymbol)
            }
        }
        .calendarTabViewBottomAccessory(isEnabled: bottomStatusBarIsPresented, content: bottomStatusBar)
        .background(.calendarSystemBackground)
    }
}
