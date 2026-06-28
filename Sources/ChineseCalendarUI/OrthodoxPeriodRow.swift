import ChineseCalendarPersistence
import SwiftUI

struct OrthodoxPeriodRow: View {
    let period: OrthodoxPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(period.dynasty?.name ?? period.segmentName)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let segmentText = period.segmentName
        let startText = period.startBoundary?.date.sourceText ?? "起点不详"
        let endText = period.endBoundary?.date.sourceText ?? "终点不详"
        return "\(segmentText) · \(startText) - \(endText)"
    }
}
