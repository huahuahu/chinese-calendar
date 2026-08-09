import ChineseCalendarCore
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

/// 显示在 LunarMonthGrid 顶部，用于切换当前查看的农历月份。
struct MonthSwitcher: View {
    let title: String
    let subtitle: String
    let months: [ChineseLunarMonth]
    let selectedMonth: ChineseLunarMonth
    let showYearPicker: (() -> Void)?
    let canSelectPreviousMonth: Bool
    let canSelectNextMonth: Bool
    let selectPreviousMonth: () -> Void
    let selectNextMonth: () -> Void
    let selectMonth: (ChineseLunarMonth) -> Void

    @State private var scrollPosition: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Button("上个月", systemSymbol: .chevronLeft, action: selectPreviousMonth)
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(!canSelectPreviousMonth)
                    .help("切换到上个月")

                titleContent
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("下个月", systemSymbol: .chevronRight, action: selectNextMonth)
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(!canSelectNextMonth)
                    .help("切换到下个月")
            }

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
            .onAppear(perform: scrollToSelectedMonth)
            .onChange(of: selectedMonth.lunarMonthIndex) {
                scrollToSelectedMonth()
            }
        }
    }

    @ViewBuilder
    private var titleContent: some View {
        if let showYearPicker {
            Button(action: showYearPicker) {
                monthTitleContent
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityHint("打开年份选择器")
        } else {
            monthTitleContent
        }
    }

    private var monthTitleContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2)
                .bold()
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func scrollToSelectedMonth() {
        scrollPosition = selectedMonth.lunarMonthIndex
    }
}
