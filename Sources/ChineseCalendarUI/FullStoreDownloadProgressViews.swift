import SwiftUI

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
                    "没有正在下载的数据",
                    systemImage: "checkmark.circle",
                    description: Text("开始下载完整日期数据后，进度会显示在这里。")
                )
                .padding()
            }
        }
        .frame(minWidth: 360, idealWidth: 420, minHeight: 180, idealHeight: 220)
    }
}

struct FullStoreDownloadBottomProgressView: View {
    let progress: FullStoreDownloadProgress

    @State private var isExpanded = false

    var body: some View {
        Button {
            withAnimation(.snappy) {
                isExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: progress.systemImage)
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

                    Image(systemName: "chevron.up")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(isExpanded ? .zero : .degrees(180))
                }

                if isExpanded {
                    Text(progress.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.title)，\(progress.detail)")
        .accessibilityValue(progress.fractionCompleted.formatted(.percent.precision(.fractionLength(0))))
    }
}

struct FullStoreDownloadMacStatusBar: View {
    let progress: FullStoreDownloadProgress
    let openProgressWindow: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Label(progress.title, systemImage: progress.systemImage)
                .font(.callout)

            ProgressView(value: progress.fractionCompleted)
                .frame(maxWidth: 180)

            Text(progress.fractionCompleted, format: .percent.precision(.fractionLength(0)))
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Button("查看进度", systemImage: "arrow.up.forward.app", action: openProgressWindow)
                .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
        .accessibilityElement(children: .contain)
    }
}

private struct FullStoreDownloadProgressContent: View {
    let progress: FullStoreDownloadProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(progress.title, systemImage: progress.systemImage)
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
