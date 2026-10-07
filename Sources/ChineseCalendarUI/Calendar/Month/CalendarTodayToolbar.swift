import ChineseCalendarLocalization
import SFSafeSymbols
import SwiftUI

/// 按系统工具栏布局显示“今天”，让 Duo 竖栏保留图标。
@available(iOS 27.1, *)
struct CalendarTodayToolbar: ToolbarContent {
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge

    let selectToday: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(
                CalendarStringKey.Calendar.MonthNavigation.today,
                systemSymbol: .calendarBadgeClock,
                action: selectToday
            )
            .labelStyle(TodayLabelStyle(showsTitle: toolbarVerticalEdge == nil))
        }
    }

    private struct TodayLabelStyle: LabelStyle {
        let showsTitle: Bool

        func makeBody(configuration: Configuration) -> some View {
            if showsTitle {
                Label(configuration).labelStyle(.titleOnly)
            } else {
                Label(configuration).labelStyle(.automatic)
            }
        }
    }
}
