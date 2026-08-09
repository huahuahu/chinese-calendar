import ChineseCalendarPersistence
import SwiftUI

/// 显示在历史时间线中，用于概览一个正统时期及其朝代信息。
struct OrthodoxPeriodRow: View {
    let period: OrthodoxPeriod

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(sequenceText)
                .font(.headline)
                .bold()
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .background(.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 8) {
                Text(period.dynasty?.name ?? period.segmentName)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    DynastySummaryChip(title: "\(emperorCount) 位皇帝")
                    DynastySummaryChip(title: "\(reignEraCount) 个年号")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }

    private var sequenceText: String {
        let sequenceNumber = period.sequenceIndex + 1
        return sequenceNumber < 10 ? "0\(sequenceNumber)" : "\(sequenceNumber)"
    }

    private var subtitle: String {
        let segmentText = period.segmentName
        let startText = period.startBoundary?.date.sourceText ?? "起点不详"
        let endText = period.endBoundary?.date.sourceText ?? "终点不详"
        return "\(segmentText) · \(startText) - \(endText)"
    }

    private var emperorCount: Int {
        period.dynasty?.emperors.count ?? 0
    }

    private var reignEraCount: Int {
        period.dynasty?.emperors.reduce(0) { count, emperor in
            count + emperor.reignEras.count
        } ?? 0
    }
}
