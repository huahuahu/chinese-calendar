import ChineseCalendarLocalization
import Foundation
import NavigationCore

/// 设置页的数据清理提示与动作；宿主在真实关闭后等待清理及结果提示提交完成。
enum CalendarSettingsAlerts {
    static func clearDownloadedData(
        storeCoordinator: ChineseCalendarStoreCoordinator?, presentation: CalendarPresentationContext
    ) -> NavigationAlertDefinition {
        let clearDownloadedData: (@MainActor () async throws -> Void)? = if let store = storeCoordinator {
            { try await store.clearDownloadedData() }
        } else {
            nil
        }
        return NavigationAlertDefinition(content: clearDownloadedDataContent) { action in
            await handleClearDownloadedDataAction(
                action, presentation: presentation, clearDownloadedData: clearDownloadedData
            )
        }
    }

    static var clearDownloadedDataContent: NavigationAlertContent<ClearDownloadedDataAction> {
        NavigationAlertContent(
            title: CalendarStringKey.Settings.ClearData.confirmationTitle,
            message: CalendarStringKey.Settings.ClearData.confirmationMessage,
            firstButton: NavigationAlertButton(
                CalendarStringKey.Settings.ClearData.action, action: .clear, role: .destructive
            ),
            cancelButton: NavigationAlertCancelButton(CalendarStringKey.Common.Action.cancel, action: .cancel)
        )
    }

    static func clearDataSucceeded() -> NavigationAlertDefinition {
        CalendarNoticeAlert.definition(content: clearDataSucceededContent)
    }

    static var clearDataSucceededContent: NavigationAlertContent<CalendarNoticeAction> {
        CalendarNoticeAlert.content(
            title: CalendarStringKey.Settings.ClearData.successTitle,
            message: CalendarStringKey.Settings.ClearData.successMessage
        )
    }

    static func clearDataFailed(failure: CalendarStoreFailure) -> NavigationAlertDefinition {
        CalendarNoticeAlert.definition(content: clearDataFailedContent(failure: failure))
    }

    static func clearDataFailedContent(failure: CalendarStoreFailure) -> NavigationAlertContent<CalendarNoticeAction> {
        CalendarNoticeAlert.content(
            title: CalendarStringKey.Settings.ClearData.failureTitle,
            message: CalendarStoreErrorPresentation.message(for: failure)
        )
    }

    static func handleClearDownloadedDataAction(
        _ action: ClearDownloadedDataAction, presentation: CalendarPresentationContext,
        clearDownloadedData: (@MainActor () async throws -> Void)?
    ) async {
        switch action {
        case .cancel:
            break
        case .clear:
            guard let clearDownloadedData else { return }
            do {
                try await clearDownloadedData()
                presentation.present(.alert(.clearDataSucceeded))
            } catch {
                let failure = CalendarStoreErrorPresentation.failure(for: error, operation: .clear)
                presentation.present(.alert(.clearDataFailed(failure: failure)))
            }
        }
    }
}
