import SwiftUI

/// 显示在 OrthodoxPeriodRow 中，用于突出朝代时间线的统计摘要。
struct DynastySummaryChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption)
            .bold()
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.background, in: Capsule())
    }
}
