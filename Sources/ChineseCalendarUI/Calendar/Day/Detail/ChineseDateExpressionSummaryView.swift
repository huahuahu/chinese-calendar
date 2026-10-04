import ChineseCalendarPersistence
import SwiftUI

/// 用于概览中国历日期表达式，供日期详情界面组合使用。
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

#Preview("日期精度与长备注") {
    let dayExpression = ChineseDateExpression(
        id: "preview-day-expression",
        precision: .day,
        index: 315,
        sourceText: "丙午年正月十五",
        note: "这是一段较长的说明文字，用于检查来源备注换行后，卡片是否仍然保持清晰的层级与间距。"
    )
    let rangeExpression = ChineseDateExpression(
        id: "preview-range-expression",
        precision: .range,
        uncertainRange: ChineseDateRange(
            id: "preview-date-range",
            lowerBound: ChineseDateBound(
                id: "preview-range-lower-bound",
                precision: .year,
                index: 220
            ),
            upperBound: ChineseDateBound(
                id: "preview-range-upper-bound",
                precision: .year,
                index: 221
            )
        ),
        sourceText: "约公元220年至221年"
    )
    let unknownExpression = ChineseDateExpression(
        id: "preview-unknown-expression",
        precision: .unknown,
        sourceText: "年代不详"
    )

    NavigationStack {
        ScrollView {
            VStack(spacing: 16) {
                ChineseDateExpressionSummaryView(
                    title: "日精度",
                    date: dayExpression
                )
                ChineseDateExpressionSummaryView(
                    title: "范围精度",
                    date: rangeExpression
                )
                ChineseDateExpressionSummaryView(
                    title: "没有备注",
                    date: unknownExpression
                )
            }
            .padding()
        }
        .navigationTitle("日期表达")
    }
}

#Preview("有可能空白 · 无索引或备注") {
    NavigationStack {
        ScrollView {
            VStack(spacing: 16) {
                ChineseDateExpressionSummaryView(
                    title: "只有年份",
                    date: ChineseDateExpression(
                        id: "preview-year-expression",
                        precision: .year,
                        index: 2026,
                        sourceText: "丙午年"
                    )
                )
                ChineseDateExpressionSummaryView(
                    title: "月份索引缺失",
                    date: ChineseDateExpression(
                        id: "preview-month-expression",
                        precision: .month,
                        sourceText: "正月"
                    )
                )
                ChineseDateExpressionSummaryView(
                    title: "范围边界缺失",
                    date: ChineseDateExpression(
                        id: "preview-missing-range-expression",
                        precision: .range,
                        sourceText: "约在年初"
                    )
                )
            }
            .padding()
        }
        .navigationTitle("日期表达")
    }
}
