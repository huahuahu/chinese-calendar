import SFSafeSymbols
import SwiftUI

/// 显示在 iOS 主界面底部，根据标签栏状态呈现完整数据下载进度。
struct FullStoreDownloadBottomProgressView: View {
    let progress: FullStoreDownloadProgress

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        Group {
            if placement == .inline {
                HStack(spacing: 10) {
                    Image(systemSymbol: progress.systemSymbol)
                        .foregroundStyle(.tint)

                    ProgressView(value: progress.fractionCompleted)

                    Text(progress.fractionCompleted, format: .percent.precision(.fractionLength(0)))
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemSymbol: progress.systemSymbol)
                            .font(.title3)
                            .foregroundStyle(.tint)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(progress.title)
                                .font(.callout.weight(.semibold))
                            ProgressView(value: progress.fractionCompleted)
                        }

                        Text(progress.fractionCompleted, format: .percent.precision(.fractionLength(0)))
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    Text(progress.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.title)，\(progress.detail)")
        .accessibilityValue(progress.fractionCompleted.formatted(.percent.precision(.fractionLength(0))))
    }
}
