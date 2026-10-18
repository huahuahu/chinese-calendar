import ChineseCalendarLocalization
import SwiftUI

/// 普通列表和模态内的资料入口复用相同路由，展示方式由当前上下文决定。
private struct CalendarPresentationMenu: ViewModifier {
    let destination: CalendarDestination
    @Environment(CalendarPresentationContext.self) private var presentation

    func body(content: Content) -> some View {
        content.contextMenu {
            Button(CalendarStringKey.Navigation.openSheet) {
                presentation.present(destination)
            }
            Button(CalendarStringKey.Navigation.openFullScreen) {
                presentation.present(destination, style: .fullScreen)
            }
        }
    }
}

extension View {
    func calendarPresentationMenu(destination: CalendarDestination) -> some View {
        modifier(CalendarPresentationMenu(destination: destination))
    }
}
