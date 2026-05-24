import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftData
import SwiftUI

struct LunarYearDetailView: View {
    let year: ChineseLunarYear
    @Binding var selectedMonthIndex: Int?
    let canSelectPreviousYear: Bool
    let canSelectNextYear: Bool
    let selectPreviousYear: () -> Void
    let selectNextYear: () -> Void

    @Query private var months: [ChineseLunarMonth]

    init(
        year: ChineseLunarYear,
        selectedMonthIndex: Binding<Int?>,
        canSelectPreviousYear: Bool,
        canSelectNextYear: Bool,
        selectPreviousYear: @escaping () -> Void,
        selectNextYear: @escaping () -> Void
    ) {
        self.year = year
        _selectedMonthIndex = selectedMonthIndex
        self.canSelectPreviousYear = canSelectPreviousYear
        self.canSelectNextYear = canSelectNextYear
        self.selectPreviousYear = selectPreviousYear
        self.selectNextYear = selectNextYear

        let lunarYearNumber = year.lunarYearNumber
        _months = Query(
            filter: #Predicate<ChineseLunarMonth> { month in
                month.lunarYearNumber == lunarYearNumber
            },
            sort: \ChineseLunarMonth.lunarMonthIndex
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
                Text(yearSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if monthsInYearStartOrder.isEmpty {
                    ContentUnavailableView("没有月份数据", systemImage: "calendar.badge.exclamationmark")
                } else if let selectedMonth {
                    MonthSwitcher(
                        months: monthsInYearStartOrder,
                        selectedMonth: selectedMonth,
                        selectedMonthIndex: $selectedMonthIndex
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
                Button("上一年", systemImage: "chevron.left", action: selectPreviousYear)
                    .disabled(!canSelectPreviousYear)
                    .help("切换到上一年")

                Button("下一年", systemImage: "chevron.right", action: selectNextYear)
                    .disabled(!canSelectNextYear)
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
        guard monthsInYearStartOrder.contains(where: { $0.lunarMonthIndex == selectedMonthIndex }) == false else {
            return
        }

        selectedMonthIndex = monthsInYearStartOrder.first?.lunarMonthIndex
    }
}
