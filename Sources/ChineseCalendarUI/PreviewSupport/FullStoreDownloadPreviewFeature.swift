#if DEBUG
    import NavigationCore
    import Observation

    /// 设置入口持有本次演示；子详情沿用演示状态，不结束父流程。
    @MainActor
    @Observable
    final class FullStoreDownloadPreviewFeature {
        private(set) var session: FullStoreDownloadPreviewState?
        private var request: NavigationPresentationHandle?

        func present(
            from presentation: CalendarPresentationContext, coordinator: CalendarHomeCoordinator,
            storeCoordinator: ChineseCalendarStoreCoordinator? = nil
        ) {
            guard session == nil else { return }
            let session = FullStoreDownloadPreviewState()
            self.session = session
            let submission = presentation.present(
                .fullScreen(
                    .downloadPreview, initialStack: .scope(.years),
                    rootDestinations: [
                        .scope(.years): .downloadPreviewScenarios,
                        .scope(.history): .downloadPreviewSwitch
                    ]
                ),
                configuration: coordinator.downloadPreviewConfiguration(
                    state: session,
                    storeCoordinator: storeCoordinator
                )
            ) { [weak self] in self?.finish(session) }
            if submission.result.isAccepted {
                if self.session === session {
                    request = submission.handle
                } else {
                    submission.handle?.dismiss()
                }
            } else {
                finish(session)
            }
        }

        private func finish(_ session: FullStoreDownloadPreviewState) {
            guard self.session === session else { return }
            self.session = nil
            request = nil
        }
    }
#endif
