import SwiftUI

/// 年号详情中的起止边界卡；常规宽度并排，较大字号下自动改为上下排列。
struct ReignEraBoundaryCard: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let contentPadding: CGFloat = 18
        static let cardCornerRadius: CGFloat = 22
        static let layoutSpacing: CGFloat = 0
        static let connectorHeight: CGFloat = 1
        static let markerSize: CGFloat = 8
        static let markerBorderWidth: CGFloat = 2
        static let connectorWidth: CGFloat = 70
        static let valueColumnSpacing: CGFloat = 6
        static let valueRowSpacing: CGFloat = 12
        static let valueRowMinimumSpacerLength: CGFloat = 12
        static let valueDetailSpacing: CGFloat = 3
        static let valueRowVerticalPadding: CGFloat = 12
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let startValue: String
    let startPrecision: String
    let endValue: String
    let endPrecision: String

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                stackedLayout
            } else {
                ViewThatFits(in: .horizontal) {
                    horizontalLayout
                    stackedLayout
                }
            }
        }
        .padding(Constants.contentPadding)
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
        )
        .accessibilityElement(children: .combine)
    }

    private var horizontalLayout: some View {
        HStack(spacing: Constants.layoutSpacing) {
            valueColumn(label: "开始", value: startValue, precision: startPrecision)

            ZStack {
                Rectangle()
                    .fill(.quaternary)
                    .frame(height: Constants.connectorHeight)

                Circle()
                    .fill(.tint)
                    .frame(width: Constants.markerSize, height: Constants.markerSize)
                    .overlay {
                        Circle()
                            .stroke(
                                .background.secondary,
                                lineWidth: Constants.markerBorderWidth
                            )
                    }
            }
            .frame(width: Constants.connectorWidth)
            .accessibilityHidden(true)

            valueColumn(label: "结束", value: endValue, precision: endPrecision)
        }
    }

    private var stackedLayout: some View {
        VStack(spacing: Constants.layoutSpacing) {
            valueRow(label: "开始", value: startValue, precision: startPrecision)
            Divider()
            valueRow(label: "结束", value: endValue, precision: endPrecision)
        }
    }

    private func valueColumn(label: String, value: String, precision: String) -> some View {
        VStack(spacing: Constants.valueColumnSpacing) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.monospacedDigit())
                .fontDesign(.serif)
                .bold()
            Text(precision)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func valueRow(label: String, value: String, precision: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Constants.valueRowSpacing) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: Constants.valueRowMinimumSpacerLength)

            VStack(alignment: .trailing, spacing: Constants.valueDetailSpacing) {
                Text(value)
                    .font(.headline.monospacedDigit())
                    .bold()
                Text(precision)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Constants.valueRowVerticalPadding)
    }
}

#Preview {
    ReignEraBoundaryCard(
        startValue: "1403",
        startPrecision: "年精度",
        endValue: "1424",
        endPrecision: "年精度"
    )
    .padding()
}

#Preview("辅助功能字号") {
    ReignEraBoundaryCard(
        startValue: "1403",
        startPrecision: "年精度",
        endValue: "1424",
        endPrecision: "年精度"
    )
    .padding()
    .environment(\.dynamicTypeSize, .accessibility3)
}
