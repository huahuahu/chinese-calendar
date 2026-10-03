import ChineseCalendarCore
import ChineseCalendarLogging
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 显示由选中日推导出的年月，并负责月、年与“今天”选择入口。
struct YearMonthHeader: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let sectionSpacing: CGFloat = 12
        static let headerSpacing: CGFloat = 10
        static let navigationButtonDimension: CGFloat = 44
        static let titleSpacing: CGFloat = 4
        static let reducedMotionDuration: TimeInterval = 0.2
        static let yearSelectionDuration: TimeInterval = 0.35
    }

    @Environment(CalendarSelection.self) private var selection
    @Environment(CalendarToday.self) private var today
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var modelContext

    let month: ChineseLunarMonth

    @State private var isYearPickerPresented = false
    @State private var pendingYearTransition: LunarYearTransitionRequest?
    @State private var yearTransitionContext = LunarYearTransitionContext()

    var body: some View {
        let previousMonth = adjacentMonth(direction: .earlier)
        let nextMonth = adjacentMonth(direction: .later)

        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            HStack(alignment: .center, spacing: Constants.headerSpacing) {
                Button("上个月", systemSymbol: .chevronLeft) {
                    selectMonth(previousMonth)
                }
                .labelStyle(.iconOnly)
                .frame(
                    width: Constants.navigationButtonDimension,
                    height: Constants.navigationButtonDimension
                )
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(previousMonth == nil)
                .help("切换到上个月")

                ZStack(alignment: .leading) {
                    titleContent
                        .id(month.lunarYearNumber)
                        .transition(yearTransition)
                }
                .clipped()
                .animation(yearSelectionAnimation, value: month.lunarYearNumber)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button("下个月", systemSymbol: .chevronRight) {
                    selectMonth(nextMonth)
                }
                .labelStyle(.iconOnly)
                .frame(
                    width: Constants.navigationButtonDimension,
                    height: Constants.navigationButtonDimension
                )
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(nextMonth == nil)
                .help("切换到下个月")
            }

            ZStack(alignment: .leading) {
                LunarMonthStrip(
                    months: months,
                    selectedMonth: month,
                    selectMonth: selectMonth,
                    yearTransitionPreparationMonthIndex: pendingYearTransition?.sourceMonthIndex,
                    completeYearTransitionPreparation: completeYearTransitionPreparation
                )
                .id(month.lunarYearNumber)
                .transition(yearTransition)
            }
            .clipped()
            .animation(yearSelectionAnimation, value: month.lunarYearNumber)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("今天", action: selectToday)
            }
        }
        .sheet(isPresented: $isYearPickerPresented) {
            NavigationStack {
                CalendarYearPickerView(selectYear: selectYearFromPicker)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("关闭") {
                                isYearPickerPresented = false
                            }
                        }
                    }
            }
        }
    }
}

private extension YearMonthHeader {
    private var year: ChineseLunarYear? {
        month.chineseLunarYear
    }

    private var months: [ChineseLunarMonth] {
        guard let year else {
            return [month]
        }

        return year.months.sorted { $0.lunarMonthIndex < $1.lunarMonthIndex }
    }

    private var monthNavigationTitle: String {
        let yearTitle: String = if let year {
            LunarCalendarFormatting.yearSubtitle(
                stemIndex: year.yearStemIndex,
                branchIndex: year.yearBranchIndex
            )
        } else {
            String(month.lunarYearNumber)
        }

        return "\(yearTitle) \(LunarMonthDisplay.title(for: month))"
    }

    private var monthNavigationSubtitle: String {
        let fallback = LunarCalendarFormatting.monthSubtitle(
            dayCount: month.dayCount,
            stemIndex: month.monthStemIndex,
            branchIndex: month.monthBranchIndex
        )
        return Self.monthNavigationSubtitle(
            civilDateRangeTitle: civilDateRangeTitle,
            fallback: fallback
        )
    }

    private var civilDateRangeTitle: String? {
        let julianDayNumbers = month.days.map { $0.calendarDay?.julianDayNumber }
        guard let julianDayRange = Self.julianDayRange(in: julianDayNumbers) else {
            return nil
        }

        return LunarCalendarFormatting.civilDateRangeTitle(
            fromJulianDayNumber: julianDayRange.lowerBound,
            throughJulianDayNumber: julianDayRange.upperBound,
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
        reduceMotion
            ? .easeInOut(duration: Constants.reducedMotionDuration)
            : .smooth(duration: Constants.yearSelectionDuration)
    }

    private var titleContent: some View {
        Button {
            isYearPickerPresented = true
        } label: {
            VStack(alignment: .leading, spacing: Constants.titleSpacing) {
                Text(monthNavigationTitle)
                    .font(.title2)
                    .bold()
                Text(monthNavigationSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityHint("打开年份选择器")
    }

    private func adjacentMonth(
        direction: LunarYearTransitionDirection
    ) -> ChineseLunarMonth? {
        do {
            return try resolver.adjacentMonth(
                to: month.lunarMonthIndex,
                direction: direction
            )
        } catch {
            ChineseCalendarLog.ui.error("无法查询相邻农历月：\(error.localizedDescription)")
            return nil
        }
    }

    private func selectMonth(_ destinationMonth: ChineseLunarMonth?) {
        guard let destinationMonth,
              destinationMonth.lunarMonthIndex != month.lunarMonthIndex
        else {
            return
        }

        let crossesYear = destinationMonth.lunarYearNumber != month.lunarYearNumber
        if crossesYear {
            let direction = LunarYearTransitionDirection(
                from: month.lunarYearNumber,
                to: destinationMonth.lunarYearNumber
            )
            if let direction {
                yearTransitionContext.direction = direction
            }
        }

        ChineseCalendarPerformanceSignposts.shared.beginMonthSwitch(
            from: month.lunarMonthIndex,
            to: destinationMonth.lunarMonthIndex,
            crossesYear: crossesYear
        )

        pendingYearTransition = nil
        selectDay(inMonth: destinationMonth.lunarMonthIndex)
    }

    private func selectToday() {
        pendingYearTransition = nil
        today.refresh()

        do {
            let destinationDayIndex = try resolver.todayDayIndex(
                julianDayNumber: today.julianDayNumber
            )
            let destinationYearNumber = try resolver.yearNumber(forDayIndex: destinationDayIndex)

            if let destinationYearNumber {
                let direction = LunarYearTransitionDirection(
                    from: month.lunarYearNumber,
                    to: destinationYearNumber
                )
                if let direction {
                    yearTransitionContext.direction = direction
                }
            }

            selection.select(dayIndex: destinationDayIndex)
        } catch {
            ChineseCalendarLog.ui.error("无法选择今天：\(error.localizedDescription)")
            selection.select(dayIndex: nil)
        }
    }

    private func selectYearFromPicker(_ yearNumber: Int) {
        isYearPickerPresented = false
        selectYear(yearNumber)
    }

    private func selectYear(_ yearNumber: Int) {
        guard let direction = LunarYearTransitionDirection(
            from: month.lunarYearNumber,
            to: yearNumber
        ) else {
            return
        }

        yearTransitionContext.direction = direction

        do {
            let destinationMonthIndex = try resolver.boundaryMonthIndex(
                inYear: yearNumber,
                direction: direction,
                isSource: false
            )
            guard let sourceMonthIndex = try resolver.boundaryMonthIndex(
                inYear: month.lunarYearNumber,
                direction: direction,
                isSource: true
            ) else {
                pendingYearTransition = nil
                selectBoundaryDay(inYear: yearNumber, direction: direction)
                return
            }

            pendingYearTransition = LunarYearTransitionRequest(
                sourceYearNumber: month.lunarYearNumber,
                sourceMonthIndex: sourceMonthIndex,
                destinationYearNumber: yearNumber,
                destinationMonthIndex: destinationMonthIndex
            )
        } catch {
            ChineseCalendarLog.ui.error("无法准备农历年份切换：\(error.localizedDescription)")
            pendingYearTransition = nil
            selection.select(dayIndex: nil)
        }
    }

    private func completeYearTransitionPreparation(_ sourceMonthIndex: Int) {
        guard let pendingYearTransition,
              pendingYearTransition.sourceMonthIndex == sourceMonthIndex,
              pendingYearTransition.sourceYearNumber == month.lunarYearNumber
        else {
            return
        }

        self.pendingYearTransition = nil

        if let destinationMonthIndex = pendingYearTransition.destinationMonthIndex {
            selectDay(inMonth: destinationMonthIndex)
        } else {
            selection.select(dayIndex: nil)
        }
    }

    private func selectBoundaryDay(
        inYear yearNumber: Int,
        direction: LunarYearTransitionDirection
    ) {
        do {
            try selection.select(
                dayIndex: resolver.selectedDayIndex(
                    inBoundaryMonthOf: yearNumber,
                    direction: direction,
                    todayJulianDayNumber: today.julianDayNumber
                )
            )
        } catch {
            ChineseCalendarLog.ui.error("无法选择目标年份的日期：\(error.localizedDescription)")
            selection.select(dayIndex: nil)
        }
    }

    private func selectDay(inMonth monthIndex: Int) {
        do {
            try selection.select(
                dayIndex: resolver.selectedDayIndex(
                    inMonth: monthIndex,
                    todayJulianDayNumber: today.julianDayNumber
                )
            )
        } catch {
            ChineseCalendarLog.ui.error("无法选择目标月份的日期：\(error.localizedDescription)")
            selection.select(dayIndex: nil)
        }
    }

    private var resolver: CalendarSelectionResolver {
        CalendarSelectionResolver(modelContext: modelContext)
    }
}

extension YearMonthHeader {
    static func julianDayRange(in julianDayNumbers: [Int?]) -> ClosedRange<Int>? {
        let availableJulianDayNumbers = julianDayNumbers.compactMap(\.self)
        guard let minimumJulianDayNumber = availableJulianDayNumbers.min(),
              let maximumJulianDayNumber = availableJulianDayNumbers.max()
        else {
            return nil
        }

        return minimumJulianDayNumber ... maximumJulianDayNumber
    }

    static func monthNavigationSubtitle(
        civilDateRangeTitle: String?,
        fallback: String
    ) -> String {
        civilDateRangeTitle ?? fallback
    }
}

private struct YearMonthHeaderPreviewContent: View {
    @Environment(CalendarSelection.self) private var selection
    @Query private var days: [ChineseLunarDay]

    var body: some View {
        if let month = days.first(where: { $0.dayIndex == selection.selectedDayIndex })?.chineseLunarMonth {
            YearMonthHeader(month: month)
        } else {
            // 保留真实的无选中日状态；不回退到另一个月份。
            ContentUnavailableView(
                "没有找到日期",
                systemSymbol: .calendarBadgeExclamationmark
            )
        }
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        ScrollView {
            YearMonthHeaderPreviewContent()
                .padding()
        }
        .navigationTitle("日历")
    }
}

#Preview("有可能空白 · 缺少年份与日期关联", traits: .emptySampleData) {
    NavigationStack {
        ScrollView {
            YearMonthHeader(month: ChineseLunarMonth(
                lunarMonthIndex: 3,
                lunarYearNumber: 2026,
                monthNumberInYear: 1,
                isLeapMonth: false,
                dayCount: 30,
                monthStemIndex: 2,
                monthBranchIndex: 2
            ))
            .padding()
        }
        .navigationTitle("日历")
    }
}

#Preview("公元前 1 年 · 跨年导航", traits: .sampleData(.beforeCommonEra)) {
    NavigationStack {
        ScrollView {
            YearMonthHeaderPreviewContent()
                .padding()
        }
        .navigationTitle("年月切换")
    }
}

#Preview("九月 → 后九月 → 次年十月", traits: .sampleData(.postNinthMonth)) {
    NavigationStack {
        ScrollView {
            YearMonthHeaderPreviewContent()
                .padding()
        }
        .navigationTitle("古历后月")
    }
}
