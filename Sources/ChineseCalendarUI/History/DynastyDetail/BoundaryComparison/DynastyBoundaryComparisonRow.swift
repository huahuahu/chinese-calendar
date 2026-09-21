import ChineseCalendarPersistence
import SwiftUI

/// 显示在边界比较卡片中，用于并列呈现起点或终点的两种日期口径。
struct DynastyBoundaryComparisonRow: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let rowSpacing: CGFloat = 0
        static let titleWidth: CGFloat = 54
        static let titleLeadingPadding: CGFloat = 12
        static let rowVerticalPadding: CGFloat = 12
    }

    let title: String
    let claimedDate: ChineseDateExpression
    let orthodoxDate: ChineseDateExpression?

    var body: some View {
        HStack(spacing: Constants.rowSpacing) {
            Text(title)
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)
                .frame(width: Constants.titleWidth, alignment: .leading)
                .padding(.leading, Constants.titleLeadingPadding)
                .padding(.vertical, Constants.rowVerticalPadding)

            Divider()

            DynastyBoundaryComparisonCell(date: claimedDate)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            DynastyBoundaryComparisonCell(date: orthodoxDate)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    let sample = HistoryPreviewData.makeSample()

    DynastyBoundaryComparisonRow(
        title: "开始",
        claimedDate: sample.dynasty.claimedStartDate,
        orthodoxDate: sample.period.startBoundary?.date
    )
    .padding()
}
