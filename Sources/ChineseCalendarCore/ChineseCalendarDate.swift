import Foundation

public struct ChineseCalendarDate: Codable, Equatable, Sendable {
    public let gregorianDate: Date
    public let lunarYear: Int
    public let lunarMonth: Int
    public let lunarDay: Int
    public let isLeapMonth: Bool

    public init(
        gregorianDate: Date,
        lunarYear: Int,
        lunarMonth: Int,
        lunarDay: Int,
        isLeapMonth: Bool = false
    ) {
        self.gregorianDate = gregorianDate
        self.lunarYear = lunarYear
        self.lunarMonth = lunarMonth
        self.lunarDay = lunarDay
        self.isLeapMonth = isLeapMonth
    }
}
