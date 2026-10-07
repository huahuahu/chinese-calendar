import ChineseCalendarLocalization
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
        .accessibilityHint(CalendarStringKey.Store.Download.Progress.accessibilityHint)
        .accessibilityInputLabels([
            Text(CalendarStringKey.Store.Download.Progress.inputLabel),
            Text(CalendarStringKey.Store.Download.Progress.detailInputLabel)
        ])
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
            return Text(CalendarStringKey.Store.Download.Completed.summary)
        }

        let stepCount = FullStoreDownloadPhase.allCases.count
        return Text(CalendarStringKey.Store.Download.Progress.stage(
            step: progress.phase.rawValue,
            count: stepCount,
            title: progress.phase.title
        ))
    }

    private var compactTitle: Text {
        switch progress.phase {
        case .preparingManifest: Text(CalendarStringKey.Store.Download.Preparing.shortTitle)
        case .downloading: Text(CalendarStringKey.Store.Download.Downloading.shortTitle)
        case .validating: Text(CalendarStringKey.Store.Download.Validating.shortTitle)
        case .installing: Text(CalendarStringKey.Store.Download.Installing.shortTitle)
        case .completed: Text(CalendarStringKey.Store.Download.Completed.shortTitle)
        }
    }
}
