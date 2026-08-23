import ChineseCalendarCore
import ChineseCalendarLogging
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 从目的地提供的初始日期开始，在页面内部浏览农历年、月与日。
struct LunarYearDetailView: View {
    let initialYearNumber: Int
    let initialMonthIndex: Int?
    let initialDayIndex: Int?

    @State private var browseState: LunarCalendarBrowseState

    @Environment(CalendarRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.calendarStoreContentLevel) private var storeContentLevel
    @Query(sort: \ChineseLunarYear.lunarYearNumber) private var years: [ChineseLunarYear]
    @Query(sort: \ChineseLunarMonth.lunarMonthIndex) private var calendarMonths: [ChineseLunarMonth]
    @Query private var todayCivilDates: [CivilDate]

    init(
        initialYearNumber: Int,
        initialMonthIndex: Int? = nil,
        initialDayIndex: Int? = nil,
        today: Date = .now
    ) {
        self.initialYearNumber = initialYearNumber
        self.initialMonthIndex = initialMonthIndex
        self.initialDayIndex = initialDayIndex
        _browseState = State(
            initialValue: LunarCalendarBrowseState(
                displayedYearNumber: initialYearNumber,
                selectedMonthIndex: initialMonthIndex,
                selectedDayIndex: initialDayIndex
            )
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

    var body: some View {
        let selectedMonth = selectedMonth
        let adjacentMonths = adjacentCalendarMonths(to: selectedMonth)

        Group {
            if let year = displayedYear {
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
                                daySelection: browseState.daySelection,
                                todayDayIndex: todayCivilDates.first?.dayIndex,
                                showYearPicker: presentYearPicker,
                                canSelectPreviousMonth: canSelect(adjacentMonths.previous),
                                canSelectNextMonth: canSelect(adjacentMonths.next),
                                selectPreviousMonth: { selectMonthInCalendar(adjacentMonths.previous) },
                                selectNextMonth: { selectMonthInCalendar(adjacentMonths.next) },
                                selectMonth: selectMonthInCalendar,
                                yearTransitionDirection: browseState.yearTransitionDirection,
                                reduceMotion: accessibilityReduceMotion
                            )
                        }
                    }
                    .padding()
                    .frame(maxWidth: 980, alignment: .leading)
                }
            } else {
                ContentUnavailableView {
                    Label("Chinese Calendar", systemSymbol: .calendarBadgeExclamationmark)
                } description: {
                    Text("没有找到这个农历年。")
                }
            }
        }
        .background(.calendarSystemBackground)
        .onAppear(perform: selectDefaultMonthIfNeeded)
        .onChange(of: browseState.displayedYearNumber) {
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
                ToolbarItem(placement: .primaryAction) {
                    Button("今天", action: selectToday)
                }
            #else
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("今天", action: selectToday)
                        .help("回到今天")

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
}

private extension LunarYearDetailView {
    var displayedYear: ChineseLunarYear? {
        years.first { $0.lunarYearNumber == browseState.displayedYearNumber }
    }

    var displayedYearIndex: [ChineseLunarYear].Index? {
        years.firstIndex { $0.lunarYearNumber == browseState.displayedYearNumber }
    }

    var canSelectPreviousYear: Bool {
        guard let displayedYearIndex else {
            return false
        }

        return displayedYearIndex > years.startIndex
    }

    var canSelectNextYear: Bool {
        guard let displayedYearIndex else {
            return false
        }

        return displayedYearIndex < years.index(before: years.endIndex)
    }

    var selectedMonth: ChineseLunarMonth? {
        guard let selectedMonthIndex = browseState.selectedMonthIndex else {
            return monthsInYearStartOrder.first
        }

        return monthsInYearStartOrder.first { $0.lunarMonthIndex == selectedMonthIndex }
            ?? monthsInYearStartOrder.first
    }

    var monthsInYearStartOrder: [ChineseLunarMonth] {
        // lunarMonthIndex 是连续时间轴，过滤后仍保留历史年首顺序。
        calendarMonths.filter { $0.lunarYearNumber == browseState.displayedYearNumber }
    }

    var todayMonthIndex: Int? {
        guard let todaySelection,
              monthsInYearStartOrder.contains(where: { $0.lunarMonthIndex == todaySelection.lunarMonthIndex })
        else {
            return nil
        }

        return todaySelection.lunarMonthIndex
    }

    var todaySelection: CalendarTodaySelection? {
        todayCivilDates
            .lazy
            .compactMap { civilDate -> CalendarTodaySelection? in
                guard let lunarDay = civilDate.calendarDay?.chineseLunarDay else {
                    return nil
                }

                let lunarYearNumber = lunarDay.chineseLunarMonth?.lunarYearNumber
                    ?? calendarMonths.first { $0.lunarMonthIndex == lunarDay.lunarMonthIndex }?.lunarYearNumber

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

    func selectDefaultMonthIfNeeded() {
        guard monthsInYearStartOrder.contains(where: { $0.lunarMonthIndex == browseState.selectedMonthIndex }) == false
        else {
            return
        }

        if let todayMonthIndex {
            browseState.selectedMonthIndex = todayMonthIndex
            return
        }

        if storeContentLevel == .base {
            browseState.selectedMonthIndex = nil
            return
        }

        browseState.selectedMonthIndex = monthsInYearStartOrder.first?.lunarMonthIndex
    }

    func adjacentCalendarMonths(
        to selectedMonth: ChineseLunarMonth?
    ) -> (previous: ChineseLunarMonth?, next: ChineseLunarMonth?) {
        guard let selectedMonth else {
            return (nil, nil)
        }

        guard let selectedMonthInCalendarIndex = calendarMonths.binarySearchIndex(
            of: selectedMonth.lunarMonthIndex,
            by: \.lunarMonthIndex
        )
        else {
            return (nil, nil)
        }

        let previousMonth: ChineseLunarMonth? = if selectedMonthInCalendarIndex > calendarMonths.startIndex {
            calendarMonths[calendarMonths.index(before: selectedMonthInCalendarIndex)]
        } else {
            nil
        }

        let lastCalendarMonthIndex = calendarMonths.index(before: calendarMonths.endIndex)
        let nextMonth: ChineseLunarMonth? = if selectedMonthInCalendarIndex < lastCalendarMonthIndex {
            calendarMonths[calendarMonths.index(after: selectedMonthInCalendarIndex)]
        } else {
            nil
        }

        return (previousMonth, nextMonth)
    }

    func canSelect(_ month: ChineseLunarMonth?) -> Bool {
        guard let month else {
            return false
        }

        return years.contains { $0.lunarYearNumber == month.lunarYearNumber }
    }

    func selectMonthInCalendar(_ month: ChineseLunarMonth) {
        let crossesYear = month.lunarYearNumber != browseState.displayedYearNumber
        guard crossesYear || browseState.selectedMonthIndex != month.lunarMonthIndex else {
            return
        }

        ChineseCalendarPerformanceSignposts.shared.beginMonthSwitch(
            from: selectedMonth?.lunarMonthIndex,
            to: month.lunarMonthIndex,
            crossesYear: crossesYear
        )

        browseState.select(
            yearNumber: month.lunarYearNumber,
            monthIndex: month.lunarMonthIndex
        )
    }

    func selectMonthInCalendar(_ month: ChineseLunarMonth?) {
        guard let month else {
            return
        }

        selectMonthInCalendar(month)
    }

    func selectPreviousYear() {
        guard let displayedYearIndex, displayedYearIndex > years.startIndex else {
            return
        }

        selectYear(years[years.index(before: displayedYearIndex)].lunarYearNumber)
    }

    func selectNextYear() {
        guard let displayedYearIndex, displayedYearIndex < years.index(before: years.endIndex) else {
            return
        }

        selectYear(years[years.index(after: displayedYearIndex)].lunarYearNumber)
    }

    func selectToday() {
        guard let todaySelection else {
            selectYear(ChineseLunarCalendar.yearNumber())
            return
        }

        browseState.select(
            yearNumber: todaySelection.lunarYearNumber,
            monthIndex: todaySelection.lunarMonthIndex,
            dayIndex: todaySelection.dayIndex
        )
    }

    func presentYearPicker() {
        let yearPicker = CalendarYearPickerDestination(
            initialYearNumber: browseState.displayedYearNumber,
            onSelect: selectYear
        )
        router.presentSheet(.yearPicker(yearPicker))
    }

    func selectYear(_ yearNumber: Int) {
        guard years.contains(where: { $0.lunarYearNumber == yearNumber }),
              browseState.displayedYearNumber != yearNumber
        else {
            return
        }

        browseState.selectYear(yearNumber)
    }
}

private extension LunarYearDetailView {
    static func gregorianDateComponents(for date: Date) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
}
