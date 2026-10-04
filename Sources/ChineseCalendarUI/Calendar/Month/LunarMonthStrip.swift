import ChineseCalendarPersistence
import SwiftUI

/// 显示一个农历年内的月份，并保持选中月份位于可见区域。
struct LunarMonthStrip: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let monthSpacing: CGFloat = 6
        static let edgeFadeWidth: CGFloat = 16
        static let yearPreparationDuration: TimeInterval = 0.25
    }

    let months: [ChineseLunarMonth]
    let selectedMonth: ChineseLunarMonth
    let selectMonth: (ChineseLunarMonth) -> Void
    let yearTransitionPreparationMonthIndex: Int?
    let completeYearTransitionPreparation: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var scrollPosition: ScrollPosition

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
        _scrollPosition = State(initialValue: ScrollPosition(id: selectedMonth.lunarMonthIndex, anchor: .center))
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Constants.monthSpacing) {
                ForEach(months, id: \.lunarMonthIndex) { month in
                    LunarMonthButton(
                        title: LunarMonthDisplay.title(for: month),
                        isSelected: month.lunarMonthIndex == selectedMonth.lunarMonthIndex
                    ) {
                        selectMonth(month)
                    }
                    .id(month.lunarMonthIndex)
                }
            }
            .scrollTargetLayout()
        }
        // Keep the first and last buttons entirely inside the opaque part of the mask.
        .contentMargins(.horizontal, Constants.edgeFadeWidth, for: .scrollContent)
        .scrollIndicators(.hidden)
        .mask { edgeFadeMask }
        .scrollPosition($scrollPosition, anchor: .center)
        .onChange(of: selectedMonth.lunarMonthIndex, initial: true) {
            scrollToSelectedMonth()
        }
        .onChange(of: yearTransitionPreparationMonthIndex) {
            prepareForYearTransitionIfNeeded()
        }
    }

    private var edgeFadeMask: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [reduceTransparency ? .black : .clear, .black],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: Constants.edgeFadeWidth)

            Rectangle()
                .fill(.black)

            LinearGradient(
                colors: [.black, reduceTransparency ? .black : .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: Constants.edgeFadeWidth)
        }
        .allowsHitTesting(false)
    }

    private func scrollToSelectedMonth() {
        scrollPosition.scrollTo(id: selectedMonth.lunarMonthIndex, anchor: .center)
    }

    private func prepareForYearTransitionIfNeeded() {
        guard let yearTransitionPreparationMonthIndex else {
            return
        }

        guard scrollPosition.viewID(type: Int.self) != yearTransitionPreparationMonthIndex,
              !reduceMotion
        else {
            scrollPosition.scrollTo(id: yearTransitionPreparationMonthIndex, anchor: .center)
            completeYearTransitionPreparation(yearTransitionPreparationMonthIndex)
            return
        }

        withAnimation(.smooth(duration: Constants.yearPreparationDuration)) {
            scrollPosition.scrollTo(id: yearTransitionPreparationMonthIndex, anchor: .center)
        } completion: {
            completeYearTransitionPreparation(yearTransitionPreparationMonthIndex)
        }
    }
}

#Preview("月份条 · 首月") {
    LunarMonthStripPreviewContent(initialMonthOffset: 0)
}

#Preview("月份条 · 闰月") {
    LunarMonthStripPreviewContent(initialMonthOffset: 6)
}

#Preview("月份条 · 十一月") {
    LunarMonthStripPreviewContent(initialMonthOffset: 11)
}

#Preview("月份条 · 末月") {
    LunarMonthStripPreviewContent(initialMonthOffset: 12)
}

#Preview("月份条 · 深色") {
    LunarMonthStripPreviewContent(initialMonthOffset: 6)
        .preferredColorScheme(.dark)
}

#Preview("月份条 · 最长闰月名称与最大字体") {
    LunarMonthStripPreviewContent(initialMonthOffset: 11, leapMonthNumber: 11)
        .dynamicTypeSize(.accessibility5)
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
