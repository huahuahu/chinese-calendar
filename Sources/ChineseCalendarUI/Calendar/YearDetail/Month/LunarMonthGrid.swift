import ChineseCalendarCore
import ChineseCalendarLogging
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 显示在 LunarYearDetailView 中，用于浏览当前月份的日期网格与选中日详情。
struct LunarMonthGrid: View {
    let year: ChineseLunarYear
    let months: [ChineseLunarMonth]
    let month: ChineseLunarMonth
    let showYearPicker: (() -> Void)?
    let canSelectPreviousMonth: Bool
    let canSelectNextMonth: Bool
    let selectPreviousMonth: () -> Void
    let selectNextMonth: () -> Void
    let selectMonth: (ChineseLunarMonth) -> Void
    let todayDayIndex: Int?

    @Environment(\.calendarStoreContentLevel) private var storeContentLevel
    @Bindable var daySelection: CalendarDaySelection
    @Query private var days: [ChineseLunarDay]

    init(
        year: ChineseLunarYear,
        months: [ChineseLunarMonth],
        month: ChineseLunarMonth,
        daySelection: CalendarDaySelection,
        todayDayIndex: Int?,
        showYearPicker: (() -> Void)? = nil,
        canSelectPreviousMonth: Bool,
        canSelectNextMonth: Bool,
        selectPreviousMonth: @escaping () -> Void,
        selectNextMonth: @escaping () -> Void,
        selectMonth: @escaping (ChineseLunarMonth) -> Void
    ) {
        self.year = year
        self.months = months
        self.month = month
        self.daySelection = daySelection
        self.todayDayIndex = todayDayIndex
        self.showYearPicker = showYearPicker
        self.canSelectPreviousMonth = canSelectPreviousMonth
        self.canSelectNextMonth = canSelectNextMonth
        self.selectPreviousMonth = selectPreviousMonth
        self.selectNextMonth = selectNextMonth
        self.selectMonth = selectMonth

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
        let todayDay = todayDayIndex.flatMap { todayDayIndex in
            days.first { $0.dayIndex == todayDayIndex }
        }
        let defaultSelectedDay = todayDay ?? days.first
        let selectedDay = selectedDay(
            at: selectedDayIndex,
            defaultingTo: defaultSelectedDay
        )
        let effectiveSelectedDayIndex = selectedDay?.dayIndex
        let todayDayIndex = todayDay?.dayIndex

        VStack(alignment: .leading, spacing: 16) {
            MonthSwitcher(
                title: monthNavigationTitle,
                subtitle: monthNavigationSubtitle,
                months: months,
                selectedMonth: month,
                showYearPicker: showYearPicker,
                canSelectPreviousMonth: canSelectPreviousMonth,
                canSelectNextMonth: canSelectNextMonth,
                selectPreviousMonth: selectPreviousMonth,
                selectNextMonth: selectNextMonth,
                selectMonth: selectMonth
            )
            .padding()
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 28))

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
                                    isToday: day.dayIndex == todayDayIndex
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

    private var monthNavigationTitle: String {
        let yearTitle = LunarCalendarFormatting.yearSubtitle(
            stemIndex: year.yearStemIndex,
            branchIndex: year.yearBranchIndex
        )
        return "\(yearTitle) \(LunarMonthDisplay.title(for: month))"
    }

    private var monthNavigationSubtitle: String {
        let fallback = LunarCalendarFormatting.monthSubtitle(
            dayCount: month.dayCount,
            stemIndex: month.monthStemIndex,
            branchIndex: month.monthBranchIndex
        )
        return Self.monthNavigationSubtitle(
            civilDateRangeTitle: civilDateRangeTitle,
            fallback: fallback
        )
    }

    private var civilDateRangeTitle: String? {
        guard let firstCivilDate = days.first?.calendarDay?.civilDate,
              let lastCivilDate = days.last?.calendarDay?.civilDate
        else {
            return nil
        }

        return "\(fullCivilDateTitle(for: firstCivilDate)) - \(fullCivilDateTitle(for: lastCivilDate))"
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
            "当前内置数据只包含年份和月份；下载完整数据后会显示每日干支和对应公历日期。"
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
            in: days.map(\.dayIndex),
            todayDayIndex: todayDayIndex
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

    private func fullCivilDateTitle(for civilDate: CivilDate) -> String {
        let prefix = civilDate.calendarStyle == .julian ? "儒略" : "公历"
        return "\(prefix) \(civilDate.year)年\(civilDate.month)月\(civilDate.dayOfMonth)日"
    }

    static func monthNavigationSubtitle(
        civilDateRangeTitle: String?,
        fallback: String
    ) -> String {
        civilDateRangeTitle ?? fallback
    }

    static func defaultDayIndex(in dayIndices: [Int], todayDayIndex: Int?) -> Int? {
        if let todayDayIndex, dayIndices.contains(todayDayIndex) {
            return todayDayIndex
        }

        return dayIndices.first
    }
}
