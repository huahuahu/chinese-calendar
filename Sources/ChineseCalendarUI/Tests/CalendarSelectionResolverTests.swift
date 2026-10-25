import ChineseCalendarCore
import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("Calendar month-or-day selection resolver")
struct CalendarSelectionResolverTests {
    @Test func dayLandingSelectsExactDayInsteadOfToday() throws {
        let fixture = try Fixture()

        let selection = try fixture.resolver.selection(
            for: .day(index: 2_600_101),
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(selection == .day(index: 2_600_101))
    }

    @Test(arguments: [
        LunarCalendarLanding.year(number: 9999),
        .month(index: 99999),
        .day(index: 9_999_999)
    ])
    func missingLandingTargetCannotProduceASelection(landing: LunarCalendarLanding) throws {
        let fixture = try Fixture()

        let selection = try fixture.resolver.selection(
            for: landing,
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(selection == nil)
    }

    @Test func monthLandingSelectsTodayWhenTodayBelongsToThatMonth() throws {
        let fixture = try Fixture()

        let selection = try fixture.resolver.selection(
            for: .month(index: 26001),
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(selection == .day(index: 2_600_102))
    }

    @Test func monthLandingSelectsFirstDayWhenTodayIsElsewhere() throws {
        let fixture = try Fixture()

        let selection = try fixture.resolver.selection(
            for: .month(index: 26002),
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(selection == .day(index: 2_600_201))
    }

    @Test func yearLandingSelectsTodayWhenTodayBelongsToThatYear() throws {
        let fixture = try Fixture()

        let selection = try fixture.resolver.selection(
            for: .year(number: 2026),
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(selection == .day(index: 2_600_102))
    }

    @Test func yearLandingSelectsFirstDayOnTheContinuousMonthTimeline() throws {
        let fixture = try Fixture()

        let selection = try fixture.resolver.selection(
            for: .year(number: 2025),
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(selection == .day(index: 2_500_101))
    }

    @Test func yearTransitionSelectsTheDestinationBoundaryMonth() throws {
        let fixture = try Fixture()

        let earlierSelection = try fixture.resolver.selection(
            inBoundaryMonthOf: 2025,
            direction: .earlier,
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )
        let laterSelection = try fixture.resolver.selection(
            inBoundaryMonthOf: 2025,
            direction: .later,
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(earlierSelection == .day(index: 2_500_201))
        #expect(laterSelection == .day(index: 2_500_101))
    }

    @Test func adjacentMonthsUseTheGlobalContinuousMonthIndex() throws {
        let fixture = try Fixture()

        let previous = try fixture.resolver.adjacentMonth(to: 26001, direction: .earlier)
        let next = try fixture.resolver.adjacentMonth(to: 25002, direction: .later)

        #expect(previous?.lunarMonthIndex == 25002)
        #expect(next?.lunarMonthIndex == 26001)
    }

    @Test func incompleteSelectedDayCannotResolveAValidCalendarPosition() throws {
        let fixture = try Fixture()
        let dayIndex = 2_600_102
        let day = try #require(try fixture.container.mainContext.fetch(
            FetchDescriptor<ChineseLunarDay>(predicate: #Predicate { $0.dayIndex == dayIndex })
        ).first)
        day.chineseLunarMonth = nil
        try fixture.container.mainContext.save()
        #expect(try !fixture.resolver.contains(selection: .day(index: dayIndex)))
        #expect(try fixture.resolver.selection(
            for: .day(index: dayIndex),
            todayJulianDayNumber: fixture.todayJulianDayNumber
        ) == nil)
        #expect(try fixture.resolver.yearNumber(for: .day(index: dayIndex)) == nil)
        #expect(try fixture.resolver.todaySelection(julianDayNumber: fixture.todayJulianDayNumber)?.dayIndex == nil)
    }

    @Test func yearWithoutDaysPreservesTheFirstMonth() throws {
        let fixture = try Fixture()

        let selection = try fixture.resolver.selection(
            for: .year(number: 2027),
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(selection == .month(index: 27001))
    }

    @Test func monthWithoutDaysPreservesMonthPrecision() throws {
        let fixture = try Fixture()

        let selection = try #require(try fixture.resolver.selection(
            for: .month(index: 27001),
            todayJulianDayNumber: fixture.todayJulianDayNumber
        ))

        #expect(selection == .month(index: 27001))
        #expect(try fixture.resolver.month(for: selection)?.lunarMonthIndex == 27001)
        #expect(try fixture.resolver.yearNumber(for: selection) == 2027)
        #expect(try fixture.resolver.contains(selection: .month(index: 27001)))
    }

    @Test func selectionKeepsOnlyOnePrecisionAtATime() {
        let selection = CalendarSelection(value: .month(index: 27001))
        #expect(selection.selectedDayIndex == nil)
        selection.select(dayIndex: 2_600_101)
        #expect(selection.value == .day(index: 2_600_101))
        selection.select(.month(index: 26002))
        #expect(selection.selectedDayIndex == nil)
        selection.select(dayIndex: nil)
        #expect(selection.value == nil)
    }

    @Test(arguments: [
        (0, 0), (29, 0), (30, 1), (57, 1), (58, 2), (80, 2), (81, 3), (109, 3)
    ])
    func baseTodayUsesAccumulatedActualMonthLengths(offset: Int, monthIndex: Int) throws {
        let fixture = try BaseFixture()
        let today = LunarMonthDateIndex.firstMonthStartJulianDayNumber + offset
        #expect(try fixture.container.mainContext.fetchCount(FetchDescriptor<CalendarDay>()) == 0)
        #expect(try fixture.resolver.todaySelection(julianDayNumber: today) == .month(index: monthIndex))
        #expect(try fixture.resolver.selection(for: .today, todayJulianDayNumber: today) == .month(index: monthIndex))
    }

    @Test func baseYearLandingUsesTheYearAndRepeatedMonthFromTheTimeline() throws {
        let fixture = try BaseFixture()
        let today = LunarMonthDateIndex.firstMonthStartJulianDayNumber + 81
        #expect(try fixture.resolver
            .selection(for: .year(number: 237), todayJulianDayNumber: today) == .month(index: 3))
        #expect(try fixture.resolver.yearNumber(for: .month(index: 3)) == 237)
        #expect(try fixture.resolver.adjacentMonth(to: 1, direction: .later)?.lunarMonthIndex == 2)
        #expect(try fixture.resolver.selection(for: .day(index: 81), todayJulianDayNumber: today) == nil)
    }

    @Test func changingMonthNamesDoesNotChangeAbsoluteDatePosition() throws {
        let fixture = try BaseFixture()
        let month = try #require(try fixture.resolver.month(for: .month(index: 3)))
        month.isLeapMonth = true
        month.intercalaryMonthNameStyle = .post
        try fixture.container.mainContext.save()
        let today = LunarMonthDateIndex.firstMonthStartJulianDayNumber + 81
        #expect(try fixture.resolver.todaySelection(julianDayNumber: today) == .month(index: 3))
    }

    @Test(arguments: [0, 1])
    func missingPrefixOrInteriorMonthCannotGuessToday(missingIndex: Int) throws {
        let fixture = try BaseFixture()
        let missing = try #require(try fixture.resolver.month(for: .month(index: missingIndex)))
        fixture.container.mainContext.delete(missing)
        try fixture.container.mainContext.save()
        let today = LunarMonthDateIndex.firstMonthStartJulianDayNumber + 81
        #expect(try fixture.resolver.selection(for: .today, todayJulianDayNumber: today) == nil)
    }

    @Test(arguments: [-1, 110])
    func baseTodayOutsideItsMonthDataRemainsUnavailable(offset: Int) throws {
        let fixture = try BaseFixture()
        let today = LunarMonthDateIndex.firstMonthStartJulianDayNumber + offset
        #expect(try fixture.resolver.todaySelection(julianDayNumber: today) == nil)
    }
}

@MainActor
private extension CalendarSelectionResolverTests {
    /// 人工区间夹具用于短月、跨年与重复月名测试，不表示这几个历史月份的实际起点。
    struct BaseFixture {
        let container: ModelContainer

        var resolver: CalendarSelectionResolver {
            CalendarSelectionResolver(modelContext: container.mainContext)
        }

        init() throws {
            let schema = Schema(ChineseCalendarModelSchema.models, version: ChineseCalendarModelSchema.version)
            container = try ModelContainer(for: schema, configurations: [
                ModelConfiguration("CalendarBaseSelectionTests", schema: schema, isStoredInMemoryOnly: true)
            ])
            let previousYear = ChineseLunarYear(lunarYearNumber: 236, yearStemIndex: 2, yearBranchIndex: 4)
            let year = ChineseLunarYear(lunarYearNumber: 237, yearStemIndex: 3, yearBranchIndex: 5)
            let specifications = [
                (0, 11, 30, previousYear),
                (1, 12, 28, previousYear),
                (2, 1, 23, year),
                (3, 1, 29, year)
            ]
            for (index, number, dayCount, parent) in specifications {
                let month = ChineseLunarMonth(
                    lunarMonthIndex: index, monthNumberInYear: number, isLeapMonth: false, dayCount: dayCount,
                    monthStemIndex: 0, monthBranchIndex: 0, chineseLunarYear: parent
                )
                parent.months.append(month)
            }
            container.mainContext.insert(previousYear)
            container.mainContext.insert(year)
            try container.mainContext.save()
        }
    }

    struct Fixture {
        let container: ModelContainer
        let todayJulianDayNumber = 2_461_042

        var resolver: CalendarSelectionResolver {
            CalendarSelectionResolver(modelContext: container.mainContext)
        }

        init() throws {
            let schema = Schema(
                ChineseCalendarModelSchema.models,
                version: ChineseCalendarModelSchema.version
            )
            let configuration = ModelConfiguration(
                "CalendarSelectionResolverTests",
                schema: schema,
                isStoredInMemoryOnly: true
            )
            container = try ModelContainer(for: schema, configurations: [configuration])

            let year2025 = ChineseLunarYear(lunarYearNumber: 2025, yearStemIndex: 0, yearBranchIndex: 0)
            let year2026 = ChineseLunarYear(lunarYearNumber: 2026, yearStemIndex: 1, yearBranchIndex: 1)
            let year2027 = ChineseLunarYear(lunarYearNumber: 2027, yearStemIndex: 2, yearBranchIndex: 2)

            let month25001 = makeMonth(index: 25001, year: year2025, monthNumber: 1)
            let month25002 = makeMonth(index: 25002, year: year2025, monthNumber: 2)
            let month26001 = makeMonth(index: 26001, year: year2026, monthNumber: 1)
            let month26002 = makeMonth(index: 26002, year: year2026, monthNumber: 2)
            let month27001 = makeMonth(index: 27001, year: year2027, monthNumber: 1)

            attach(month: month25002, to: year2025)
            attach(month: month25001, to: year2025)
            attach(month: month26002, to: year2026)
            attach(month: month26001, to: year2026)
            attach(month: month27001, to: year2027)

            let records = [
                makeDay(index: 2_500_101, number: 1, month: month25001, julianDayNumber: 2_460_900),
                makeDay(index: 2_500_201, number: 1, month: month25002, julianDayNumber: 2_460_930),
                makeDay(index: 2_600_101, number: 1, month: month26001, julianDayNumber: 2_461_041),
                makeDay(index: 2_600_102, number: 2, month: month26001, julianDayNumber: todayJulianDayNumber),
                makeDay(index: 2_600_201, number: 1, month: month26002, julianDayNumber: 2_461_071)
            ]

            let context = container.mainContext
            [year2025, year2026, year2027].forEach(context.insert)
            records.map(\.calendarDay).forEach(context.insert)
            try context.save()
        }

        private func makeMonth(
            index: Int,
            year: ChineseLunarYear,
            monthNumber: Int
        ) -> ChineseLunarMonth {
            ChineseLunarMonth(
                lunarMonthIndex: index,
                monthNumberInYear: monthNumber,
                isLeapMonth: false,
                dayCount: 30,
                monthStemIndex: 0,
                monthBranchIndex: 0,
                chineseLunarYear: year
            )
        }

        private func attach(month: ChineseLunarMonth, to year: ChineseLunarYear) {
            month.chineseLunarYear = year
            year.months.append(month)
        }

        private func makeDay(
            index: Int,
            number: Int,
            month: ChineseLunarMonth,
            julianDayNumber: Int
        ) -> (day: ChineseLunarDay, calendarDay: CalendarDay) {
            let calendarDay = CalendarDay(dayIndex: index, julianDayNumber: julianDayNumber)
            let day = ChineseLunarDay(
                dayIndex: index,
                dayNumberInMonth: number,
                dayStemIndex: 0,
                dayBranchIndex: 0,
                calendarDay: calendarDay,
                chineseLunarMonth: month
            )
            calendarDay.chineseLunarDay = day
            month.days.append(day)
            return (day, calendarDay)
        }
    }
}
