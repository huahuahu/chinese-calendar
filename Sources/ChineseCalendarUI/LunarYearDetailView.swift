import ChineseCalendarCore
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

struct LunarYearDetailView: View {
    let year: ChineseLunarYear
    let calendarMonths: [ChineseLunarMonth]
    @Binding var selectedMonthIndex: Int?
    let canSelectPreviousYear: Bool
    let canSelectNextYear: Bool
    let selectPreviousYear: () -> Void
    let selectNextYear: () -> Void
    let showYearPicker: (() -> Void)?
    let selectMonth: ((ChineseLunarMonth) -> Void)?
    let selectToday: (() -> Void)?
    let bottomStatusBarIsPresented: Bool

    @Environment(\.calendarStoreContentLevel) private var storeContentLevel
    @Query private var months: [ChineseLunarMonth]
    @Query private var todayCivilDates: [CivilDate]

    init(
        year: ChineseLunarYear,
        calendarMonths: [ChineseLunarMonth] = [],
        selectedMonthIndex: Binding<Int?>,
        canSelectPreviousYear: Bool,
        canSelectNextYear: Bool,
        selectPreviousYear: @escaping () -> Void,
        selectNextYear: @escaping () -> Void,
        showYearPicker: (() -> Void)? = nil,
        selectMonth: ((ChineseLunarMonth) -> Void)? = nil,
        selectToday: (() -> Void)? = nil,
        bottomStatusBarIsPresented: Bool = false,
        today: Date = .now
    ) {
        self.year = year
        self.calendarMonths = calendarMonths
        _selectedMonthIndex = selectedMonthIndex
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
                        showYearPicker: showYearPicker,
                        canSelectPreviousMonth: canSelectPreviousMonth,
                        canSelectNextMonth: canSelectNextMonth,
                        selectPreviousMonth: selectPreviousMonth,
                        selectNextMonth: selectNextMonth,
                        selectMonth: selectMonthInCalendar
                    )
                    .id(selectedMonth.lunarMonthIndex)
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
            if let selectToday {
                ToolbarItem(placement: .primaryAction) {
                    Button("今天", action: selectToday)
                }
            }
#else
            ToolbarItemGroup(placement: .primaryAction) {
                if let selectToday {
                    Button("今天", action: selectToday)
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
        let monthIndexes = Set(monthsInYearStartOrder.map(\.lunarMonthIndex))
        return todayCivilDates
            .lazy
            .compactMap { $0.calendarDay?.chineseLunarDay?.lunarMonthIndex }
            .first { monthIndexes.contains($0) }
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

    private var selectedMonthInCalendarIndex: [ChineseLunarMonth].Index? {
        guard let selectedMonth else {
            return nil
        }

        return calendarMonthsInOrder.firstIndex { $0.lunarMonthIndex == selectedMonth.lunarMonthIndex }
    }

    private var previousCalendarMonth: ChineseLunarMonth? {
        guard let selectedMonthInCalendarIndex,
              selectedMonthInCalendarIndex > calendarMonthsInOrder.startIndex
        else {
            return nil
        }

        return calendarMonthsInOrder[calendarMonthsInOrder.index(before: selectedMonthInCalendarIndex)]
    }

    private var nextCalendarMonth: ChineseLunarMonth? {
        guard let selectedMonthInCalendarIndex,
              selectedMonthInCalendarIndex < calendarMonthsInOrder.index(before: calendarMonthsInOrder.endIndex)
        else {
            return nil
        }

        return calendarMonthsInOrder[calendarMonthsInOrder.index(after: selectedMonthInCalendarIndex)]
    }

    private var canSelectPreviousMonth: Bool {
        canSelect(previousCalendarMonth)
    }

    private var canSelectNextMonth: Bool {
        canSelect(nextCalendarMonth)
    }

    private func canSelect(_ month: ChineseLunarMonth?) -> Bool {
        guard let month else {
            return false
        }

        return month.lunarYearNumber == year.lunarYearNumber || selectMonth != nil
    }

    private func selectPreviousMonth() {
        guard let previousCalendarMonth else {
            return
        }

        selectMonthInCalendar(previousCalendarMonth)
    }

    private func selectNextMonth() {
        guard let nextCalendarMonth else {
            return
        }

        selectMonthInCalendar(nextCalendarMonth)
    }

    private func selectMonthInCalendar(_ month: ChineseLunarMonth) {
        if month.lunarYearNumber == year.lunarYearNumber {
            selectedMonthIndex = month.lunarMonthIndex
        } else {
            selectMonth?(month)
        }
    }

    private var bottomStatusBarContentPadding: CGFloat {
        #if os(iOS)
            bottomStatusBarIsPresented ? 120 : 0
        #else
            0
        #endif
    }

    private static func gregorianDateComponents(for date: Date) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
}
