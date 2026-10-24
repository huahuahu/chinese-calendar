import ChineseCalendarLocalization
import Foundation
import NavigationCore

/// 每类提示在构建文案时确定自己的 Action；配置将它与同类型处理函数配对。
enum CalendarAlertContent {
    static var clearDownloadedData: NavigationAlertContent<ClearDownloadedDataAction> {
        NavigationAlertContent(
            title: CalendarStringKey.Settings.ClearData.confirmationTitle,
            message: CalendarStringKey.Settings.ClearData.confirmationMessage,
            firstButton: NavigationAlertButton(
                CalendarStringKey.Settings.ClearData.action, action: .clear, role: .destructive
            ),
            cancelButton: NavigationAlertCancelButton(CalendarStringKey.Common.Action.cancel, action: .cancel)
        )
    }

    static var clearDataSucceeded: NavigationAlertContent<CalendarNoticeAction> {
        notice(
            title: CalendarStringKey.Settings.ClearData.successTitle,
            message: CalendarStringKey.Settings.ClearData.successMessage
        )
    }

    static func clearDataFailed(message: LocalizedStringResource?) -> NavigationAlertContent<CalendarNoticeAction> {
        notice(
            title: CalendarStringKey.Settings.ClearData.failureTitle,
            message: message ?? CalendarStringKey.Common.Error.retryLater
        )
    }

    static func downloadFailed(message: LocalizedStringResource?) -> NavigationAlertContent<CalendarNoticeAction> {
        notice(
            title: CalendarStringKey.Store.Download.failureTitle,
            message: message ?? CalendarStringKey.Common.Error.retryLater
        )
    }

    #if DEBUG
        static func debugNotice(number: Int) -> NavigationAlertContent<CalendarNoticeAction> {
            notice(
                title: CalendarStringKey.Debug.Alert.noticeTitle(number: number),
                message: CalendarStringKey.Debug.Alert.noticeMessage
            )
        }

        static var debugNavigationChoice: NavigationAlertContent<CalendarDebugNavigationAction> {
            NavigationAlertContent(
                title: CalendarStringKey.Debug.Alert.navigationTitle,
                message: CalendarStringKey.Debug.Alert.navigationMessage,
                firstButton: NavigationAlertButton(
                    CalendarStringKey.Debug.Navigation.pushOnHistory, action: .openHistory
                ),
                cancelButton: NavigationAlertCancelButton(CalendarStringKey.Common.Action.cancel, action: .cancel)
            )
        }
    #endif

    private static func notice(
        title: LocalizedStringResource, message: LocalizedStringResource
    ) -> NavigationAlertContent<CalendarNoticeAction> {
        NavigationAlertContent(
            title: title, message: message,
            firstButton: NavigationAlertButton(CalendarStringKey.Common.Action.ok, action: .acknowledge)
        )
    }
}
