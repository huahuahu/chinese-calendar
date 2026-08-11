import ChineseCalendarCore
import ChineseCalendarLogging
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 显示在日历路由目的地中，组织当前农历年的月份与日期详情。
struct LunarYearDetailView: View {
    let year: ChineseLunarYear
    let calendarMonths: [ChineseLunarMonth]
    @Binding var selectedMonthIndex: Int?
    @Binding var selectedDayIndex: Int?
    let canSelectPreviousYear: Bool
    let canSelectNextYear: Bool
    let selectPreviousYear: () -> Void
    let selectNextYear: () -> Void
    let showYearPicker: (() -> Void)?
    let selectMonth: ((ChineseLunarMonth) -> Void)?
    let selectToday: ((CalendarTodaySelection?) -> Void)?
    let bottomStatusBarIsPresented: Bool

    @Environment(\.calendarStoreContentLevel) private var storeContentLevel
    @Query private var months: [ChineseLunarMonth]
    @Query private var todayCivilDates: [CivilDate]

    init(
        year: ChineseLunarYear,
        calendarMonths: [ChineseLunarMonth] = [],
        selectedMonthIndex: Binding<Int?>,
        selectedDayIndex: Binding<Int?>,
        canSelectPreviousYear: Bool,
        canSelectNextYear: Bool,
        selectPreviousYear: @escaping () -> Void,
        selectNextYear: @escaping () -> Void,
        showYearPicker: (() -> Void)? = nil,
        selectMonth: ((ChineseLunarMonth) -> Void)? = nil,
        selectToday: ((CalendarTodaySelection?) -> Void)? = nil,
        bottomStatusBarIsPresented: Bool = false,
        today: Date = .now
    ) {
        self.year = year
        self.calendarMonths = calendarMonths
        _selectedMonthIndex = selectedMonthIndex
        _selectedDayIndex = selectedDayIndex
        self.canSelectPreviousYear = canSelectPreviousYear
        self.canSelectNextYear = canSelectNextYear
        self.selectPreviousYear = selectPreviousYear
        self.selectNextYear = selectNextYear
        self.showYearPicker = showYearPicker
        self.selectMonth = selectMonth
        self.selectToday = selectToday
        self.bottomStatusBarIsPresented = bottomStatusBarIsPresented

        let lunarYearNumber = year.lunarYearNumber
        _months = Query(
            filter: #Predicate<ChineseLunarMonth> { month in
                month.lunarYearNumber == lunarYearNumber
            },
            sort: \ChineseLunarMonth.lunarMonthIndex
        )

        let todayComponents = Self.gregorianDateComponents(for: today)
        let todayYear = todayComponents.year ?? 0
        let todayMonth = todayComponents.month ?? 0
        let todayDay = todayComponents.day ?? 0
        let gregorianCalendarStyle = CivilCalendarStyle.gregorian.rawValue
        _todayCivilDates = Query(
            filter: #Predicate<CivilDate> { civilDate in
                civilDate.year == todayYear
                    && civilDate.month == todayMonth
                    && civilDate.dayOfMonth == todayDay
                    && civilDate.calendarStyleRawValue == gregorianCalendarStyle
            },
            sort: \CivilDate.dayIndex
        )
    }

    private var selectedMonth: ChineseLunarMonth? {
        guard let selectedMonthIndex else {
            return monthsInYearStartOrder.first
        }

        return monthsInYearStartOrder.first { $0.lunarMonthIndex == selectedMonthIndex } ?? monthsInYearStartOrder.first
    }

    private var monthsInYearStartOrder: [ChineseLunarMonth] {
        // lunarMonthIndex is chronological, so it preserves historical year starts such as tenth-month starts.
        months
    }

    var body: some View {
        let selectedMonth = selectedMonth
        let adjacentMonths = adjacentCalendarMonths(to: selectedMonth)

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if monthsInYearStartOrder.isEmpty {
                    ContentUnavailableView {
                        Label("没有月份数据", systemSymbol: .calendarBadgeExclamationmark)
                    }
                } else if let selectedMonth {
                    LunarMonthGrid(
                        year: year,
                        months: monthsInYearStartOrder,
                        month: selectedMonth,
                        selectedDayIndex: $selectedDayIndex,
                        showYearPicker: showYearPicker,
                        canSelectPreviousMonth: canSelect(adjacentMonths.previous),
                        canSelectNextMonth: canSelect(adjacentMonths.next),
                        selectPreviousMonth: { selectMonthInCalendar(adjacentMonths.previous) },
                        selectNextMonth: { selectMonthInCalendar(adjacentMonths.next) },
                        selectMonth: selectMonthInCalendar
                    )
                }
            }
            .padding()
            .padding(.bottom, bottomStatusBarContentPadding)
            .frame(maxWidth: 980, alignment: .leading)
        }
        .background(.calendarSystemBackground)
        .onAppear(perform: selectDefaultMonthIfNeeded)
        .onChange(of: year.lunarYearNumber) {
            selectDefaultMonthIfNeeded()
        }
        .onChange(of: todayCivilDates.map(\.dayIndex)) {
            selectDefaultMonthIfNeeded()
        }
        .onChange(of: storeContentLevel) {
            selectDefaultMonthIfNeeded()
        }
        .navigationTitle("日历")
        .toolbar {
            #if os(iOS)
                if selectToday != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("今天", action: selectTodayFromToolbar)
                    }
                }
            #else
                ToolbarItemGroup(placement: .primaryAction) {
                    if selectToday != nil {
                        Button("今天", action: selectTodayFromToolbar)
                            .help("回到今天")
                    }

                    Button("上一年", systemSymbol: .chevronLeft, action: selectPreviousYear)
                        .disabled(!canSelectPreviousYear)
                        .help("切换到上一年")

                    Button("下一年", systemSymbol: .chevronRight, action: selectNextYear)
                        .disabled(!canSelectNextYear)
                        .help("切换到下一年")
                }
            #endif
        }
    }

    private var todayMonthIndex: Int? {
        guard let todaySelection,
              monthsInYearStartOrder.contains(where: { $0.lunarMonthIndex == todaySelection.lunarMonthIndex })
        else {
            return nil
        }

        return todaySelection.lunarMonthIndex
    }

    private var todaySelection: CalendarTodaySelection? {
        todayCivilDates
            .lazy
            .compactMap { civilDate -> CalendarTodaySelection? in
                guard let lunarDay = civilDate.calendarDay?.chineseLunarDay else {
                    return nil
                }

                let lunarYearNumber = lunarDay.chineseLunarMonth?.lunarYearNumber
                    ?? calendarMonthsInOrder.first { $0.lunarMonthIndex == lunarDay.lunarMonthIndex }?.lunarYearNumber

                guard let lunarYearNumber else {
                    return nil
                }

                return CalendarTodaySelection(
                    lunarYearNumber: lunarYearNumber,
                    lunarMonthIndex: lunarDay.lunarMonthIndex,
                    dayIndex: lunarDay.dayIndex
                )
            }
            .first
    }

    private func selectDefaultMonthIfNeeded() {
        guard monthsInYearStartOrder.contains(where: { $0.lunarMonthIndex == selectedMonthIndex }) == false else {
            return
        }

        if let todayMonthIndex {
            selectedMonthIndex = todayMonthIndex
            return
        }

        if storeContentLevel == .base {
            selectedMonthIndex = nil
            return
        }

        selectedMonthIndex = monthsInYearStartOrder.first?.lunarMonthIndex
    }

    private var calendarMonthsInOrder: [ChineseLunarMonth] {
        calendarMonths
    }

    private func adjacentCalendarMonths(
        to selectedMonth: ChineseLunarMonth?
    ) -> (previous: ChineseLunarMonth?, next: ChineseLunarMonth?) {
        guard let selectedMonth else {
            return (nil, nil)
        }

        guard let selectedMonthInCalendarIndex = calendarMonthsInOrder.binarySearchIndex(
            of: selectedMonth.lunarMonthIndex,
            by: \.lunarMonthIndex
        )
        else {
            return (nil, nil)
        }

        let previousMonth: ChineseLunarMonth? = if selectedMonthInCalendarIndex > calendarMonthsInOrder.startIndex {
            calendarMonthsInOrder[calendarMonthsInOrder.index(before: selectedMonthInCalendarIndex)]
        } else {
            nil
        }

        let lastCalendarMonthIndex = calendarMonthsInOrder.index(before: calendarMonthsInOrder.endIndex)
        let nextMonth: ChineseLunarMonth? = if selectedMonthInCalendarIndex < lastCalendarMonthIndex {
            calendarMonthsInOrder[calendarMonthsInOrder.index(after: selectedMonthInCalendarIndex)]
        } else {
            nil
        }

        return (previousMonth, nextMonth)
    }

    private func canSelect(_ month: ChineseLunarMonth?) -> Bool {
        guard let month else {
            return false
        }

        return month.lunarYearNumber == year.lunarYearNumber || selectMonth != nil
    }

    private func selectMonthInCalendar(_ month: ChineseLunarMonth) {
        if month.lunarYearNumber == year.lunarYearNumber {
            guard selectedMonthIndex != month.lunarMonthIndex else {
                return
            }

            ChineseCalendarPerformanceSignposts.shared.beginMonthSwitch(
                from: selectedMonth?.lunarMonthIndex,
                to: month.lunarMonthIndex,
                crossesYear: false
            )
            selectedMonthIndex = month.lunarMonthIndex
            if selectedDayIndex != nil {
                selectedDayIndex = nil
            }
        } else {
            ChineseCalendarPerformanceSignposts.shared.beginMonthSwitch(
                from: selectedMonth?.lunarMonthIndex,
                to: month.lunarMonthIndex,
                crossesYear: true
            )
            selectMonth?(month)
        }
    }

    private func selectMonthInCalendar(_ month: ChineseLunarMonth?) {
        guard let month else {
            return
        }

        selectMonthInCalendar(month)
    }

    private func selectTodayFromToolbar() {
        selectToday?(todaySelection)
    }

    private var bottomStatusBarContentPadding: CGFloat {
        #if os(iOS)
            bottomStatusBarIsPresented ? 120 : 0
        #else
            0
        #endif
    }
}

private extension LunarYearDetailView {
    static func gregorianDateComponents(for date: Date) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
}
