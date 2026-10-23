import ChineseCalendarCore
import ChineseCalendarLocalization
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

    @Environment(CalendarPresentationContext.self) private var presentation
    @Environment(CalendarHomeCoordinator.self) private var homeCoordinator
    @Environment(CalendarYearFeature.self) private var feature
    @Environment(ChineseCalendarStoreCoordinator.self) private var storeCoordinator: ChineseCalendarStoreCoordinator?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var modelContext

    let month: ChineseLunarMonth

    var body: some View {
        let previousMonth = adjacentMonth(direction: .earlier)
        let nextMonth = adjacentMonth(direction: .later)

        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            HStack(alignment: .center, spacing: Constants.headerSpacing) {
                Button(CalendarStringKey.Calendar.MonthNavigation.previous, systemSymbol: .chevronLeft) {
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
                .help(CalendarStringKey.Calendar.MonthNavigation.previousHelp)

                ZStack(alignment: .leading) {
                    titleContent
                        .id(year?.lunarYearNumber)
                        .transition(yearTransition)
                }
                .clipped()
                .animation(yearSelectionAnimation, value: year?.lunarYearNumber)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(CalendarStringKey.Calendar.MonthNavigation.next, systemSymbol: .chevronRight) {
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
                .help(CalendarStringKey.Calendar.MonthNavigation.nextHelp)
            }

            ZStack(alignment: .leading) {
                LunarMonthStrip(
                    months: months,
                    selectedMonth: month,
                    selectMonth: selectMonth,
                    yearTransitionPreparationMonthIndex: feature.pendingYearTransition?.sourceMonthIndex,
                    completeYearTransitionPreparation: feature.completeYearTransitionPreparation
                )
                .id(year?.lunarYearNumber)
                .transition(yearTransition)
            }
            .clipped()
            .animation(yearSelectionAnimation, value: year?.lunarYearNumber)
        }
        .toolbar {
            if #available(iOS 27.1, *) {
                CalendarTodayToolbar(selectToday: feature.selectToday)
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        CalendarStringKey.Calendar.MonthNavigation.today,
                        systemSymbol: .calendarBadgeClock,
                        action: feature.selectToday
                    )
                    .labelStyle(.titleOnly)
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
            String(localized: CalendarStringKey.Calendar.MonthNavigation.missingYear)
        }

        return String(localized: CalendarStringKey.Calendar.MonthNavigation.title(
            year: yearTitle,
            month: LunarMonthDisplay.title(for: month)
        ))
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
            LunarYearContextualTransition(context: feature.yearTransitionContext)
        )
    }

    private var yearSelectionAnimation: Animation {
        reduceMotion
            ? .easeInOut(duration: Constants.reducedMotionDuration)
            : .smooth(duration: Constants.yearSelectionDuration)
    }

    private var titleContent: some View {
        Button {
            feature.connect(modelContext: modelContext, storeCoordinator: storeCoordinator)
            feature.presentYearPicker(presentation: presentation) { session in
                homeCoordinator.yearPickerConfiguration(
                    feature: feature, session: session, storeCoordinator: storeCoordinator
                )
            }
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
        .accessibilityHint(CalendarStringKey.Calendar.YearPicker.accessibilityHint)
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
        feature.selectMonth(destinationMonth, from: month)
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
            ContentUnavailableView {
                Label(
                    CalendarStringKey.Calendar.Unavailable.missingDateTitle,
                    systemSymbol: .calendarBadgeExclamationmark
                )
            }
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
    let month: ChineseLunarMonth = {
        let month = PreviewSampleData.makeStandaloneMonth()
        month.chineseLunarYear = nil
        return month
    }()

    NavigationStack {
        ScrollView {
            YearMonthHeader(month: month)
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
