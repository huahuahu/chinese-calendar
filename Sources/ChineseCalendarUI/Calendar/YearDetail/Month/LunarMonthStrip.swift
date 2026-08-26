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
                    Button {
                        selectMonth(month)
                    } label: {
                        Text(LunarMonthDisplay.title(for: month))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(minWidth: 76, minHeight: 44)
                    }
                    .id(month.lunarMonthIndex)
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .tint(month.lunarMonthIndex == selectedMonth.lunarMonthIndex ? .accentColor : nil)
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
