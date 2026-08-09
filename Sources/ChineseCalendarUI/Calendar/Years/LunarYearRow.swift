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
