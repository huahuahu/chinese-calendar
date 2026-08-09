import ChineseCalendarPersistence
import SwiftUI

/// 显示在边界比较行中，用于呈现单一日期来源的边界值。
struct DynastyBoundaryComparisonCell: View {
    let date: ChineseDateExpression?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(primaryText)
                .font(.headline)
                .bold()

            Text(precisionText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var primaryText: String {
        guard let date else {
            return "不详"
        }

        guard let index = date.index else {
            return date.sourceText
        }

        switch date.precision {
        case .year:
            return "\(index)"
        case .month:
            return "月序 \(index)"
        case .day:
            return "日序 \(index)"
        case .range, .unknown:
            return date.sourceText
        }
    }

    private var precisionText: String {
        guard let date else {
            return "当前数据缺失"
        }

        switch date.precision {
        case .year:
            return "年精度"
        case .month:
            return "月精度"
        case .day:
            return "日精度"
        case .range:
            return "范围精度"
        case .unknown:
            return "精度未知"
        }
    }
}
