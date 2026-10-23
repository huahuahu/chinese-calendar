import ChineseCalendarLocalization
import Foundation

extension CalendarHomeCoordinator {
    /// 下载可能在任意页面结束，错误提示交给当前最上层页面；已有提示时排队。
    func presentDownloadError(_ message: LocalizedStringResource) -> Bool {
        let id = CalendarAlertMessageID()
        alertMessages[id] = message
        if router.navigation.presentAlert(.downloadFailed(messageID: id)).isAccepted { return true }
        alertMessages[id] = nil
        return false
    }

    /// 宿主在提示真正关闭后调用；清理结束并登记结果提示前，外部导航继续等待。
    func handleClearDownloadedDataAction(
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
                let id = CalendarAlertMessageID()
                alertMessages[id] = CalendarStoreErrorPresentation.message(for: error, operation: .clear)
                if !presentation.present(.alert(.clearDataFailed(messageID: id))).isAccepted { alertMessages[id] = nil }
            }
        }
    }

    func handleNoticeAction(_ action: CalendarNoticeAction, messageID: CalendarAlertMessageID? = nil) {
        switch action {
        case .acknowledge:
            if let messageID { alertMessages[messageID] = nil }
        }
    }

    #if DEBUG
        func handleDebugNavigationAction(_ action: CalendarDebugNavigationAction) {
            switch action {
            case .cancel:
                break
            case .openHistory:
                router.navigation.submit(.push(.debugNavigation(id: UUID()), on: .history))
            }
        }
    #endif
}
