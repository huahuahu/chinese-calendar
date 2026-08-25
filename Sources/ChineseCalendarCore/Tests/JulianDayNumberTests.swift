@testable import ChineseCalendarCore
import Foundation
import Testing

@Test func localGregorianDateUsesTheUsersTimeZone() throws {
    let date = utcDate(year: 2026, month: 1, day: 1, hour: 4)
    let utcPlusEight = try #require(TimeZone(secondsFromGMT: 8 * 60 * 60))
    let utcMinusEight = try #require(TimeZone(secondsFromGMT: -8 * 60 * 60))

    #expect(JulianDayNumber.forLocalGregorianDate(
        containing: date,
        timeZone: utcPlusEight
    ) == 2_461_042)
    #expect(JulianDayNumber.forLocalGregorianDate(
        containing: date,
        timeZone: utcMinusEight
    ) == 2_461_041)
}

@Test(
    "本地午夜切换 JDN",
    arguments: [
        (8 * 60 * 60, 2025, 12, 31, 16),
        (-8 * 60 * 60, 2026, 1, 1, 8)
    ]
)
func localMidnightAdvancesJulianDayNumber(
    secondsFromGMT: Int,
    year: Int,
    month: Int,
    day: Int,
    utcHourAtLocalMidnight: Int
) throws {
    let timeZone = try #require(TimeZone(secondsFromGMT: secondsFromGMT))
    let localMidnight = utcDate(
        year: year,
        month: month,
        day: day,
        hour: utcHourAtLocalMidnight
    )

    let beforeMidnight = JulianDayNumber.forLocalGregorianDate(
        containing: localMidnight.addingTimeInterval(-1),
        timeZone: timeZone
    )
    let atMidnight = JulianDayNumber.forLocalGregorianDate(
        containing: localMidnight,
        timeZone: timeZone
    )

    #expect(atMidnight == beforeMidnight + 1)
}

private func utcDate(year: Int, month: Int, day: Int, hour: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt

    var components = DateComponents()
    components.timeZone = .gmt
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour

    guard let date = calendar.date(from: components) else {
        preconditionFailure("无法构造测试日期")
    }
    return date
}
