import ChineseCalendarCore
import ChineseCalendarLogging
import ChineseCalendarPersistence
import Combine
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 从目的地提供的初始日期开始，在页面内部浏览农历年、月与日。
struct LunarYearDetailView: View {
    let initialYearNumber: Int
    let initialMonthIndex: Int?
    let initialDayIndex: Int?

    @State private var browseState: LunarCalendarBrowseState
    @State private var pendingYearTransition: LunarYearTransitionRequest?
    @State private var todayJulianDayNumber = JulianDayNumber.forLocalGregorianDate(containing: .now)
    @State private var todaySelection: CalendarTodaySelection?

    @Environment(CalendarRouter.self) private var router
    @Environment(\.calendarStoreContentLevel) private var storeContentLevel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \ChineseLunarYear.lunarYearNumber) private var years: [ChineseLunarYear]

    init(
        initialYearNumber: Int,
        initialMonthIndex: Int? = nil,
        initialDayIndex: Int? = nil
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
                                todayJulianDayNumber: todayJulianDayNumber,
                                showYearPicker: presentYearPicker,
                                canSelectPreviousMonth: canSelect(adjacentMonths.previous),
                                canSelectNextMonth: canSelect(adjacentMonths.next),
                                selectPreviousMonth: { selectMonthInCalendar(adjacentMonths.previous) },
                                selectNextMonth: { selectMonthInCalendar(adjacentMonths.next) },
                                selectMonth: selectMonthInCalendar,
                                yearTransitionContext: browseState.yearTransitionContext,
                                yearTransitionPreparationMonthIndex: pendingYearTransition?.sourceMonthIndex,
                                completeYearTransitionPreparation: completeYearTransitionPreparation
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
        .onAppear(perform: refreshToday)
        .onChange(of: browseState.displayedYearNumber) {
            selectDefaultMonthIfNeeded()
        }
        .onChange(of: storeContentLevel) {
            refreshToday()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                refreshToday()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
                .receive(on: RunLoop.main)
        ) { _ in
            refreshToday()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)
                .receive(on: RunLoop.main)
        ) { _ in
            refreshToday()
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
        guard let displayedYear else {
            return []
        }

        return chronologicalMonths(in: displayedYear)
    }

    var todayMonthIndex: Int? {
        guard let todaySelection,
              monthsInYearStartOrder.contains(where: { $0.lunarMonthIndex == todaySelection.lunarMonthIndex })
        else {
            return nil
        }

        return todaySelection.lunarMonthIndex
    }

    func refreshToday() {
        let julianDayNumber = JulianDayNumber.forLocalGregorianDate(containing: .now)
        todayJulianDayNumber = julianDayNumber
        todaySelection = loadTodaySelection(julianDayNumber: julianDayNumber)
        selectDefaultMonthIfNeeded()
    }

    func loadTodaySelection(julianDayNumber: Int) -> CalendarTodaySelection? {
        var descriptor = FetchDescriptor<CalendarDay>(
            predicate: #Predicate<CalendarDay> { calendarDay in
                calendarDay.julianDayNumber == julianDayNumber
            }
        )
        descriptor.fetchLimit = 1
        descriptor.relationshipKeyPathsForPrefetching = [\.chineseLunarDay]

        let calendarDay: CalendarDay
        do {
            guard let fetchedCalendarDay = try modelContext.fetch(descriptor).first else {
                return nil
            }
            calendarDay = fetchedCalendarDay
        } catch {
            ChineseCalendarLog.ui.error("无法按 JDN 查询今天：\(error.localizedDescription)")
            return nil
        }

        guard let lunarDay = calendarDay.chineseLunarDay else {
            return nil
        }

        let lunarYearNumber = lunarDay.chineseLunarMonth?.lunarYearNumber
            ?? loadLunarYearNumber(lunarMonthIndex: lunarDay.lunarMonthIndex)

        guard let lunarYearNumber else {
            return nil
        }

        return CalendarTodaySelection(
            lunarYearNumber: lunarYearNumber,
            lunarMonthIndex: lunarDay.lunarMonthIndex,
            dayIndex: lunarDay.dayIndex
        )
    }

    func loadLunarYearNumber(lunarMonthIndex: Int) -> Int? {
        var descriptor = FetchDescriptor<ChineseLunarMonth>(
            predicate: #Predicate<ChineseLunarMonth> { month in
                month.lunarMonthIndex == lunarMonthIndex
            }
        )
        descriptor.fetchLimit = 1

        do {
            return try modelContext.fetch(descriptor).first?.lunarYearNumber
        } catch {
            ChineseCalendarLog.ui.error("无法按月份索引查询今天所属农历年：\(error.localizedDescription)")
            return nil
        }
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

        let months = monthsInYearStartOrder
        guard let selectedMonthIndex = months.firstIndex(where: {
            $0.lunarMonthIndex == selectedMonth.lunarMonthIndex
        })
        else {
            return (nil, nil)
        }

        let previousMonth: ChineseLunarMonth? = if selectedMonthIndex > months.startIndex {
            months[months.index(before: selectedMonthIndex)]
        } else if let displayedYearIndex, displayedYearIndex > years.startIndex {
            chronologicalMonths(in: years[years.index(before: displayedYearIndex)]).last
        } else {
            nil
        }

        let lastMonthIndex = months.index(before: months.endIndex)
        let nextMonth: ChineseLunarMonth? = if selectedMonthIndex < lastMonthIndex {
            months[months.index(after: selectedMonthIndex)]
        } else if let displayedYearIndex, displayedYearIndex < years.index(before: years.endIndex) {
            chronologicalMonths(in: years[years.index(after: displayedYearIndex)]).first
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

        pendingYearTransition = nil
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
        pendingYearTransition = nil
        refreshToday()

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
        guard let destinationYear = years.first(where: { $0.lunarYearNumber == yearNumber }),
              let direction = LunarYearTransitionDirection(
                  from: browseState.displayedYearNumber,
                  to: yearNumber
              )
        else {
            return
        }

        let destinationMonthIndices = chronologicalMonths(in: destinationYear)
            .map(\.lunarMonthIndex)

        let destinationMonthIndex = direction.destinationMonthIndex(
            in: Array(destinationMonthIndices)
        )
        let sourceMonthIndices = monthsInYearStartOrder.map(\.lunarMonthIndex)

        guard let sourceMonthIndex = direction.sourceMonthIndex(
            in: sourceMonthIndices
        ) else {
            pendingYearTransition = nil
            browseState.select(
                yearNumber: yearNumber,
                monthIndex: destinationMonthIndex
            )
            return
        }

        pendingYearTransition = LunarYearTransitionRequest(
            sourceYearNumber: browseState.displayedYearNumber,
            sourceMonthIndex: sourceMonthIndex,
            destinationYearNumber: yearNumber,
            destinationMonthIndex: destinationMonthIndex
        )
    }

    func completeYearTransitionPreparation(_ sourceMonthIndex: Int) {
        guard let pendingYearTransition,
              pendingYearTransition.sourceMonthIndex == sourceMonthIndex,
              pendingYearTransition.sourceYearNumber == browseState.displayedYearNumber
        else {
            return
        }

        self.pendingYearTransition = nil
        browseState.select(
            yearNumber: pendingYearTransition.destinationYearNumber,
            monthIndex: pendingYearTransition.destinationMonthIndex
        )
    }

    func chronologicalMonths(in year: ChineseLunarYear) -> [ChineseLunarMonth] {
        year.months.sorted { $0.lunarMonthIndex < $1.lunarMonthIndex }
    }
}
