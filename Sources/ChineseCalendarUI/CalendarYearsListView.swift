import ChineseCalendarPersistence
import SwiftUI

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
