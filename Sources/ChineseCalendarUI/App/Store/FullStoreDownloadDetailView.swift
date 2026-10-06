import SFSafeSymbols
import SwiftUI

/// 在可滚动的页面中展示底部附件容纳不下的完整下载状态。
struct FullStoreDownloadDetailView: View {
    let progress: FullStoreDownloadProgress

    @Environment(\.dismiss) private var dismiss

    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let spacing: CGFloat = 0
    }

    var body: some View {
        NavigationStack {
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
            .navigationTitle("完整数据下载")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭", systemSymbol: .xmark) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview("准备下载") {
    FullStoreDownloadDetailView(progress: .preparingManifest)
}

#Preview("文件下载一半") {
    FullStoreDownloadDetailView(progress: .downloading(progress: 0.5))
}

#Preview("文件下载一半 · 最大辅助字号") {
    FullStoreDownloadDetailView(progress: .downloading(progress: 0.5))
        .dynamicTypeSize(.accessibility5)
}

#Preview("安装数据") {
    FullStoreDownloadDetailView(progress: .installing)
}

#Preview("全部完成") {
    FullStoreDownloadDetailView(progress: .completed)
}
