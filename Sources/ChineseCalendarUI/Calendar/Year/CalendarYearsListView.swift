import ChineseCalendarPersistence
import SwiftUI

/// 用于展示可浏览的农历年份列表，并将选中年份交给上层导航。
struct CalendarYearsListView: View {
    let years: [ChineseLunarYear]

    var body: some View {
        List {
            Section("农历年") {
                ForEach(years, id: \.lunarYearNumber) { year in
                    NavigationLink(value: CalendarDestination.lunarYear(year.lunarYearNumber)) {
                        LunarYearRow(year: year)
                    }
                }
            }
        }
        .navigationTitle("年份")
    }
}

#Preview("跨时代年份", traits: .sampleData) {
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
        CalendarYearsListView(years: years)
            .navigationDestination(for: CalendarDestination.self) { destination in
                CalendarDestinationView(destination: destination)
            }
    }
}

#Preview("有可能空白") {
    NavigationStack {
        CalendarYearsListView(years: [])
    }
}
