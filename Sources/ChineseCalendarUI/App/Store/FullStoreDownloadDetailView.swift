import ChineseCalendarLocalization
import SwiftUI

/// 在可滚动的页面中展示底部附件容纳不下的完整下载状态。
struct FullStoreDownloadDetailView: View {
    let progress: FullStoreDownloadProgress

    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let spacing: CGFloat = 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.spacing) {
                ForEach(FullStoreDownloadPhase.allCases) { phase in
                    FullStoreDownloadStepView(
                        phase: phase,
                        status: progress.status(of: phase),
                        detail: phase == progress.phase ? progress.detail : nil,
                        downloadFraction: phase == .downloading ? progress.downloadFraction : nil
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(CalendarStringKey.Store.Download.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("准备下载") {
    NavigationStack {
        FullStoreDownloadDetailView(progress: .preparingManifest)
    }
}

#Preview("文件下载一半") {
    NavigationStack {
        FullStoreDownloadDetailView(progress: .downloading(progress: 0.5))
    }
}

#Preview("文件下载一半 · 最大辅助字号") {
    NavigationStack {
        FullStoreDownloadDetailView(progress: .downloading(progress: 0.5))
            .dynamicTypeSize(.accessibility5)
    }
}

#Preview("安装数据") {
    NavigationStack {
        FullStoreDownloadDetailView(progress: .installing)
    }
}

#Preview("全部完成") {
    NavigationStack {
        FullStoreDownloadDetailView(progress: .completed)
    }
}
