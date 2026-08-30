import ChineseCalendarCore
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

/// 显示在 LunarYearDetailView 中，用于切换当前查看的农历月份。
struct MonthSwitcher: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale

    let year: ChineseLunarYear
    let months: [ChineseLunarMonth]
    let selectedMonth: ChineseLunarMonth
    let showYearPicker: (() -> Void)?
    let canSelectPreviousMonth: Bool
    let canSelectNextMonth: Bool
    let selectPreviousMonth: () -> Void
    let selectNextMonth: () -> Void
    let selectMonth: (ChineseLunarMonth) -> Void
    let yearTransitionContext: LunarYearTransitionContext
    let yearTransitionPreparationMonthIndex: Int?
    let completeYearTransitionPreparation: (Int) -> Void

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

                ZStack(alignment: .leading) {
                    titleContent
                        .id(year.lunarYearNumber)
                        .transition(yearTransition)
                }
                .clipped()
                .animation(yearSelectionAnimation, value: year.lunarYearNumber)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button("下个月", systemSymbol: .chevronRight, action: selectNextMonth)
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(!canSelectNextMonth)
                    .help("切换到下个月")
            }

            ZStack(alignment: .leading) {
                LunarMonthStrip(
                    months: months,
                    selectedMonth: selectedMonth,
                    selectMonth: selectMonth,
                    yearTransitionPreparationMonthIndex: yearTransitionPreparationMonthIndex,
                    completeYearTransitionPreparation: completeYearTransitionPreparation
                )
                .id(year.lunarYearNumber)
                .transition(yearTransition)
            }
            .clipped()
            .animation(yearSelectionAnimation, value: year.lunarYearNumber)
        }
    }

    private var monthNavigationTitle: String {
        let yearTitle = LunarCalendarFormatting.yearSubtitle(
            stemIndex: year.yearStemIndex,
            branchIndex: year.yearBranchIndex
        )
        return "\(yearTitle) \(LunarMonthDisplay.title(for: selectedMonth))"
    }

    private var monthNavigationSubtitle: String {
        let fallback = LunarCalendarFormatting.monthSubtitle(
            dayCount: selectedMonth.dayCount,
            stemIndex: selectedMonth.monthStemIndex,
            branchIndex: selectedMonth.monthBranchIndex
        )
        return Self.monthNavigationSubtitle(
            civilDateRangeTitle: civilDateRangeTitle,
            fallback: fallback
        )
    }

    private var civilDateRangeTitle: String? {
        let days = selectedMonth.days.sorted { $0.dayNumberInMonth < $1.dayNumberInMonth }
        guard let firstJulianDayNumber = days.first?.calendarDay?.julianDayNumber,
              let lastJulianDayNumber = days.last?.calendarDay?.julianDayNumber
        else {
            return nil
        }

        return LunarCalendarFormatting.civilDateRangeTitle(
            fromJulianDayNumber: firstJulianDayNumber,
            throughJulianDayNumber: lastJulianDayNumber,
            locale: locale
        )
    }

    private var yearTransition: AnyTransition {
        guard !reduceMotion else {
            return .opacity
        }

        return AnyTransition(
            LunarYearContextualTransition(context: yearTransitionContext)
        )
    }

    private var yearSelectionAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .smooth(duration: 0.35)
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
            Text(monthNavigationTitle)
                .font(.title2)
                .bold()
            Text(monthNavigationSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

extension MonthSwitcher {
    static func monthNavigationSubtitle(
        civilDateRangeTitle: String?,
        fallback: String
    ) -> String {
        civilDateRangeTitle ?? fallback
    }
}
