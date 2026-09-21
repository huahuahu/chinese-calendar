import ChineseCalendarPersistence
import SwiftUI

/// 显示在边界比较列表中，用于汇总一个正统时期的起止边界。
struct DynastyBoundaryComparisonCard: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let contentSpacing: CGFloat = 12
        static let comparisonSpacing: CGFloat = 0
        static let rowTitleWidth: CGFloat = 54
        static let comparisonCornerRadius: CGFloat = 18
        static let borderWidth: CGFloat = 1
        static let summaryHorizontalPadding: CGFloat = 12
        static let summaryVerticalPadding: CGFloat = 10
        static let summaryTintOpacity: Double = 0.12
        static let summaryCornerRadius: CGFloat = 16
        static let cardCornerRadius: CGFloat = 24
    }

    let title: String
    let traditionName: String?
    let claimedStartDate: ChineseDateExpression
    let orthodoxStartDate: ChineseDateExpression?
    let claimedEndDate: ChineseDateExpression
    let orthodoxEndDate: ChineseDateExpression?
    let startDifferenceText: String?
    let endDifferenceText: String?
    let note: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.contentSpacing) {
            cardHeader
            comparisonTable

            if let differenceSummary {
                differenceSummaryBanner(differenceSummary)
            }

            sourceDetails
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
        )
    }

    private var cardHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)

            Spacer()

            if let traditionName {
                Text(traditionName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var comparisonTable: some View {
        VStack(spacing: Constants.comparisonSpacing) {
            HStack(spacing: Constants.comparisonSpacing) {
                Color.clear
                    .frame(width: Constants.rowTitleWidth)
                    .accessibilityHidden(true)

                tableHeader("自称")
                tableHeader("正统")
            }

            Divider()

            DynastyBoundaryComparisonRow(
                title: "开始",
                claimedDate: claimedStartDate,
                orthodoxDate: orthodoxStartDate
            )

            Divider()

            DynastyBoundaryComparisonRow(
                title: "结束",
                claimedDate: claimedEndDate,
                orthodoxDate: orthodoxEndDate
            )
        }
        .background(
            .background,
            in: RoundedRectangle(cornerRadius: Constants.comparisonCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Constants.comparisonCornerRadius)
                .stroke(.quaternary, lineWidth: Constants.borderWidth)
        }
    }

    private func differenceSummaryBanner(_ summary: String) -> some View {
        Text(summary)
            .font(.callout)
            .bold()
            .foregroundStyle(.green)
            .padding(.horizontal, Constants.summaryHorizontalPadding)
            .padding(.vertical, Constants.summaryVerticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                .green.opacity(Constants.summaryTintOpacity),
                in: RoundedRectangle(cornerRadius: Constants.summaryCornerRadius)
            )
    }

    private var sourceDetails: some View {
        DynastyBoundarySourceDetailsView(
            claimedStartDate: claimedStartDate,
            orthodoxStartDate: orthodoxStartDate,
            claimedEndDate: claimedEndDate,
            orthodoxEndDate: orthodoxEndDate,
            note: note
        )
    }

    private var differenceSummary: String? {
        let parts = [
            startDifferenceText.map { "开始\($0)" },
            endDifferenceText.map { "结束\($0)" }
        ].compactMap(\.self)

        return parts.isEmpty ? nil : parts.joined(separator: "，")
    }

    private func tableHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .bold()
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.summaryHorizontalPadding)
            .padding(.vertical, Constants.summaryVerticalPadding)
    }
}

#Preview {
    let sample = HistoryPreviewData.makeSample()

    DynastyBoundaryComparisonCard(
        title: "正统期",
        traditionName: sample.tradition.name,
        claimedStartDate: sample.dynasty.claimedStartDate,
        orthodoxStartDate: sample.period.startBoundary?.date,
        claimedEndDate: sample.dynasty.claimedEndDate,
        orthodoxEndDate: sample.period.endBoundary?.date,
        startDifferenceText: "同年",
        endDifferenceText: "同年",
        note: sample.period.note
    )
    .padding()
}
