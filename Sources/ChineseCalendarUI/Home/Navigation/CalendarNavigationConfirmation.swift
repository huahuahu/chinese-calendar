import ChineseCalendarCore
import ChineseCalendarLocalization
import Foundation
import NavigationCore

/// Core 只协调请求；目标描述和确认策略属于日历 App。
enum CalendarNavigationConfirmation {
    static func content(
        for request: NavigationRequest<CalendarTab, CalendarDestination>
    ) -> NavigationConfirmationContent {
        let target: String = switch request {
        case let .replacePath(path, _): description(for: path.last)
        case let .push(destination, _): description(for: destination)
        case let .setRoot(destination, _): description(for: destination)
        case let .selectStack(stack):
            switch stack {
            case let .scope(tab): String(localized: tab.title)
            case .primary: String(localized: CalendarStringKey.Navigation.linkTarget)
            }
        }
        return NavigationConfirmationContent(
            title: CalendarStringKey.Navigation.confirmTitle,
            message: CalendarStringKey.Navigation.confirmMessage(target: target),
            confirm: CalendarStringKey.Navigation.continueAction,
            cancel: CalendarStringKey.Navigation.stayAction
        )
    }

    private static func description(for destination: CalendarDestination?) -> String {
        switch destination {
        case let .lunarYear(year, _, _):
            LunarCalendarFormatting.yearTitle(lunarYearNumber: year)
        case .dynasty:
            String(localized: CalendarStringKey.Navigation.dynastyTarget)
        case .emperor:
            String(localized: CalendarStringKey.Navigation.emperorTarget)
        #if DEBUG
            case .debugNavigation:
                String(localized: CalendarStringKey.Debug.Navigation.title)
        #endif
        default:
            String(localized: CalendarStringKey.Navigation.linkTarget)
        }
    }
}
