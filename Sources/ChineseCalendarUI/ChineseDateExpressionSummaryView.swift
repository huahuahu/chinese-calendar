import ChineseCalendarPersistence
import SwiftUI

struct ChineseDateExpressionSummaryView: View {
    let title: String
    let date: ChineseDateExpression

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .bold()

            Text(date.sourceText)
                .font(.headline)

            Text(precisionText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let note = date.note {
                Text(note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var precisionText: String {
        switch date.precision {
        case .year:
            indexText(prefix: "年精度")
        case .month:
            indexText(prefix: "月精度")
        case .day:
            indexText(prefix: "日精度")
        case .range:
            rangeText
        case .unknown:
            "精度未知"
        }
    }

    private var rangeText: String {
        guard let range = date.uncertainRange else {
            return "范围精度"
        }

        return "范围精度 · \(boundText(range.lowerBound)) 到 \(boundText(range.upperBound))"
    }

    private func indexText(prefix: String) -> String {
        guard let index = date.index else {
            return prefix
        }

        return "\(prefix) · index \(index)"
    }

    private func boundText(_ bound: ChineseDateBound) -> String {
        "\(bound.precision.rawValue) \(bound.index)"
    }
}
