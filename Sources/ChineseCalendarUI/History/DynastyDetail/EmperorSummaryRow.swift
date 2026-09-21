import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

/// 显示在 DynastyDetailView 的皇帝列表中，用于概览一位皇帝。
struct EmperorSummaryRow: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let rowSpacing: CGFloat = 12
        static let contentSpacing: CGFloat = 4
        static let disclosureMinimumSpacing: CGFloat = 12
        static let cardCornerRadius: CGFloat = 12
    }

    let emperor: Emperor

    var body: some View {
        HStack(spacing: Constants.rowSpacing) {
            emperorDetails

            Spacer(minLength: Constants.disclosureMinimumSpacing)

            disclosureIndicator
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
        )
        .accessibilityElement(children: .combine)
    }

    private var emperorDetails: some View {
        VStack(alignment: .leading, spacing: Constants.contentSpacing) {
            Text(emperor.displayName)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var disclosureIndicator: some View {
        Image(systemSymbol: .chevronRight)
            .font(.footnote)
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }

    private var subtitle: String {
        let names = [
            emperor.personalName,
            emperor.templeName,
            emperor.posthumousName
        ]
        .compactMap(\.self)

        let nameText = names.isEmpty ? "未记录别名" : names.joined(separator: " · ")
        return "\(nameText) · \(emperor.reignSegments.count) 段在位 · \(emperor.reignEras.count) 个年号"
    }
}

#Preview {
    let sample = HistoryPreviewData.makeSample()

    EmperorSummaryRow(emperor: sample.emperor)
        .padding()
}
