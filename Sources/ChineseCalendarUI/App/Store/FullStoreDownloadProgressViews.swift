import SFSafeSymbols
import SwiftUI

/// 显示在 iOS 主界面底部，根据标签栏状态呈现完整数据下载进度。
struct FullStoreDownloadBottomProgressView: View {
    let progress: FullStoreDownloadProgress
    let showDetails: () -> Void

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let spacing: CGFloat = 8
        static let progressSpacing: CGFloat = 4
        static let minimumHeight: CGFloat = 44
    }

    var body: some View {
        Button(action: showDetails) {
            HStack(spacing: Constants.spacing) {
                Image(systemSymbol: progress.systemSymbol)
                    .font(.title3)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .foregroundStyle(.tint)

                progressContent

                Image(systemSymbol: .chevronUp)
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, minHeight: Constants.minimumHeight)
            .contentShape(.rect)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(stageTitle)
            .accessibilityValue(Text(progress.detail))
        }
        .buttonStyle(.plain)
        .accessibilityHint("查看完整下载状态")
        .accessibilityInputLabels([Text("下载进度"), Text("查看下载状态")])
    }

    @ViewBuilder
    private var progressContent: some View {
        if let fraction = progress.downloadFraction {
            // inline 主动采用简洁展示；展开时根据可用宽高选择布局。
            if placement == .inline {
                ProgressView(value: fraction)
            } else {
                ViewThatFits {
                    VStack(alignment: .leading, spacing: Constants.progressSpacing) {
                        stageTitle
                            .font(.callout.weight(.semibold))
                            .lineLimit(1)
                        ProgressView(value: fraction)
                    }

                    ProgressView(value: fraction)
                }
                .frame(maxWidth: .infinity)
            }

            Text(fraction, format: .percent.precision(.fractionLength(0)))
                .monospacedDigit()
                .fixedSize()
                .foregroundStyle(.secondary)
        } else {
            ViewThatFits {
                if placement != .inline {
                    stageTitle
                        .font(.callout.weight(.semibold))
                        .fixedSize()
                }

                compactTitle
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if progress.phase != .completed {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var stageTitle: Text {
        if progress.phase == .completed {
            return Text("完整日历数据已就绪")
        }

        let stepCount = FullStoreDownloadPhase.allCases.count
        return Text("第 \(progress.phase.rawValue)/\(stepCount) 步 · \(Text(progress.phase.title))")
    }

    private var compactTitle: Text {
        switch progress.phase {
        case .preparingManifest: Text("准备")
        case .downloading: Text("下载")
        case .validating: Text("校验")
        case .installing: Text("安装")
        case .completed: Text("已就绪")
        }
    }
}
