import ChineseCalendarPersistence
import SwiftUI

/// 显示一个农历年内的月份，并保持选中月份位于可见区域。
struct LunarMonthStrip: View {
    let months: [ChineseLunarMonth]
    let selectedMonth: ChineseLunarMonth
    let selectMonth: (ChineseLunarMonth) -> Void
    let yearTransitionPreparationMonthIndex: Int?
    let completeYearTransitionPreparation: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scrollPosition: Int?

    init(
        months: [ChineseLunarMonth],
        selectedMonth: ChineseLunarMonth,
        selectMonth: @escaping (ChineseLunarMonth) -> Void,
        yearTransitionPreparationMonthIndex: Int?,
        completeYearTransitionPreparation: @escaping (Int) -> Void
    ) {
        self.months = months
        self.selectedMonth = selectedMonth
        self.selectMonth = selectMonth
        self.yearTransitionPreparationMonthIndex = yearTransitionPreparationMonthIndex
        self.completeYearTransitionPreparation = completeYearTransitionPreparation
        _scrollPosition = State(initialValue: selectedMonth.lunarMonthIndex)
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(months, id: \.lunarMonthIndex) { month in
                    VStack(spacing: 0) {
                        Button {
                            selectMonth(month)
                        } label: {
                            Text(LunarMonthDisplay.title(for: month))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(minWidth: 76, minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .tint(month.lunarMonthIndex == selectedMonth.lunarMonthIndex ? .accentColor : nil)
                        .accessibilityAddTraits(
                            month.lunarMonthIndex == selectedMonth.lunarMonthIndex ? .isSelected : []
                        )
                    }
                    .id(month.lunarMonthIndex)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .defaultScrollAnchor(initialScrollAnchor, for: .initialOffset)
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .onChange(of: selectedMonth.lunarMonthIndex, initial: true) {
            scrollToSelectedMonth()
        }
        .onChange(of: yearTransitionPreparationMonthIndex) {
            prepareForYearTransitionIfNeeded()
        }
    }

    private var initialScrollAnchor: UnitPoint {
        if selectedMonth.lunarMonthIndex == months.last?.lunarMonthIndex {
            return .trailing
        }

        if selectedMonth.lunarMonthIndex == months.first?.lunarMonthIndex {
            return .leading
        }

        return .center
    }

    private func scrollToSelectedMonth() {
        scrollPosition = selectedMonth.lunarMonthIndex
    }

    private func prepareForYearTransitionIfNeeded() {
        guard let yearTransitionPreparationMonthIndex else {
            return
        }

        guard scrollPosition != yearTransitionPreparationMonthIndex,
              !reduceMotion
        else {
            scrollPosition = yearTransitionPreparationMonthIndex
            completeYearTransitionPreparation(yearTransitionPreparationMonthIndex)
            return
        }

        withAnimation(.smooth(duration: 0.25)) {
            scrollPosition = yearTransitionPreparationMonthIndex
        } completion: {
            completeYearTransitionPreparation(yearTransitionPreparationMonthIndex)
        }
    }
}

#Preview("含闰月的月份条") {
    @Previewable @State var selectedMonthOffset = 6

    let months: [ChineseLunarMonth] = {
        let year = ChineseLunarYear(lunarYearNumber: 2026, yearStemIndex: 2, yearBranchIndex: 6)
        let regularMonths = (1 ... 12).map { monthNumber in
            ChineseLunarMonth(
                lunarMonthIndex: monthNumber < 7 ? monthNumber : monthNumber + 1,
                monthNumberInYear: monthNumber,
                isLeapMonth: false,
                dayCount: monthNumber.isMultiple(of: 2) ? 29 : 30,
                monthStemIndex: (monthNumber - 1) % 10,
                monthBranchIndex: (monthNumber - 1) % 12,
                chineseLunarYear: year
            )
        }
        let leapMonth = ChineseLunarMonth(
            lunarMonthIndex: 7,
            monthNumberInYear: 6,
            isLeapMonth: true,
            dayCount: 29,
            monthStemIndex: 6,
            monthBranchIndex: 6,
            chineseLunarYear: year
        )
        return Array(regularMonths.prefix(6))
            + [leapMonth]
            + regularMonths.dropFirst(6)
    }()

    NavigationStack {
        ScrollView {
            LunarMonthStrip(
                months: months,
                selectedMonth: months[selectedMonthOffset],
                selectMonth: { month in
                    if let index = months.firstIndex(where: { $0.lunarMonthIndex == month.lunarMonthIndex }) {
                        selectedMonthOffset = index
                    }
                },
                yearTransitionPreparationMonthIndex: nil,
                completeYearTransitionPreparation: { _ in }
            )
            .padding()
        }
        .navigationTitle("月份选择")
    }
}

#Preview("有可能空白 · 没有月份") {
    let selectedMonth = ChineseLunarMonth(
        lunarMonthIndex: 3,
        monthNumberInYear: 1,
        isLeapMonth: false,
        dayCount: 30,
        monthStemIndex: 2,
        monthBranchIndex: 2,
        chineseLunarYear: ChineseLunarYear(lunarYearNumber: 2026, yearStemIndex: 0, yearBranchIndex: 0)
    )

    NavigationStack {
        ScrollView {
            LunarMonthStrip(
                months: [],
                selectedMonth: selectedMonth,
                selectMonth: { _ in },
                yearTransitionPreparationMonthIndex: nil,
                completeYearTransitionPreparation: { _ in }
            )
            .padding()
        }
        .navigationTitle("月份选择")
    }
}

#Preview("后六月 · 仅命名示例，非历史记录") {
    @Previewable @State var selectedMonthOffset = 0

    // 当前导入库没有后六月记录；这里只验证模型的 .post 命名和重复月份的选择。
    let year = ChineseLunarYear(lunarYearNumber: -220, yearStemIndex: 0, yearBranchIndex: 0)
    let months = [6, 6, 7].enumerated().map { offset, number in
        ChineseLunarMonth(
            lunarMonthIndex: offset,
            monthNumberInYear: number,
            isLeapMonth: offset == 1,
            intercalaryMonthNameStyle: offset == 1 ? .post : .leap,
            dayCount: offset == 1 ? 29 : 30,
            monthStemIndex: 0,
            monthBranchIndex: 0,
            chineseLunarYear: year
        )
    }

    NavigationStack {
        ScrollView {
            LunarMonthStrip(
                months: months,
                selectedMonth: months[selectedMonthOffset],
                selectMonth: { selectedMonthOffset = $0.lunarMonthIndex },
                yearTransitionPreparationMonthIndex: nil,
                completeYearTransitionPreparation: { _ in }
            )
            .padding()
        }
        .navigationTitle("后六月命名示例")
    }
}
