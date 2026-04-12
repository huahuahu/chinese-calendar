@testable import ChineseCalendarCore
import Foundation
import Testing

@Test func preservesLeapMonthFlag() {
    let date = ChineseCalendarDate(
        gregorianDate: Date(timeIntervalSince1970: 0),
        lunarYear: 2025,
        lunarMonth: .six,
        lunarDay: .one,
        isLeapMonth: true
    )

    #expect(date.isLeapMonth)
    #expect(date.lunarMonth == .six)
    #expect(date.lunarMonthNumber == 6)
}

@Test func defaultsLeapMonthFlagToFalse() {
    let date = ChineseCalendarDate(
        gregorianDate: Date(timeIntervalSince1970: 1),
        lunarYear: 2025,
        lunarMonth: .one,
        lunarDay: .fifteen
    )

    #expect(date.isLeapMonth == false)
    #expect(date.lunarDayNumber == 15)
}

@Test func codableRoundTripPreservesValue() throws {
    let original = ChineseCalendarDate(
        gregorianDate: Date(timeIntervalSince1970: 86400),
        lunarYear: 2024,
        lunarMonth: .eight,
        lunarDay: .twenty,
        isLeapMonth: false
    )
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let data = try encoder.encode(original)
    let decoded = try decoder.decode(ChineseCalendarDate.self, from: data)

    #expect(decoded == original)
}
