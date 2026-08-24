import ChineseCalendarPersistence
import SwiftUI

/// 显示一个农历年内的月份，并保持选中月份位于可见区域。
struct LunarMonthStrip: View {
    let months: [ChineseLunarMonth]
    let selectedMonth: ChineseLunarMonth
    let selectMonth: (ChineseLunarMonth) -> Void

    @State private var scrollPosition: Int?

    init(
        months: [ChineseLunarMonth],
        selectedMonth: ChineseLunarMonth,
        selectMonth: @escaping (ChineseLunarMonth) -> Void
    ) {
        self.months = months
        self.selectedMonth = selectedMonth
        self.selectMonth = selectMonth
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
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .onChange(of: selectedMonth.lunarMonthIndex, initial: true) {
            scrollToSelectedMonth()
        }
    }

    private func scrollToSelectedMonth() {
        scrollPosition = selectedMonth.lunarMonthIndex
    }
}
