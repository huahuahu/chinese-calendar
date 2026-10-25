@testable import ChineseCalendarCore
import Testing

@Suite("按真实月长累计定位")
struct LunarMonthDateIndexTests {
    @Test(arguments: [
        (1_640_700, 0, 1), (1_640_703, 0, 4), (1_640_729, 0, 30),
        (1_640_730, 1, 1), (1_640_757, 1, 28), (1_640_758, 2, 1),
        (1_640_780, 2, 23), (1_640_781, 3, 1), (1_640_809, 3, 29)
    ])
    func locatesEveryKindOfMonthBoundary(julianDayNumber: Int, monthIndex: Int, dayNumber: Int) throws {
        let dateIndex = try #require(LunarMonthDateIndex(months: [30, 28, 23, 29].enumerated().map {
            .init(index: $0.offset, dayCount: $0.element)
        }))
        let result = try #require(dateIndex.day(forJulianDayNumber: julianDayNumber))
        #expect(result.monthIndex == monthIndex)
        #expect(result.dayNumberInMonth == dayNumber)
    }

    @Test func doesNotGuessOutsideTheMonthIntervals() throws {
        let dateIndex = try #require(LunarMonthDateIndex(months: [.init(index: 0, dayCount: 28)]))
        #expect(dateIndex.day(forJulianDayNumber: 1_640_699) == nil)
        #expect(dateIndex.day(forJulianDayNumber: 1_640_728) == nil)
    }

    @Test func rejectsMissingDuplicateAndUnorderedMonths() {
        for indexes in [[1], [0, 2], [0, 0], [1, 0]] {
            #expect(LunarMonthDateIndex(months: indexes.map { .init(index: $0, dayCount: 30) }) == nil)
        }
        #expect(LunarMonthDateIndex(months: [LunarMonthDateIndex.Month]()) == nil)
    }

    @Test(arguments: [-1, 0, 31, Int.max])
    func rejectsInvalidDayCounts(dayCount: Int) {
        #expect(LunarMonthDateIndex(months: [.init(index: 0, dayCount: dayCount)]) == nil)
    }

    @Test func supportsAnExplicitAnchorForAPartialDataset() throws {
        let dateIndex = try #require(LunarMonthDateIndex(
            months: [.init(index: 5653, dayCount: 28), .init(index: 5654, dayCount: 30)],
            firstMonthIndex: 5653,
            firstMonthStartJulianDayNumber: 1_807_637
        ))
        #expect(dateIndex.day(forJulianDayNumber: 1_807_664)?.dayNumberInMonth == 28)
        #expect(dateIndex.day(forJulianDayNumber: 1_807_665)?.monthIndex == 5654)
        #expect(dateIndex.day(forJulianDayNumber: 1_807_665)?.dayNumberInMonth == 1)
    }

    @Test func rejectsOverflowingIntervals() {
        #expect(LunarMonthDateIndex(
            months: [.init(index: 0, dayCount: 30)], firstMonthStartJulianDayNumber: Int.max - 2
        ) == nil)
    }
}
