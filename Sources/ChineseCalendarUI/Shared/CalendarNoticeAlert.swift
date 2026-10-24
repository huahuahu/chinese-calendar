import ChineseCalendarLocalization
import Foundation
import NavigationCore

/// 复用只有一个确认按钮的提示结构，不承载具体业务文案、路由或后续动作。
enum CalendarNoticeAlert {
    static func content(
        title: LocalizedStringResource, message: LocalizedStringResource
    ) -> NavigationAlertContent<CalendarNoticeAction> {
        NavigationAlertContent(
            title: title, message: message,
            firstButton: NavigationAlertButton(CalendarStringKey.Common.Action.ok, action: .acknowledge)
        )
    }

    static func definition(content: NavigationAlertContent<CalendarNoticeAction>) -> NavigationAlertDefinition {
        NavigationAlertDefinition(content: content) { action in
            switch action {
            case .acknowledge:
                break
            }
        }
    }
}
