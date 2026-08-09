import ChineseCalendarPersistence
import SwiftUI

/// 显示在边界比较列表中，用于汇总一个正统时期的起止边界。
struct DynastyBoundaryComparisonCard: View {
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
        VStack(alignment: .leading, spacing: 12) {
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

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: 54)
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
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.quaternary, lineWidth: 1)
            }

            if let differenceSummary {
                Text(differenceSummary)
                    .font(.callout)
                    .bold()
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            }

            DynastyBoundarySourceDetailsView(
                claimedStartDate: claimedStartDate,
                orthodoxStartDate: orthodoxStartDate,
                claimedEndDate: claimedEndDate,
                orthodoxEndDate: orthodoxEndDate,
                note: note
            )
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 24))
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
    }
}
