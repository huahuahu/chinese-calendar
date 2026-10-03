import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftUI

/// 显示在年份列表和年份选择器中，用于概览一个农历年。
struct LunarYearRow: View {
    let year: ChineseLunarYear

    var body: some View {
        VStack(alignment: .leading) {
            Text(LunarCalendarFormatting.yearTitle(lunarYearNumber: year.lunarYearNumber))
            Text(LunarCalendarFormatting.yearSubtitle(
                stemIndex: year.yearStemIndex,
                branchIndex: year.yearBranchIndex
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("公元前与公元年份") {
    let years = [
        ChineseLunarYear(
            lunarYearNumber: -221,
            yearStemIndex: 6,
            yearBranchIndex: 4
        ),
        ChineseLunarYear(
            lunarYearNumber: 618,
            yearStemIndex: 4,
            yearBranchIndex: 2
        ),
        ChineseLunarYear(
            lunarYearNumber: 2026,
            yearStemIndex: 2,
            yearBranchIndex: 6
        )
    ]

    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(years, id: \.lunarYearNumber) { year in
                    LunarYearRow(year: year)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("年份")
    }
}
