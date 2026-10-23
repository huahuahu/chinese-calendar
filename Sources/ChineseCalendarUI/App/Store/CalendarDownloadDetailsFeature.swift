import NavigationCore
import Observation

/// 由覆盖下载流程的应用 owner 持有，进度附件消失后仍能关闭自己发起的详情。
@MainActor
@Observable
final class CalendarDownloadDetailsFeature {
    private(set) var request: NavigationPresentationHandle?
    @ObservationIgnored private var activeRequest: Request?

    func present(from presentation: CalendarPresentationContext) {
        guard activeRequest == nil else { return }
        let activeRequest = Request()
        self.activeRequest = activeRequest
        let submission = presentation.present(.sheet(.downloadDetails)) { [weak self, weak activeRequest] in
            guard let activeRequest else { return }
            self?.finish(activeRequest)
        }
        // 完成通知可能在 present 返回前同步到达，旧请求不能重新写回或覆盖后来打开的详情。
        guard self.activeRequest === activeRequest else {
            submission.handle?.dismiss()
            return
        }
        if submission.result.isAccepted {
            request = submission.handle
        } else {
            finish(activeRequest)
        }
    }

    func progressDidDisappear() {
        request?.dismiss()
    }

    private func finish(_ activeRequest: Request) {
        guard self.activeRequest === activeRequest else { return }
        request = nil
        self.activeRequest = nil
    }

    private final class Request {}
}
