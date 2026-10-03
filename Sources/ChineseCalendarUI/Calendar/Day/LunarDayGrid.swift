import ChineseCalendarLogging
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 显示指定农历月的所有日期；选择与今天均来自日历功能环境。
struct LunarDayGrid: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let contentSpacing: CGFloat = 12
        static let cornerRadius: CGFloat = 28
    }

    @Environment(CalendarSelection.self) private var selection
    @Environment(CalendarToday.self) private var today
    @Environment(\.calendarStoreContentLevel) private var storeContentLevel

    let month: ChineseLunarMonth

    @Query private var days: [ChineseLunarDay]

    init(month: ChineseLunarMonth) {
        self.month = month

        let lunarMonthIndex = month.lunarMonthIndex
        _days = Query(
            filter: ChineseCalendarRelationshipPredicates.days(inMonth: lunarMonthIndex),
            sort: \ChineseLunarDay.dayNumberInMonth
        )
    }

    var body: some View {
        Group {
            if days.isEmpty {
                ContentUnavailableView(
                    label: {
                        Label(emptyStateTitle, systemSymbol: emptyStateSystemSymbol)
                    },
                    description: {
                        Text(emptyStateDescription)
                    }
                )
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: Constants.contentSpacing) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("农历月格")
                            .font(.title2)
                            .bold()

                        Spacer()

                        Text("连续日序")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    LunarDayGridLayout {
                        ForEach(days, id: \.dayIndex) { day in
                            Button {
                                selection.select(dayIndex: day.dayIndex)
                            } label: {
                                LunarDayGridCell(
                                    day: day,
                                    isSelected: day.dayIndex == selection.selectedDayIndex,
                                    isToday: day.calendarDay?.julianDayNumber == today.julianDayNumber
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
        }
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: Constants.cornerRadius)
        )
        .onAppear(perform: finishPendingMonthSwitch)
        .onChange(of: days.map(\.dayIndex)) {
            finishPendingMonthSwitch()
        }
    }

    private var emptyStateTitle: String {
        switch storeContentLevel {
        case .base:
            "完整日期数据尚未下载"
        case .full:
            "没有日期数据"
        }
    }

    private var emptyStateSystemSymbol: SFSymbol {
        switch storeContentLevel {
        case .base:
            .arrowDownCircle
        case .full:
            .calendarBadgeExclamationmark
        }
    }

    private var emptyStateDescription: String {
        switch storeContentLevel {
        case .base:
            "请先下载完整日期数据。"
        case .full:
            "这个月份暂时没有可显示的日级记录。"
        }
    }

    private func finishPendingMonthSwitch() {
        let performanceSignposts = ChineseCalendarPerformanceSignposts.shared
        performanceSignposts.monthDaysAvailable(
            monthIndex: month.lunarMonthIndex,
            dayCount: days.count
        )
        performanceSignposts.endMonthSwitch(
            monthIndex: month.lunarMonthIndex,
            dayCount: days.count,
            selectedDayIndex: selection.selectedDayIndex
        )
    }
}

#Preview("30 天与选中日", traits: .sampleData) {
    NavigationStack {
        ScrollView {
            LunarDayGrid(
                month: ChineseLunarMonth(
                    lunarMonthIndex: 3,
                    monthNumberInYear: 1,
                    isLeapMonth: false,
                    dayCount: 30,
                    monthStemIndex: 2,
                    monthBranchIndex: 2,
                    chineseLunarYear: ChineseLunarYear(lunarYearNumber: 2026, yearStemIndex: 0, yearBranchIndex: 0)
                )
            )
            .padding()
        }
        .navigationTitle("日期网格")
    }
}

#Preview("有可能空白", traits: .emptySampleData) {
    NavigationStack {
        ScrollView {
            LunarDayGrid(
                month: ChineseLunarMonth(
                    lunarMonthIndex: 3,
                    monthNumberInYear: 1,
                    isLeapMonth: false,
                    dayCount: 30,
                    monthStemIndex: 2,
                    monthBranchIndex: 2,
                    chineseLunarYear: ChineseLunarYear(lunarYearNumber: 2026, yearStemIndex: 0, yearBranchIndex: 0)
                )
            )
            .padding()
        }
        .navigationTitle("日期网格")
    }
}

#Preview("29 天的小月", traits: .sampleData) {
    NavigationStack {
        ScrollView {
            LunarDayGrid(month: ChineseLunarMonth(
                lunarMonthIndex: 4,
                monthNumberInYear: 2,
                isLeapMonth: false,
                dayCount: 29,
                monthStemIndex: 3,
                monthBranchIndex: 3,
                chineseLunarYear: ChineseLunarYear(lunarYearNumber: 2026, yearStemIndex: 0, yearBranchIndex: 0)
            ))
            .padding()
        }
        .navigationTitle("日期网格")
    }
}

#Preview("有可能空白 · 未下载完整日期", traits: .emptySampleData) {
    NavigationStack {
        ScrollView {
            LunarDayGrid(month: ChineseLunarMonth(
                lunarMonthIndex: 6,
                monthNumberInYear: 1,
                isLeapMonth: false,
                dayCount: 30,
                monthStemIndex: 5,
                monthBranchIndex: 5,
                chineseLunarYear: ChineseLunarYear(lunarYearNumber: 2027, yearStemIndex: 0, yearBranchIndex: 0)
            ))
            .environment(\.calendarStoreContentLevel, .base)
            .padding()
        }
        .navigationTitle("日期网格")
    }
}

private struct LunarDayGridEraPreviewContent: View {
    @Environment(CalendarSelection.self) private var selection
    @Query private var days: [ChineseLunarDay]

    var body: some View {
        if let month = days.first(where: { $0.dayIndex == selection.selectedDayIndex })?.chineseLunarMonth {
            LunarDayGrid(month: month)
        }
    }
}

#Preview("同月日期跨越公历纪元", traits: .sampleData(.civilEraBoundary)) {
    NavigationStack {
        ScrollView {
            LunarDayGridEraPreviewContent()
                .padding()
        }
        .navigationTitle("公元前 → 公元")
    }
}
