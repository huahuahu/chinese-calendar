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
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .onChange(of: selectedMonth.lunarMonthIndex, initial: true) {
            scrollToSelectedMonth()
        }
        .onChange(of: yearTransitionPreparationMonthIndex) {
            prepareForYearTransitionIfNeeded()
        }
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
