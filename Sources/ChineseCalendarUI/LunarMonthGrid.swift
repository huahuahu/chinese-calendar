import ChineseCalendarCore
import ChineseCalendarPersistence
import Foundation
import SFSafeSymbols
import SwiftData
import SwiftUI

struct LunarMonthGrid: View {
    let year: ChineseLunarYear
    let months: [ChineseLunarMonth]
    let month: ChineseLunarMonth
    @Binding var selectedMonthIndex: Int?
    let showYearList: (() -> Void)?

    @Environment(\.calendarStoreContentLevel) private var storeContentLevel
    @State private var selectedDayIndex: Int?
    @Query private var days: [ChineseLunarDay]
    private let todayComponents: DateComponents

    init(
        year: ChineseLunarYear,
        months: [ChineseLunarMonth],
        month: ChineseLunarMonth,
        selectedMonthIndex: Binding<Int?>,
        showYearList: (() -> Void)? = nil,
        today: Date = .now
    ) {
        self.year = year
        self.months = months
        self.month = month
        _selectedMonthIndex = selectedMonthIndex
        self.showYearList = showYearList
        todayComponents = Self.gregorianDateComponents(for: today)

        let lunarMonthIndex = month.lunarMonthIndex
        _days = Query(
            filter: #Predicate<ChineseLunarDay> { day in
                day.lunarMonthIndex == lunarMonthIndex
            },
            sort: \ChineseLunarDay.dayNumberInMonth
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MonthSwitcher(
                title: monthNavigationTitle,
                subtitle: monthNavigationSubtitle,
                months: months,
                selectedMonth: month,
                selectedMonthIndex: $selectedMonthIndex,
                showYearList: showYearList
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
                                selectedDayIndex = day.dayIndex
                            } label: {
                                LunarDayGridCell(
                                    day: day,
                                    isSelected: day.dayIndex == selectedDay?.dayIndex,
                                    isToday: isToday(day)
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
        .onAppear(perform: selectDefaultDayIfNeeded)
        .onChange(of: days.map(\.dayIndex)) {
            selectDefaultDayIfNeeded()
        }
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 58), spacing: 8)]
    }

    private var selectedDay: ChineseLunarDay? {
        if let selectedDayIndex,
           let selectedDay = days.first(where: { $0.dayIndex == selectedDayIndex }) {
            return selectedDay
        }

        return defaultSelectedDay
    }

    private var defaultSelectedDay: ChineseLunarDay? {
        days.first(where: isToday) ?? days.first
    }

    private var monthNavigationTitle: String {
        let yearTitle = LunarCalendarFormatting.yearSubtitle(
            stemIndex: year.yearStemIndex,
            branchIndex: year.yearBranchIndex
        )
        return "\(yearTitle) \(LunarMonthDisplay.title(for: month))"
    }

    private var monthNavigationSubtitle: String {
        if let civilDateRangeTitle {
            let selectionText = defaultSelectedDay.map(isToday) == true ? "今天优先选中" : "默认选中初一"
            return "\(civilDateRangeTitle) · \(selectionText)"
        }

        return LunarCalendarFormatting.monthSubtitle(
            dayCount: month.dayCount,
            stemIndex: month.monthStemIndex,
            branchIndex: month.monthBranchIndex
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
            selectedDayIndex = nil
            return
        }

        if let selectedDayIndex,
           days.contains(where: { $0.dayIndex == selectedDayIndex }) {
            return
        }

        selectedDayIndex = defaultSelectedDay?.dayIndex
    }

    private func isToday(_ day: ChineseLunarDay) -> Bool {
        guard let civilDate = day.calendarDay?.civilDate,
              civilDate.calendarStyle == .gregorian
        else {
            return false
        }

        return civilDate.year == todayComponents.year
            && civilDate.month == todayComponents.month
            && civilDate.dayOfMonth == todayComponents.day
    }

    private func fullCivilDateTitle(for civilDate: CivilDate) -> String {
        let prefix = civilDate.calendarStyle == .julian ? "儒略" : "公历"
        return "\(prefix) \(civilDate.year)年\(civilDate.month)月\(civilDate.dayOfMonth)日"
    }

    private static func gregorianDateComponents(for date: Date) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
}
