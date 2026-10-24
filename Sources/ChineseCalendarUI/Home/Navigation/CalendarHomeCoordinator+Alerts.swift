import Foundation

extension CalendarHomeCoordinator {
    /// 下载可能在任意页面结束，错误提示交给当前最上层页面；已有提示时排队。
    func presentDownloadError(_ failure: CalendarStoreFailure) -> Bool {
        router.navigation.presentAlert(.downloadFailed(failure: failure)).result.isAccepted
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
                let failure = CalendarStoreErrorPresentation.failure(for: error, operation: .clear)
                presentation.present(.alert(.clearDataFailed(failure: failure)))
            }
        }
    }

    func handleNoticeAction(_ action: CalendarNoticeAction) {
        switch action {
        case .acknowledge:
            break
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
