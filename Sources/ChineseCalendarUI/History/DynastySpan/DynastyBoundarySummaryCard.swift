import SwiftUI

/// 朝代起讫页中用于对照朝代自称范围和当前正统期的两行卡片。
struct DynastyBoundarySummaryCard: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let cardSpacing: CGFloat = 0
        static let horizontalLayoutSpacing: CGFloat = 12
        static let labelWidth: CGFloat = 82
        static let stackedLayoutSpacing: CGFloat = 6
        static let horizontalPadding: CGFloat = 17
        static let verticalPadding: CGFloat = 15
        static let separatorHeight: CGFloat = 1
        static let cardCornerRadius: CGFloat = 22
        static let borderWidth: CGFloat = 1
    }

    let claimedRange: String
    let orthodoxRange: String

    var body: some View {
        VStack(spacing: Constants.cardSpacing) {
            rangeRow(title: "朝代自称", value: claimedRange)

            Rectangle()
                .fill(.quaternary)
                .frame(height: Constants.separatorHeight)

            rangeRow(title: "正统时间线", value: orthodoxRange)
        }
        .background(
            .background,
            in: RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
                .stroke(.quaternary, lineWidth: Constants.borderWidth)
        }
        .accessibilityElement(children: .combine)
    }

    private func rangeRow(title: String, value: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: Constants.horizontalLayoutSpacing) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: Constants.labelWidth, alignment: .leading)
                Text(value)
                    .font(.subheadline.monospacedDigit())
                    .fontDesign(.serif)
                    .bold()
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: Constants.stackedLayoutSpacing) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.monospacedDigit())
                    .fontDesign(.serif)
                    .bold()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
    }
}

#Preview {
    DynastyBoundarySummaryCard(
        claimedRange: "1368—1644",
        orthodoxRange: "1368—1644"
    )
    .padding()
    .background(.background.secondary)
}
