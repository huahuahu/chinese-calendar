import SFSafeSymbols
import SwiftUI

struct DynastyCard: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let rowSpacing: CGFloat = 10
        static let timelineMarkerSize: CGFloat = 10
        static let timelineMarkerBorderWidth: CGFloat = 2
        static let monogramCharacterCount = 2
        static let monogramMinimumScaleFactor: CGFloat = 0.7
        static let monogramSize: CGFloat = 42
        static let monogramCornerRadius: CGFloat = 15
        static let contentSpacing: CGFloat = 5
        static let disclosureMinimumSpacing: CGFloat = 8
        static let minimumRowHeight: CGFloat = 72
        static let horizontalPadding: CGFloat = 10
        static let verticalPadding: CGFloat = 10
        static let separatorHeight: CGFloat = 1
        static let separatorLeadingInset: CGFloat = 21
    }

    let model: DynastyCardModel
    let showsDisclosureIndicator: Bool

    var body: some View {
        HStack(alignment: .center, spacing: Constants.rowSpacing) {
            timelineMarker
            dynastyMonogram
            dynastyDetails

            Spacer(minLength: Constants.disclosureMinimumSpacing)

            if showsDisclosureIndicator {
                disclosureIndicator
            }
        }
        .frame(maxWidth: .infinity, minHeight: Constants.minimumRowHeight, alignment: .leading)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .overlay(alignment: .bottom) {
            rowSeparator
        }
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilityLabel)
    }

    private var timelineMarker: some View {
        Circle()
            .fill(.secondary)
            .frame(
                width: Constants.timelineMarkerSize,
                height: Constants.timelineMarkerSize
            )
            .overlay {
                Circle()
                    .stroke(
                        .background,
                        lineWidth: Constants.timelineMarkerBorderWidth
                    )
            }
            .accessibilityHidden(true)
    }

    private var dynastyMonogram: some View {
        Text(String(model.dynastyName.prefix(Constants.monogramCharacterCount)))
            .font(.title3)
            .fontDesign(.serif)
            .bold()
            .minimumScaleFactor(Constants.monogramMinimumScaleFactor)
            .lineLimit(1)
            .frame(width: Constants.monogramSize, height: Constants.monogramSize)
            .background(
                .background.secondary,
                in: RoundedRectangle(cornerRadius: Constants.monogramCornerRadius)
            )
    }

    private var dynastyDetails: some View {
        VStack(alignment: .leading, spacing: Constants.contentSpacing) {
            if model.dynastyName.count > Constants.monogramCharacterCount {
                Text(model.dynastyName)
                    .font(.headline)
                    .lineLimit(1)
            }

            Text(model.boundaryText)
                .font(.headline)
                .monospacedDigit()

            if let statisticsText = model.statisticsText {
                Text(statisticsText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let unavailableText = model.unavailableText {
                Text(unavailableText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var disclosureIndicator: some View {
        Image(systemSymbol: .chevronRight)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
    }

    private var rowSeparator: some View {
        Rectangle()
            .fill(.quaternary)
            .frame(height: Constants.separatorHeight)
            .padding(.leading, Constants.separatorLeadingInset)
    }
}

#Preview {
    DynastyCard(
        model: DynastyCardModel(
            id: "ming",
            dynastyName: "明",
            boundaryText: "1368—1644",
            statisticsText: "16 位皇帝 · 17 个年号"
        ),
        showsDisclosureIndicator: true
    )
    .padding()
}
