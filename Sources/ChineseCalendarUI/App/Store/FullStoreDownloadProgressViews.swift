import SFSafeSymbols
import SwiftUI

/// 显示在 macOS 独立窗口中，用于查看完整日历数据的下载进度。
public struct FullStoreDownloadProgressWindow: View {
    public static let sceneID = "full-store-download-progress"

    private let coordinator: ChineseCalendarStoreCoordinator

    public init(coordinator: ChineseCalendarStoreCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        Group {
            if let progress = coordinator.fullStoreDownloadProgress {
                FullStoreDownloadProgressContent(progress: progress)
                    .padding(20)
            } else {
                ContentUnavailableView(
                    label: {
                        Label("没有正在下载的数据", systemSymbol: .checkmarkCircle)
                    },
                    description: {
                        Text("开始下载完整日期数据后，进度会显示在这里。")
                    }
                )
                .padding()
            }
        }
        .frame(minWidth: 360, idealWidth: 420, minHeight: 180, idealHeight: 220)
        .calendarColorSchemePreference()
    }
}

/// 显示在 iOS 主界面底部，根据标签栏状态呈现完整数据下载进度。
#if os(iOS)
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
#endif

/// 显示在 macOS 主窗口状态栏中，用于概览完整数据下载进度。
struct FullStoreDownloadMacStatusBar: View {
    let progress: FullStoreDownloadProgress
    let openProgressWindow: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Label(progress.title, systemSymbol: progress.systemSymbol)
                .font(.callout)

            ProgressView(value: progress.fractionCompleted)
                .frame(maxWidth: 180)

            Text(progress.fractionCompleted, format: .percent.precision(.fractionLength(0)))
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Button("查看进度", systemSymbol: .arrowUpForwardApp, action: openProgressWindow)
                .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
        .accessibilityElement(children: .contain)
    }
}

/// 供各下载进度界面复用，用于展示统一的阶段和进度信息。
private struct FullStoreDownloadProgressContent: View {
    let progress: FullStoreDownloadProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(progress.title, systemSymbol: progress.systemSymbol)
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(progress.detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(progress.fractionCompleted, format: .percent.precision(.fractionLength(0)))
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: progress.fractionCompleted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.title)，\(progress.detail)")
        .accessibilityValue(progress.fractionCompleted.formatted(.percent.precision(.fractionLength(0))))
    }
}
