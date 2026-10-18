import ChineseCalendarLocalization
import Foundation
import NavigationCore

/// 根据业务提示路由生成文案。Core 不理解清理数据或下载失败等业务含义。
enum CalendarAlertContent {
    static func content(
        for route: CalendarAlert, messages: [UUID: LocalizedStringResource]
    ) -> NavigationAlertContent<CalendarAlert.Action> {
        let acknowledge = NavigationAlertButton<CalendarAlert.Action>(
            CalendarStringKey.Common.Action.ok, action: .acknowledge
        )
        switch route {
        case .clearDownloadedData:
            return NavigationAlertContent(
                title: CalendarStringKey.Settings.ClearData.confirmationTitle,
                message: CalendarStringKey.Settings.ClearData.confirmationMessage,
                buttons: [
                    NavigationAlertButton(CalendarStringKey.Common.Action.cancel, action: .cancel, role: .cancel),
                    NavigationAlertButton(
                        CalendarStringKey.Settings.ClearData.action, action: .clearDownloadedData, role: .destructive
                    )
                ]
            )
        case .clearDataSucceeded:
            return NavigationAlertContent(
                title: CalendarStringKey.Settings.ClearData.successTitle,
                message: CalendarStringKey.Settings.ClearData.successMessage, buttons: [acknowledge]
            )
        case let .clearDataFailed(id):
            return NavigationAlertContent(
                title: CalendarStringKey.Settings.ClearData.failureTitle,
                message: messages[id] ?? CalendarStringKey.Common.Error.retryLater, buttons: [acknowledge]
            )
        case let .downloadFailed(id):
            return NavigationAlertContent(
                title: CalendarStringKey.Store.Download.failureTitle,
                message: messages[id] ?? CalendarStringKey.Common.Error.retryLater, buttons: [acknowledge]
            )
        #if DEBUG
            case let .debugNotice(number):
                return NavigationAlertContent(
                    title: CalendarStringKey.Debug.Alert.noticeTitle(number: number),
                    message: CalendarStringKey.Debug.Alert.noticeMessage, buttons: [acknowledge]
                )
            case .debugNavigationChoice:
                return NavigationAlertContent(
                    title: CalendarStringKey.Debug.Alert.navigationTitle,
                    message: CalendarStringKey.Debug.Alert.navigationMessage,
                    buttons: [
                        NavigationAlertButton(CalendarStringKey.Common.Action.cancel, action: .cancel, role: .cancel),
                        NavigationAlertButton(CalendarStringKey.Debug.Navigation.pushOnHistory, action: .openHistory)
                    ]
                )
        #endif
        }
    }
}
