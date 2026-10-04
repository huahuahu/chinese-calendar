import ChineseCalendarPersistence
import SwiftUI

/// Synthetic month names for layout and interaction checks, not a historical year.
struct LunarMonthStripPreviewContent: View {
    private let months: [ChineseLunarMonth]
    @State private var selectedMonthOffset: Int

    init(initialMonthOffset: Int, leapMonthNumber: Int = 6) {
        _selectedMonthOffset = State(initialValue: initialMonthOffset)
        let year = ChineseLunarYear(lunarYearNumber: 2026, yearStemIndex: 2, yearBranchIndex: 6)
        let regularMonths = (1 ... 12).map { monthNumber in
            ChineseLunarMonth(
                lunarMonthIndex: monthNumber <= leapMonthNumber ? monthNumber : monthNumber + 1,
                monthNumberInYear: monthNumber,
                isLeapMonth: false,
                dayCount: monthNumber.isMultiple(of: 2) ? 29 : 30,
                monthStemIndex: (monthNumber - 1) % 10,
                monthBranchIndex: (monthNumber - 1) % 12,
                chineseLunarYear: year
            )
        }
        let leapMonth = ChineseLunarMonth(
            lunarMonthIndex: leapMonthNumber + 1,
            monthNumberInYear: leapMonthNumber,
            isLeapMonth: true,
            dayCount: 29,
            monthStemIndex: leapMonthNumber % 10,
            monthBranchIndex: leapMonthNumber % 12,
            chineseLunarYear: year
        )
        months = Array(regularMonths.prefix(leapMonthNumber))
            + [leapMonth]
            + regularMonths.dropFirst(leapMonthNumber)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LunarMonthStrip(
                    months: months,
                    selectedMonth: months[selectedMonthOffset],
                    selectMonth: selectMonth,
                    yearTransitionPreparationMonthIndex: nil,
                    completeYearTransitionPreparation: { _ in }
                )
                .padding()
            }
            .navigationTitle("月份选择")
        }
    }

    private func selectMonth(_ month: ChineseLunarMonth) {
        if let index = months.firstIndex(where: { $0.lunarMonthIndex == month.lunarMonthIndex }) {
            selectedMonthOffset = index
        }
    }
}
