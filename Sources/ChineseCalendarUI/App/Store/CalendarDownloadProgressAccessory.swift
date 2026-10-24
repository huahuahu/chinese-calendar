import SwiftUI

/// 同一主标签页可以出现在任意层，附件从实际所在层打开下载详情。
struct CalendarDownloadProgressAccessory: View {
    let progress: FullStoreDownloadProgress
    @Environment(CalendarPresentationContext.self) private var presentation

    @Environment(CalendarHomeCoordinator.self) private var coordinator

    var body: some View {
        FullStoreDownloadBottomProgressView(progress: progress) {
            coordinator.downloadDetails.present(from: presentation)
        }
    }
}
