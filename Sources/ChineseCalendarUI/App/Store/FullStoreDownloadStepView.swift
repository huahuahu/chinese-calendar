import SFSafeSymbols
import SwiftUI

/// 每一行独立表达等待、进行中或完成；只有下载行有可量化的进度。
struct FullStoreDownloadStepView: View {
    let phase: FullStoreDownloadPhase
    let status: FullStoreDownloadPhase.Status
    let detail: LocalizedStringResource?
    let downloadFraction: Double?

    @ScaledMetric(relativeTo: .headline) private var markerSize = Constants.markerSize

    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let markerSize: CGFloat = 24
        static let spacing: CGFloat = 16
        static let contentSpacing: CGFloat = 8
        static let bottomSpacing: CGFloat = 28
        static let connectorWidth: CGFloat = 2
        static let connectorSpacing: CGFloat = 6
    }

    var body: some View {
        HStack(alignment: .top, spacing: Constants.spacing) {
            marker
                .frame(width: markerSize, height: markerSize)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Constants.contentSpacing) {
                Text(phase.title)
                    .font(.headline)
                    .foregroundStyle(titleStyle)

                if let detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(status == .completed ? "已完成" : "等待开始")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let downloadFraction {
                    ProgressView(value: downloadFraction)
                        .accessibilityHidden(true)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, hasNextStep ? Constants.bottomSpacing : 0)
        .background(alignment: .leading) {
            if hasNextStep {
                Rectangle()
                    .fill(status == .completed ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary))
                    .frame(width: Constants.connectorWidth)
                    .padding(.leading, (markerSize - Constants.connectorWidth) / 2)
                    .padding(.top, markerSize + Constants.connectorSpacing)
                    .padding(.bottom, Constants.connectorSpacing)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(status == .current ? Text("进行中") : Text(""))
    }

    private var hasNextStep: Bool {
        phase != FullStoreDownloadPhase.allCases.last
    }

    @ViewBuilder
    private var marker: some View {
        switch status {
        case .pending:
            Image(systemSymbol: .circle)
                .font(.title3)
                .foregroundStyle(.tertiary)
        case .current:
            ProgressView()
                .tint(.accentColor)
        case .completed:
            Image(systemSymbol: .checkmarkCircleFill)
                .font(.title3)
                .foregroundStyle(.tint)
        }
    }

    private var titleStyle: AnyShapeStyle {
        switch status {
        case .pending: AnyShapeStyle(.secondary)
        case .current: AnyShapeStyle(.tint)
        case .completed: AnyShapeStyle(.primary)
        }
    }
}
