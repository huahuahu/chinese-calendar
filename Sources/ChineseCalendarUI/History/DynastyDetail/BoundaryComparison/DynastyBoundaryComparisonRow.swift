import ChineseCalendarPersistence
import SwiftUI

/// 显示在边界比较卡片中，用于并列呈现起点或终点的两种日期口径。
struct DynastyBoundaryComparisonRow: View {
    let title: String
    let claimedDate: ChineseDateExpression
    let orthodoxDate: ChineseDateExpression?

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)
                .frame(width: 54, alignment: .leading)
                .padding(.leading, 12)
                .padding(.vertical, 12)

            Divider()

            DynastyBoundaryComparisonCell(date: claimedDate)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            DynastyBoundaryComparisonCell(date: orthodoxDate)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
