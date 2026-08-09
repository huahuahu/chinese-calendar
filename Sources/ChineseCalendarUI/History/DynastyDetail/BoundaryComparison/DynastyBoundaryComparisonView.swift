import ChineseCalendarPersistence
import SwiftUI

/// 显示在 DynastyDetailView 中，用于比较朝代各正统时期的起止边界。
struct DynastyBoundaryComparisonView: View {
    let dynasty: Dynasty
    let orthodoxPeriods: [OrthodoxPeriod]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("时间边界")
                    .font(.title2)
                    .bold()

                Text("对比朝代自称起止与正统时间线采用的边界。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if orthodoxPeriods.isEmpty {
                DynastyBoundaryComparisonCard(
                    title: "正统期",
                    traditionName: nil,
                    claimedStartDate: dynasty.claimedStartDate,
                    orthodoxStartDate: nil,
                    claimedEndDate: dynasty.claimedEndDate,
                    orthodoxEndDate: nil,
                    startDifferenceText: nil,
                    endDifferenceText: nil,
                    note: "当前 SwiftData store 还没有为这个朝代关联正统开始和结束边界。"
                )
            } else {
                ForEach(orthodoxPeriods, id: \.id) { period in
                    DynastyBoundaryComparisonCard(
                        title: periodTitle(for: period),
                        traditionName: period.tradition?.name,
                        claimedStartDate: dynasty.claimedStartDate,
                        orthodoxStartDate: period.startBoundary?.date,
                        claimedEndDate: dynasty.claimedEndDate,
                        orthodoxEndDate: period.endBoundary?.date,
                        startDifferenceText: differenceText(
                            claimed: dynasty.claimedStartDate,
                            orthodox: period.startBoundary?.date
                        ),
                        endDifferenceText: differenceText(
                            claimed: dynasty.claimedEndDate,
                            orthodox: period.endBoundary?.date
                        ),
                        note: period.note
                    )
                }
            }
        }
    }

    private func periodTitle(for period: OrthodoxPeriod) -> String {
        if period.segmentName == dynasty.name || period.segmentName == dynasty.shortName {
            return "正统期"
        }

        return "正统期 · \(period.segmentName)"
    }

    private func differenceText(
        claimed: ChineseDateExpression,
        orthodox: ChineseDateExpression?
    ) -> String? {
        guard let orthodox else {
            return nil
        }

        guard claimed.precision == orthodox.precision else {
            return "边界精度不同"
        }

        guard let claimedIndex = claimed.index, let orthodoxIndex = orthodox.index else {
            return claimed.sourceText == orthodox.sourceText ? "同一来源文本" : "边界来源不同"
        }

        let difference = orthodoxIndex - claimedIndex

        guard difference != 0 else {
            return claimed.precision == .year ? "同年" : "同一边界"
        }

        guard claimed.precision == .year else {
            return "边界不同"
        }

        return difference > 0 ? "正统晚 \(difference) 年" : "正统早 \(abs(difference)) 年"
    }
}
