import ChineseCalendarLogging
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 显示指定农历月的日期网格与选中日详情。
struct LunarMonthGrid: View {
    @Environment(\.calendarStoreContentLevel) private var storeContentLevel

    let month: ChineseLunarMonth
    let todayJulianDayNumber: Int

    @Bindable var daySelection: CalendarDaySelection
    @Query private var days: [ChineseLunarDay]

    init(
        month: ChineseLunarMonth,
        daySelection: CalendarDaySelection,
        todayJulianDayNumber: Int
    ) {
        self.month = month
        self.daySelection = daySelection
        self.todayJulianDayNumber = todayJulianDayNumber

        let lunarMonthIndex = month.lunarMonthIndex
        _days = Query(
            filter: #Predicate<ChineseLunarDay> { day in
                day.lunarMonthIndex == lunarMonthIndex
            },
            sort: \ChineseLunarDay.dayNumberInMonth
        )
    }

    var body: some View {
        let selectedDayIndex = daySelection.dayIndex
        let todayDay = days.first { $0.calendarDay?.julianDayNumber == todayJulianDayNumber }
        let defaultSelectedDay = todayDay ?? days.first
        let selectedDay = selectedDay(
            at: selectedDayIndex,
            defaultingTo: defaultSelectedDay
        )
        let effectiveSelectedDayIndex = selectedDay?.dayIndex

        VStack(alignment: .leading, spacing: 16) {
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
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 28))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("农历月格")
                            .font(.title2)
                            .bold()

                        Spacer()

                        Text("连续日序")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 8) {
                        ForEach(days, id: \.dayIndex) { day in
                            Button {
                                daySelection.dayIndex = day.dayIndex
                            } label: {
                                LunarDayGridCell(
                                    day: day,
                                    isSelected: day.dayIndex == effectiveSelectedDayIndex,
                                    isToday: day.calendarDay?.julianDayNumber == todayJulianDayNumber
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 28))

                if let selectedDay {
                    SelectedLunarDayDetailCard(
                        day: selectedDay,
                        month: month,
                        contentLevel: storeContentLevel
                    )
                }
            }
        }
        .onAppear(perform: finishPendingMonthSwitch)
        .onChange(of: days.map(\.dayIndex)) {
            finishPendingMonthSwitch()
        }
        .onChange(of: todayJulianDayNumber) {
            selectDefaultDayIfNeeded()
        }
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 58), spacing: 8)]
    }

    private func selectedDay(
        at selectedDayIndex: Int?,
        defaultingTo defaultSelectedDay: ChineseLunarDay?
    ) -> ChineseLunarDay? {
        if let selectedDayIndex {
            return days.first { $0.dayIndex == selectedDayIndex } ?? defaultSelectedDay
        }

        return defaultSelectedDay
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
            "当前内置数据只包含年份和月份；下载完整数据后会显示每日干支和对应民用日期。"
        case .full:
            "这个月份暂时没有可显示的日级记录。"
        }
    }

    private func selectDefaultDayIfNeeded() {
        guard !days.isEmpty else {
            daySelection.dayIndex = nil
            return
        }

        if let selectedDayIndex = daySelection.dayIndex {
            guard !days.contains(where: { $0.dayIndex == selectedDayIndex }) else {
                return
            }
        }

        daySelection.dayIndex = Self.defaultDayIndex(
            in: days.map { day in
                (
                    dayIndex: day.dayIndex,
                    julianDayNumber: day.calendarDay?.julianDayNumber
                )
            },
            todayJulianDayNumber: todayJulianDayNumber
        )
    }

    private func finishPendingMonthSwitch() {
        let performanceSignposts = ChineseCalendarPerformanceSignposts.shared
        performanceSignposts.monthDaysAvailable(
            monthIndex: month.lunarMonthIndex,
            dayCount: days.count
        )
        selectDefaultDayIfNeeded()
        performanceSignposts.endMonthSwitch(
            monthIndex: month.lunarMonthIndex,
            dayCount: days.count,
            selectedDayIndex: daySelection.dayIndex
        )
    }
}

extension LunarMonthGrid {
    static func defaultDayIndex(
        in days: [(dayIndex: Int, julianDayNumber: Int?)],
        todayJulianDayNumber: Int?
    ) -> Int? {
        guard let todayJulianDayNumber else {
            return days.first?.dayIndex
        }

        return days.first(where: { $0.julianDayNumber == todayJulianDayNumber })?.dayIndex
            ?? days.first?.dayIndex
    }
}
