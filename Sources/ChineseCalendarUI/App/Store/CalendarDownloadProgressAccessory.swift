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

#if DEBUG
    #Preview("下载附件 · 下载一半") {
        CalendarDownloadProgressAccessoryPreview(progress: .downloading(progress: 0.5))
    }

    #Preview("下载附件 · 准备中") {
        CalendarDownloadProgressAccessoryPreview(progress: .preparingManifest)
    }

    #Preview("下载附件 · 完成 · 深色") {
        CalendarDownloadProgressAccessoryPreview(progress: .completed)
            .preferredColorScheme(.dark)
    }

    #Preview("下载附件 · 最大辅助字号") {
        CalendarDownloadProgressAccessoryPreview(progress: .downloading(progress: 1))
            .dynamicTypeSize(.accessibility5)
    }
#endif
