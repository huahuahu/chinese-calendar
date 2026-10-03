import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import SwiftData
import Testing

@MainActor
@Suite("Calendar selected-day resolver")
struct CalendarSelectionResolverTests {
    @Test func exactDayLandingHasPriorityOverMonthAndYear() throws {
        let fixture = try Fixture()

        let selectedDayIndex = try fixture.resolver.selectedDayIndex(
            for: LunarCalendarLanding(
                yearNumber: 2025,
                monthIndex: 25001,
                dayIndex: 2_600_102
            ),
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(selectedDayIndex == 2_600_102)
    }

    @Test func monthLandingSelectsTodayWhenTodayBelongsToThatMonth() throws {
        let fixture = try Fixture()

        let selectedDayIndex = try fixture.resolver.selectedDayIndex(
            inMonth: 26001,
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(selectedDayIndex == 2_600_102)
    }

    @Test func monthLandingSelectsFirstDayWhenTodayIsElsewhere() throws {
        let fixture = try Fixture()

        let selectedDayIndex = try fixture.resolver.selectedDayIndex(
            inMonth: 26002,
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(selectedDayIndex == 2_600_201)
    }

    @Test func yearLandingSelectsTodayWhenTodayBelongsToThatYear() throws {
        let fixture = try Fixture()

        let selectedDayIndex = try fixture.resolver.selectedDayIndex(
            inYear: 2026,
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(selectedDayIndex == 2_600_102)
    }

    @Test func yearLandingSelectsFirstDayOnTheContinuousMonthTimeline() throws {
        let fixture = try Fixture()

        let selectedDayIndex = try fixture.resolver.selectedDayIndex(
            inYear: 2025,
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(selectedDayIndex == 2_500_101)
    }

    @Test func yearTransitionSelectsTheDestinationBoundaryMonth() throws {
        let fixture = try Fixture()

        let earlierDayIndex = try fixture.resolver.selectedDayIndex(
            inBoundaryMonthOf: 2025,
            direction: .earlier,
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )
        let laterDayIndex = try fixture.resolver.selectedDayIndex(
            inBoundaryMonthOf: 2025,
            direction: .later,
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(earlierDayIndex == 2_500_201)
        #expect(laterDayIndex == 2_500_101)
    }

    @Test func adjacentMonthsUseTheGlobalContinuousMonthIndex() throws {
        let fixture = try Fixture()

        let previous = try fixture.resolver.adjacentMonth(to: 26001, direction: .earlier)
        let next = try fixture.resolver.adjacentMonth(to: 25002, direction: .later)

        #expect(previous?.lunarMonthIndex == 25002)
        #expect(next?.lunarMonthIndex == 26001)
    }

    @Test func monthWithoutDaysCannotProduceASelection() throws {
        let fixture = try Fixture()

        let selectedDayIndex = try fixture.resolver.selectedDayIndex(
            inMonth: 27001,
            todayJulianDayNumber: fixture.todayJulianDayNumber
        )

        #expect(selectedDayIndex == nil)
    }
}

@MainActor
private extension CalendarSelectionResolverTests {
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

            let month25001 = makeMonth(index: 25001, yearNumber: 2025, monthNumber: 1)
            let month25002 = makeMonth(index: 25002, yearNumber: 2025, monthNumber: 2)
            let month26001 = makeMonth(index: 26001, yearNumber: 2026, monthNumber: 1)
            let month26002 = makeMonth(index: 26002, yearNumber: 2026, monthNumber: 2)
            let month27001 = makeMonth(index: 27001, yearNumber: 2027, monthNumber: 1)

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
            yearNumber: Int,
            monthNumber: Int
        ) -> ChineseLunarMonth {
            ChineseLunarMonth(
                lunarMonthIndex: index,
                lunarYearNumber: yearNumber,
                monthNumberInYear: monthNumber,
                isLeapMonth: false,
                dayCount: 30,
                monthStemIndex: 0,
                monthBranchIndex: 0
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
                lunarMonthIndex: month.lunarMonthIndex,
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
