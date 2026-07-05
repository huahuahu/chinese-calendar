import ChineseCalendarCore
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

struct LunarYearDetailView: View {
    let year: ChineseLunarYear
    @Binding var selectedMonthIndex: Int?
    let canSelectPreviousYear: Bool
    let canSelectNextYear: Bool
    let selectPreviousYear: () -> Void
    let selectNextYear: () -> Void
    let showYearList: (() -> Void)?

    @Query private var months: [ChineseLunarMonth]
    @Query private var todayCivilDates: [CivilDate]

    init(
        year: ChineseLunarYear,
        selectedMonthIndex: Binding<Int?>,
        canSelectPreviousYear: Bool,
        canSelectNextYear: Bool,
        selectPreviousYear: @escaping () -> Void,
        selectNextYear: @escaping () -> Void,
        showYearList: (() -> Void)? = nil,
        today: Date = .now
    ) {
        self.year = year
        _selectedMonthIndex = selectedMonthIndex
        self.canSelectPreviousYear = canSelectPreviousYear
        self.canSelectNextYear = canSelectNextYear
        self.selectPreviousYear = selectPreviousYear
        self.selectNextYear = selectNextYear
        self.showYearList = showYearList

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
                        selectedMonthIndex: $selectedMonthIndex,
                        showYearList: showYearList
                    )
                    .id(selectedMonth.lunarMonthIndex)
                }
            }
            .padding()
            .frame(maxWidth: 980, alignment: .leading)
        }
        .onAppear(perform: selectDefaultMonthIfNeeded)
        .onChange(of: year.lunarYearNumber) {
            selectDefaultMonthIfNeeded()
        }
        .navigationTitle("日历")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("上一年", systemSymbol: .chevronLeft, action: selectPreviousYear)
                    .disabled(!canSelectPreviousYear)
                    .help("切换到上一年")

                Button("下一年", systemSymbol: .chevronRight, action: selectNextYear)
                    .disabled(!canSelectNextYear)
                    .help("切换到下一年")
            }
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

        selectedMonthIndex = todayMonthIndex ?? monthsInYearStartOrder.first?.lunarMonthIndex
    }

    private static func gregorianDateComponents(for date: Date) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
}
