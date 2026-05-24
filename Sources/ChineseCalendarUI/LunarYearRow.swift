import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftUI

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
