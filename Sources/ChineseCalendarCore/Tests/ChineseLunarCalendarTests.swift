@testable import ChineseCalendarCore
import Foundation
import Testing

@Test func yearNumberUsesChineseCalendarYearBoundary() throws {
    let timeZone = try #require(TimeZone(secondsFromGMT: 8 * 60 * 60))
    var gregorianCalendar = Calendar(identifier: .gregorian)
    gregorianCalendar.timeZone = timeZone

    let beforeLunarNewYear = try #require(gregorianCalendar.date(from: DateComponents(
        timeZone: timeZone,
        year: 2026,
        month: 1,
        day: 1,
        hour: 12
    )))
    let afterLunarNewYear = try #require(gregorianCalendar.date(from: DateComponents(
        timeZone: timeZone,
        year: 2026,
        month: 5,
        day: 24,
        hour: 12
    )))

    #expect(ChineseLunarCalendar.yearNumber(containing: beforeLunarNewYear, timeZone: timeZone) == 2025)
    #expect(ChineseLunarCalendar.yearNumber(containing: afterLunarNewYear, timeZone: timeZone) == 2026)
}
