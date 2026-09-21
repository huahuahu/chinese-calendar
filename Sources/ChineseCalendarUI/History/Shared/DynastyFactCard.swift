import SFSafeSymbols
import SwiftUI

/// 朝代详情页中的资料分支入口。
struct DynastyFactCard: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let horizontalLayoutSpacing: CGFloat = 12
        static let valueMinimumWidth: CGFloat = 64
        static let disclosureMinimumSpacing: CGFloat = 12
        static let compactLayoutSpacing: CGFloat = 8
        static let compactDisclosureMinimumSpacing: CGFloat = 8
        static let minimumCardHeight: CGFloat = 64
        static let horizontalPadding: CGFloat = 14
        static let verticalPadding: CGFloat = 12
        static let cardCornerRadius: CGFloat = 20
        static let borderWidth: CGFloat = 1
    }

    let model: DynastyFactCardModel

    var body: some View {
        NavigationLink(value: model.destination) {
            cardLabel
        }
        .buttonStyle(
            HistoryPressButtonStyle(
                cornerRadius: Constants.cardCornerRadius
            )
        )
    }

    private var cardLabel: some View {
        ViewThatFits(in: .horizontal) {
            horizontalLayout
            compactLayout
        }
        .frame(maxWidth: .infinity, minHeight: Constants.minimumCardHeight, alignment: .leading)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
                .stroke(.quaternary, lineWidth: Constants.borderWidth)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilityLabel)
    }

    private var horizontalLayout: some View {
        HStack(alignment: .firstTextBaseline, spacing: Constants.horizontalLayoutSpacing) {
            valueText
                .frame(minWidth: Constants.valueMinimumWidth, alignment: .leading)

            if !model.unit.isEmpty {
                unitText
            }

            Spacer(minLength: Constants.disclosureMinimumSpacing)

            disclosureIndicator
        }
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: Constants.compactLayoutSpacing) {
            HStack(alignment: .firstTextBaseline) {
                valueText

                Spacer(minLength: Constants.compactDisclosureMinimumSpacing)

                disclosureIndicator
            }

            if !model.unit.isEmpty {
                unitText
            }
        }
    }

    private var valueText: some View {
        Text(model.value)
            .font(.title2)
            .fontDesign(.serif)
            .bold()
            .monospacedDigit()
    }

    private var unitText: some View {
        Text(model.unit)
            .font(.subheadline)
            .bold()
    }

    private var disclosureIndicator: some View {
        Image(systemSymbol: .chevronRight)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        DynastyFactCard(
            model: DynastyFactCardModel(
                value: "16",
                unit: "位皇帝",
                accessibilityLabel: "查看明朝 16 位皇帝",
                destination: .emperorList(dynastyID: "ming")
            )
        )
        .padding()
    }
}
