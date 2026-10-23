import ChineseCalendarLocalization
import Foundation
import NavigationCore

/// 根据业务提示路由生成文案。Core 不理解清理数据或下载失败等业务含义。
enum CalendarAlertContent {
    static func content(
        for route: CalendarAlert, messages: [CalendarAlertMessageID: LocalizedStringResource]
    ) -> NavigationAlertContent<CalendarAlert.Action> {
        let acknowledge = NavigationAlertButton<CalendarAlert.Action>(
            CalendarStringKey.Common.Action.ok, action: .acknowledge
        )
        switch route {
        case .clearDownloadedData:
            return NavigationAlertContent(
                title: CalendarStringKey.Settings.ClearData.confirmationTitle,
                message: CalendarStringKey.Settings.ClearData.confirmationMessage,
                firstButton: NavigationAlertButton(
                    CalendarStringKey.Settings.ClearData.action, action: .clearDownloadedData, role: .destructive
                ),
                cancelButton: NavigationAlertCancelButton(CalendarStringKey.Common.Action.cancel, action: .cancel)
            )
        case .clearDataSucceeded:
            return NavigationAlertContent(
                title: CalendarStringKey.Settings.ClearData.successTitle,
                message: CalendarStringKey.Settings.ClearData.successMessage, firstButton: acknowledge
            )
        case let .clearDataFailed(id):
            return NavigationAlertContent(
                title: CalendarStringKey.Settings.ClearData.failureTitle,
                message: messages[id] ?? CalendarStringKey.Common.Error.retryLater, firstButton: acknowledge
            )
        case let .downloadFailed(id):
            return NavigationAlertContent(
                title: CalendarStringKey.Store.Download.failureTitle,
                message: messages[id] ?? CalendarStringKey.Common.Error.retryLater, firstButton: acknowledge
            )
        #if DEBUG
            case let .debugNotice(number):
                return NavigationAlertContent(
                    title: CalendarStringKey.Debug.Alert.noticeTitle(number: number),
                    message: CalendarStringKey.Debug.Alert.noticeMessage, firstButton: acknowledge
                )
            case .debugNavigationChoice:
                return NavigationAlertContent(
                    title: CalendarStringKey.Debug.Alert.navigationTitle,
                    message: CalendarStringKey.Debug.Alert.navigationMessage,
                    firstButton: NavigationAlertButton(
                        CalendarStringKey.Debug.Navigation.pushOnHistory,
                        action: .openHistory
                    ),
                    cancelButton: NavigationAlertCancelButton(CalendarStringKey.Common.Action.cancel, action: .cancel)
                )
        #endif
        }
    }
}
