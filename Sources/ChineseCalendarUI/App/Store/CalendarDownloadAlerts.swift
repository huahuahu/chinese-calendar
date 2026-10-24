import ChineseCalendarLocalization
import NavigationCore

/// 下载可能在任意页面结束，错误提示由下载业务提交给当前最上层；已有提示时排队。
enum CalendarDownloadAlerts {
    static func presentFailure(_ failure: CalendarStoreFailure, router: CalendarRouter) -> Bool {
        router.navigation.presentAlert(.downloadFailed(failure: failure)).result.isAccepted
    }

    static func failed(failure: CalendarStoreFailure) -> NavigationAlertDefinition {
        CalendarNoticeAlert.definition(content: failureContent(failure: failure))
    }

    static func failureContent(failure: CalendarStoreFailure) -> NavigationAlertContent<CalendarNoticeAction> {
        CalendarNoticeAlert.content(
            title: CalendarStringKey.Store.Download.failureTitle,
            message: CalendarStoreErrorPresentation.message(for: failure)
        )
    }
}
