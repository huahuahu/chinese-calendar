#if DEBUG
    import SwiftUI

    struct FullStoreDownloadPreviewDetailView: View {
        @Bindable var state: FullStoreDownloadPreviewState

        var body: some View {
            FullStoreDownloadDetailView(progress: state.stage.progress)
                .dynamicTypeSize(state.textSize)
        }
    }
#endif
