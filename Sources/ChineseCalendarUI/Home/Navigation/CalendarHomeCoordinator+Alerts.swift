import ChineseCalendarLocalization
import Foundation

extension CalendarHomeCoordinator {
    /// 下载可能在任意页面结束，错误提示交给当前最上层页面；已有提示时排队。
    func presentDownloadError(_ message: LocalizedStringResource) -> Bool {
        let id = UUID()
        alertMessages[id] = message
        if router.navigation.presentAlert(.downloadFailed(messageID: id)) { return true }
        alertMessages[id] = nil
        return false
    }

    /// 宿主在 alert 真正关闭后调用；异步业务处理结束前，外部导航继续等待。
    func handleAlertAction(
        _ route: CalendarAlert, action: CalendarAlert.Action,
        presentation: CalendarPresentationContext, store: ChineseCalendarStoreCoordinator?
    ) async {
        if let id = route.messageID { alertMessages[id] = nil }
        switch action {
        case .acknowledge, .cancel:
            break
        case .clearDownloadedData:
            guard route == .clearDownloadedData, let store else { return }
            do {
                try await store.clearDownloadedData()
                presentation.present(.alert(.clearDataSucceeded))
            } catch {
                let id = UUID()
                alertMessages[id] = CalendarStoreErrorPresentation.message(for: error, operation: .clear)
                if !presentation.present(.alert(.clearDataFailed(messageID: id))) { alertMessages[id] = nil }
            }
        #if DEBUG
            case .openHistory:
                router.navigation.submit(.push(.debugNavigation(id: UUID()), on: .history))
        #endif
        }
    }
}
