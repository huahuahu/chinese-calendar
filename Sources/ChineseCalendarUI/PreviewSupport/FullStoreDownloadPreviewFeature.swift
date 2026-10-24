#if DEBUG
    import NavigationCore
    import Observation

    /// 设置入口持有本次演示；子详情沿用演示状态，不结束父流程。
    @MainActor
    @Observable
    final class FullStoreDownloadPreviewFeature {
        private(set) var state: FullStoreDownloadPreviewState?
        private var request: NavigationPresentationHandle?

        func present(
            from presentation: CalendarPresentationContext
        ) {
            guard state == nil else { return }
            let state = FullStoreDownloadPreviewState()
            self.state = state
            let submission = presentation.present(
                .fullScreen(
                    .downloadPreview(id: state.id, state: state), initialStack: .scope(.years),
                    rootDestinations: [
                        .scope(.years): .downloadPreviewScenarios(id: state.id, state: state),
                        .scope(.history): .downloadPreviewSwitch
                    ]
                )
            ) { [weak self] in self?.finish(state) }
            if submission.result.isAccepted {
                if self.state === state {
                    request = submission.handle
                } else {
                    submission.handle?.dismiss()
                }
            } else {
                finish(state)
            }
        }

        private func finish(_ state: FullStoreDownloadPreviewState) {
            guard self.state === state else { return }
            self.state = nil
            request = nil
        }
    }
#endif
