@testable import ChineseCalendarCore
import Foundation
import Testing

@Test func preservesLeapMonthFlag() {
    let date = ChineseCalendarDate(
        gregorianDate: Date(timeIntervalSince1970: 0),
        lunarYear: 2025,
        lunarMonth: 6,
        lunarDay: 1,
        isLeapMonth: true
    )

    #expect(date.isLeapMonth)
    #expect(date.lunarMonth == 6)
}

@Test func defaultsLeapMonthFlagToFalse() {
    let date = ChineseCalendarDate(
        gregorianDate: Date(timeIntervalSince1970: 1),
        lunarYear: 2025,
        lunarMonth: 1,
        lunarDay: 15
    )

    #expect(date.isLeapMonth == false)
}

@Test func codableRoundTripPreservesValue() throws {
    let original = ChineseCalendarDate(
        gregorianDate: Date(timeIntervalSince1970: 86400),
        lunarYear: 2024,
        lunarMonth: 8,
        lunarDay: 20,
        isLeapMonth: false
    )
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let data = try encoder.encode(original)
    let decoded = try decoder.decode(ChineseCalendarDate.self, from: data)

    #expect(decoded == original)
}
