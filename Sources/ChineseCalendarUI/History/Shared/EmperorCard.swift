import SwiftUI

struct EmperorCard: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let rowSpacing: CGFloat = 10
        static let sequenceWidth: CGFloat = 32
        static let sequenceTopPadding: CGFloat = 3
        static let contentSpacing: CGFloat = 8
        static let titleSpacing: CGFloat = 8
        static let compactTitleSpacing: CGFloat = 3
        static let rangeSpacing: CGFloat = 6
        static let rangeMarkerSize: CGFloat = 3
        static let compactRangeSpacing: CGFloat = 4
        static let reignEraSpacing: CGFloat = 6
        static let reignEraHorizontalPadding: CGFloat = 8
        static let reignEraVerticalPadding: CGFloat = 4
        static let reignEraTintOpacity: Double = 0.12
        static let minimumRowHeight: CGFloat = 104
        static let horizontalPadding: CGFloat = 4
        static let verticalPadding: CGFloat = 15
        static let separatorHeight: CGFloat = 1
    }

    let model: EmperorCardModel

    var body: some View {
        HStack(alignment: .top, spacing: Constants.rowSpacing) {
            sequenceLabel
            emperorDetails
        }
        .frame(maxWidth: .infinity, minHeight: Constants.minimumRowHeight, alignment: .leading)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.quaternary)
                .frame(height: Constants.separatorHeight)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilityLabel)
    }

    private var sequenceLabel: some View {
        Text(model.sequenceText)
            .font(.caption.monospacedDigit())
            .fontDesign(.serif)
            .bold()
            .foregroundStyle(.tint)
            .frame(width: Constants.sequenceWidth, alignment: .leading)
            .padding(.top, Constants.sequenceTopPadding)
    }

    private var emperorDetails: some View {
        VStack(alignment: .leading, spacing: Constants.contentSpacing) {
            identitySummary
            reignSummary

            if !model.reignEraNames.isEmpty {
                reignEraTags
            }
        }
    }

    private var identitySummary: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: Constants.titleSpacing) {
                Text(model.displayName)
                    .font(.headline)
                    .fontDesign(.serif)

                if let reliableTitle = model.reliableTitle {
                    Text(reliableTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: Constants.compactTitleSpacing) {
                Text(model.displayName)
                    .font(.headline)
                    .fontDesign(.serif)

                if let reliableTitle = model.reliableTitle {
                    Text(reliableTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var reignSummary: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Constants.rangeSpacing) {
                Text(model.reignRangeText)
                if let durationText = model.durationText {
                    Circle()
                        .fill(.secondary)
                        .frame(
                            width: Constants.rangeMarkerSize,
                            height: Constants.rangeMarkerSize
                        )
                        .accessibilityHidden(true)
                    Text(durationText)
                }
            }

            VStack(alignment: .leading, spacing: Constants.compactRangeSpacing) {
                Text(model.reignRangeText)
                if let durationText = model.durationText {
                    Text(durationText)
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var reignEraTags: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Constants.reignEraSpacing) {
                ForEach(model.reignEraNames.enumerated(), id: \.offset) { _, name in
                    reignEraTag(name)
                }
            }

            VStack(alignment: .leading, spacing: Constants.reignEraSpacing) {
                ForEach(model.reignEraNames.enumerated(), id: \.offset) { _, name in
                    reignEraTag(name)
                }
            }
        }
        .accessibilityLabel("年号：\(model.reignEraNames.joined(separator: "、"))")
    }

    private func reignEraTag(_ name: String) -> some View {
        Text(name)
            .font(.caption)
            .bold()
            .padding(.horizontal, Constants.reignEraHorizontalPadding)
            .padding(.vertical, Constants.reignEraVerticalPadding)
            .foregroundStyle(.tint)
            .background(
                .tint.opacity(Constants.reignEraTintOpacity),
                in: Capsule()
            )
    }
}

#Preview {
    EmperorCard(
        model: EmperorCardModel(
            id: "ming-yingzong",
            sequenceText: "06",
            displayName: "朱祁镇",
            reliableTitle: "英宗",
            reignRangeText: "1436—1449 / 1457—1464",
            durationText: "两度在位 · 22 年",
            reignEraNames: ["正统", "天顺"]
        )
    )
    .padding()
}
