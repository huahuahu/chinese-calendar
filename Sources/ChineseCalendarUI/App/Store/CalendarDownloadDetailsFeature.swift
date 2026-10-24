import NavigationCore
import Observation

/// 由 CalendarHomeCoordinator 持有，保存本次下载详情的 handle。
/// 即使底部进度附件已消失，仍能关闭从该附件打开的详情页。
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
        if submission.result.isAccepted {
            request = submission.handle
        } else {
            finish(activeRequest)
        }
    }

    func progressDidDisappear() {
        request?.dismiss()
        if let activeRequest { finish(activeRequest) }
    }

    private func finish(_ activeRequest: Request) {
        guard self.activeRequest === activeRequest else { return }
        request = nil
        self.activeRequest = nil
    }

    private final class Request {}
}
