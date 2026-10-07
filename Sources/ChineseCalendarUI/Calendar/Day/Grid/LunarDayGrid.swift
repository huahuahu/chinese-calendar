import ChineseCalendarLocalization
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

    private var sortedDays: [ChineseLunarDay] {
        ChineseCalendarRelationshipQueries.days(inMonth: month)
    }

    var body: some View {
        let days = sortedDays
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
                        Text(CalendarStringKey.Calendar.MonthGrid.title)
                            .font(.title2)
                            .bold()

                        Spacer()

                        Text(CalendarStringKey.Calendar.MonthGrid.subtitle)
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

    private var emptyStateTitle: LocalizedStringResource {
        switch storeContentLevel {
        case .base:
            CalendarStringKey.Calendar.MonthGrid.Empty.requiresFullDataTitle
        case .full:
            CalendarStringKey.Calendar.MonthGrid.Empty.title
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

    private var emptyStateDescription: LocalizedStringResource {
        switch storeContentLevel {
        case .base:
            CalendarStringKey.Calendar.MonthGrid.Empty.requiresFullDataMessage
        case .full:
            CalendarStringKey.Calendar.MonthGrid.Empty.message
        }
    }

    private func finishPendingMonthSwitch() {
        let performanceSignposts = ChineseCalendarPerformanceSignposts.shared
        let dayCount = month.days.count
        performanceSignposts.monthDaysAvailable(
            monthIndex: month.lunarMonthIndex,
            dayCount: dayCount
        )
        performanceSignposts.endMonthSwitch(
            monthIndex: month.lunarMonthIndex,
            dayCount: dayCount,
            selectedDayIndex: selection.selectedDayIndex
        )
    }
}

#Preview("30 天与选中日", traits: .sampleData) {
    NavigationStack {
        ScrollView {
            LunarDayGridMonthPreviewContent(monthIndex: 3)
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
            LunarDayGridMonthPreviewContent(monthIndex: 4)
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

private struct LunarDayGridMonthPreviewContent: View {
    @Query private var months: [ChineseLunarMonth]

    init(monthIndex: Int) {
        _months = Query(filter: #Predicate<ChineseLunarMonth> { $0.lunarMonthIndex == monthIndex })
    }

    var body: some View {
        if let month = months.first {
            LunarDayGrid(month: month)
        }
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
