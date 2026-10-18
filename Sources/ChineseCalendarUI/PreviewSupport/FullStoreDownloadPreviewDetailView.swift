#if DEBUG
    import SwiftUI

    struct FullStoreDownloadPreviewDetailView: View {
        let sessionID: UUID
        @Environment(CalendarHomeCoordinator.self) private var coordinator

        var body: some View {
            if let state = coordinator.downloadPreviewSessions[sessionID] {
                FullStoreDownloadDetailView(progress: state.stage.progress)
                    .dynamicTypeSize(state.textSize)
            }
        }
    }
#endif
