@testable import ChineseCalendarCore
import Foundation
import Testing

@Test func preservesLeapMonthFlag() {
    let date = ChineseCalendarDate(
        gregorianDate: Date(timeIntervalSince1970: 0),
        lunarYear: 2025,
        lunarMonth: LunarMonth(number: .six, isLeapMonth: true),
        lunarDay: .one
    )

    #expect(date.lunarMonth.isLeapMonth)
    #expect(date.lunarMonth.number == .six)
    #expect(date.lunarMonthNumber == 6)
}

@Test func defaultsLeapMonthFlagToFalse() {
    let date = ChineseCalendarDate(
        gregorianDate: Date(timeIntervalSince1970: 1),
        lunarYear: 2025,
        lunarMonth: LunarMonth(number: .one),
        lunarDay: .fifteen
    )

    #expect(date.lunarMonth.isLeapMonth == false)
    #expect(date.lunarDayNumber == 15)
}

@Test func codableRoundTripPreservesValue() throws {
    let original = ChineseCalendarDate(
        gregorianDate: Date(timeIntervalSince1970: 86400),
        lunarYear: 2024,
        lunarMonth: LunarMonth(number: .eight),
        lunarDay: .twenty
    )
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let data = try encoder.encode(original)
    let decoded = try decoder.decode(ChineseCalendarDate.self, from: data)

    #expect(decoded == original)
}
