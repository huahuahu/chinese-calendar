import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftUI

struct MonthSwitcher: View {
    let months: [ChineseLunarMonth]
    let selectedMonth: ChineseLunarMonth
    @Binding var selectedMonthIndex: Int?

    private var selectedIndex: Int? {
        months.firstIndex { $0.lunarMonthIndex == selectedMonth.lunarMonthIndex }
    }

    private var canSelectPreviousMonth: Bool {
        guard let selectedIndex else {
            return false
        }

        return selectedIndex > months.startIndex
    }

    private var canSelectNextMonth: Bool {
        guard let selectedIndex else {
            return false
        }

        return selectedIndex < months.index(before: months.endIndex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button("上个月", systemImage: "chevron.left", action: selectPreviousMonth)
                    .labelStyle(.iconOnly)
                    .disabled(!canSelectPreviousMonth)
                    .help("切换到上个月")

                VStack(alignment: .leading) {
                    Text(monthTitle(selectedMonth))
                        .font(.headline)
                    Text(LunarCalendarFormatting.monthSubtitle(
                        dayCount: selectedMonth.dayCount,
                        stemIndex: selectedMonth.monthStemIndex,
                        branchIndex: selectedMonth.monthBranchIndex
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)

                Button("下个月", systemImage: "chevron.right", action: selectNextMonth)
                    .labelStyle(.iconOnly)
                    .disabled(!canSelectNextMonth)
                    .help("切换到下个月")
            }

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(months, id: \.lunarMonthIndex) { month in
                        Button {
                            selectedMonthIndex = month.lunarMonthIndex
                        } label: {
                            VStack(spacing: 4) {
                                Text(monthTitle(month))
                                Text("\(month.dayCount)天")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(minWidth: 76)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .tint(month.lunarMonthIndex == selectedMonth.lunarMonthIndex ? .accentColor : nil)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func selectPreviousMonth() {
        guard let selectedIndex, selectedIndex > months.startIndex else {
            return
        }

        selectedMonthIndex = months[months.index(before: selectedIndex)].lunarMonthIndex
    }

    private func selectNextMonth() {
        guard let selectedIndex, selectedIndex < months.index(before: months.endIndex) else {
            return
        }

        selectedMonthIndex = months[months.index(after: selectedIndex)].lunarMonthIndex
    }

    private func monthTitle(_ month: ChineseLunarMonth) -> String {
        LunarCalendarFormatting.monthTitle(
            monthNumberInYear: month.monthNumberInYear,
            isLeapMonth: month.isLeapMonth,
            intercalaryMonthNameStyle: month.intercalaryMonthNameStyle,
            dayCount: month.dayCount
        )
    }
}
