import ChineseCalendarCore
import ChineseCalendarLocalization
import NavigationCore
import SFSafeSymbols
import SwiftUI

/// 以当前层的独立栈组织日历、历史和设置；根层与任意模态层均可复用。
struct CalendarHomeTabView<BottomStatusBar: View>: View {
    @Environment(CalendarPresentationContext.self) private var presentation
    let bottomStatusBarIsPresented: Bool
    let bottomStatusBar: () -> BottomStatusBar

    var body: some View {
        @Bindable var presentation = presentation

        TabView(selection: $presentation.selectedStack) {
            Tab(value: NavigationStackID<CalendarTab>.scope(.years)) {
                NavigationScopeView(
                    stack: .scope(.years),
                    presentation: presentation
                )
            } label: {
                Label(CalendarTab.years.title, systemSymbol: CalendarTab.years.systemSymbol)
            }

            Tab(value: NavigationStackID<CalendarTab>.scope(.history)) {
                NavigationScopeView(
                    stack: .scope(.history),
                    presentation: presentation
                )
            } label: {
                Label(CalendarTab.history.title, systemSymbol: CalendarTab.history.systemSymbol)
            }

            Tab(value: NavigationStackID<CalendarTab>.scope(.settings)) {
                NavigationScopeView(
                    stack: .scope(.settings),
                    presentation: presentation
                )
            } label: {
                Label(CalendarTab.settings.title, systemSymbol: CalendarTab.settings.systemSymbol)
            }
        }
        .calendarTabViewBottomAccessory(isEnabled: bottomStatusBarIsPresented, content: bottomStatusBar)
        .background(.calendarSystemBackground)
    }
}
