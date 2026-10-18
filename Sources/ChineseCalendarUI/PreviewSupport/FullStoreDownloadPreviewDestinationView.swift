#if DEBUG
    import SwiftUI

    struct FullStoreDownloadPreviewDestinationView: View {
        let sessionID: UUID
        @Environment(CalendarHomeCoordinator.self) private var coordinator

        var body: some View {
            if let state = coordinator.downloadPreviewSessions[sessionID] {
                FullStoreDownloadPreview(state: state)
            }
        }
    }
#endif
