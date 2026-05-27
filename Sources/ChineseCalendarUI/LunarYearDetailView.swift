import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftData
import SwiftUI

struct LunarYearDetailView: View {
    let year: ChineseLunarYear
    @Bindable var state: CalendarAppState
    let yearNumbers: [Int]

    @Query private var months: [ChineseLunarMonth]

    init(
        year: ChineseLunarYear,
        state: CalendarAppState,
        yearNumbers: [Int]
    ) {
        self.year = year
        self.state = state
        self.yearNumbers = yearNumbers

        let lunarYearNumber = year.lunarYearNumber
        _months = Query(
            filter: #Predicate<ChineseLunarMonth> { month in
                month.lunarYearNumber == lunarYearNumber
            },
            sort: \ChineseLunarMonth.lunarMonthIndex
        )
    }

    private var selectedMonth: ChineseLunarMonth? {
        guard let selectedMonthIndex = state.selectedMonthIndex else {
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
                Text(yearSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if monthsInYearStartOrder.isEmpty {
                    ContentUnavailableView("没有月份数据", systemImage: "calendar.badge.exclamationmark")
                } else if let selectedMonth {
                    MonthSwitcher(
                        months: monthsInYearStartOrder,
                        selectedMonth: selectedMonth,
                        state: state
                    )

                    LunarMonthGrid(month: selectedMonth)
                }
            }
            .padding()
            .frame(maxWidth: 980, alignment: .leading)
        }
        .onAppear(perform: selectDefaultMonthIfNeeded)
        .onChange(of: year.lunarYearNumber) {
            selectDefaultMonthIfNeeded()
        }
        .navigationTitle(LunarCalendarFormatting.yearTitle(lunarYearNumber: year.lunarYearNumber))
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("上一年", systemImage: "chevron.left") {
                    state.selectPreviousYear(in: yearNumbers)
                }
                .disabled(!state.canSelectPreviousYear(in: yearNumbers))
                .help("切换到上一年")

                Button("下一年", systemImage: "chevron.right") {
                    state.selectNextYear(in: yearNumbers)
                }
                .disabled(!state.canSelectNextYear(in: yearNumbers))
                .help("切换到下一年")
            }
        }
    }

    private var yearSubtitle: String {
        let sexagenaryYear = LunarCalendarFormatting.yearSubtitle(
            stemIndex: year.yearStemIndex,
            branchIndex: year.yearBranchIndex
        )
        return "\(sexagenaryYear) · \(monthsInYearStartOrder.count)个月"
    }

    private func selectDefaultMonthIfNeeded() {
        state.selectDefaultMonthIfNeeded(from: monthsInYearStartOrder.map(\.lunarMonthIndex))
    }
}
