import SFSafeSymbols
import SwiftUI

struct ReignEraCard: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let horizontalLayoutSpacing: CGFloat = 8
        static let rangeMinimumWidth: CGFloat = 82
        static let contentSpacing: CGFloat = 6
        static let titleSpacing: CGFloat = 8
        static let disclosureMinimumSpacing: CGFloat = 8
        static let compactLayoutSpacing: CGFloat = 10
        static let minimumRowHeight: CGFloat = 82
        static let verticalPadding: CGFloat = 10
        static let trailingPadding: CGFloat = 5
        static let contentCornerRadius: CGFloat = 18
        static let timelineMarkerSize: CGFloat = 9
        static let timelineMarkerBorderWidth: CGFloat = 2
        static let timelineRailWidth: CGFloat = 18
    }

    let model: ReignEraCardModel

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalLayout
            compactLayout
        }
        .frame(maxWidth: .infinity, minHeight: Constants.minimumRowHeight, alignment: .leading)
        .padding(.vertical, Constants.verticalPadding)
        .padding(.trailing, Constants.trailingPadding)
        .contentShape(.rect(cornerRadius: Constants.contentCornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilityLabel)
    }

    private var horizontalLayout: some View {
        HStack(alignment: .center, spacing: Constants.horizontalLayoutSpacing) {
            timelineRail

            usageRangeText
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(minWidth: Constants.rangeMinimumWidth, alignment: .leading)

            eraDetails

            Spacer(minLength: Constants.disclosureMinimumSpacing)

            disclosureIndicator
        }
    }

    private var compactLayout: some View {
        HStack(alignment: .center, spacing: Constants.compactLayoutSpacing) {
            timelineRail

            VStack(alignment: .leading, spacing: Constants.contentSpacing) {
                usageRangeText
                eraDetails
            }

            Spacer(minLength: Constants.disclosureMinimumSpacing)

            disclosureIndicator
        }
    }

    private var usageRangeText: some View {
        Text(model.usageRangeText)
            .font(.caption.monospacedDigit())
            .fontDesign(.serif)
            .foregroundStyle(.secondary)
    }

    private var eraDetails: some View {
        VStack(alignment: .leading, spacing: Constants.contentSpacing) {
            eraTitle

            Text(model.emperorText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var eraTitle: some View {
        HStack(alignment: .firstTextBaseline, spacing: Constants.titleSpacing) {
            Text(model.name)
                .font(.title3)
                .fontDesign(.serif)
                .bold()

            if let durationText = model.durationText {
                Text(durationText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var timelineRail: some View {
        Circle()
            .fill(.tint)
            .frame(width: Constants.timelineMarkerSize, height: Constants.timelineMarkerSize)
            .overlay {
                Circle()
                    .stroke(
                        .background,
                        lineWidth: Constants.timelineMarkerBorderWidth
                    )
            }
            .frame(width: Constants.timelineRailWidth)
            .accessibilityHidden(true)
    }

    private var disclosureIndicator: some View {
        Image(systemSymbol: .chevronRight)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
    }
}

#Preview {
    ReignEraCard(
        model: ReignEraCardModel(
            id: "yongle",
            name: "永乐",
            usageRangeText: "1403—1424",
            durationText: "22 年",
            emperorName: "朱棣",
            emperorTitle: "成祖"
        )
    )
    .padding()
}
