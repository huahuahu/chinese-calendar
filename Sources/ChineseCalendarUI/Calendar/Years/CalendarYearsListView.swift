import ChineseCalendarPersistence
import SwiftUI

/// 用于展示可浏览的农历年份列表，并将选中年份交给上层导航。
struct CalendarYearsListView: View {
    let years: [ChineseLunarYear]

    var body: some View {
        List {
            Section("农历年") {
                ForEach(years, id: \.lunarYearNumber) { year in
                    NavigationLink(value: CalendarRoute.lunarYear(year.lunarYearNumber)) {
                        LunarYearRow(year: year)
                    }
                }
            }
        }
        .navigationTitle("年份")
    }
}
