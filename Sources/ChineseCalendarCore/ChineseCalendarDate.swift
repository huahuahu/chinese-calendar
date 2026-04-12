import Foundation

/// 农历基础月序，使用枚举避免出现非法月份值。
public enum LunarMonthNumber: Int, Codable, CaseIterable, Sendable {
    case one = 1
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case ten
    case eleven
    case twelve

    public var chineseName: String {
        let names = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
        return names[rawValue - 1]
    }
}

/// 农历中的某个月，闰月与普通月共享同一月序。
public struct LunarMonth: Codable, Equatable, Sendable {
    public let number: LunarMonthNumber
    public let isLeapMonth: Bool

    public var rawValue: Int {
        number.rawValue
    }

    public var chineseName: String {
        let prefix = isLeapMonth ? "闰" : ""
        return prefix + number.chineseName
    }

    public init(number: LunarMonthNumber, isLeapMonth: Bool = false) {
        self.number = number
        self.isLeapMonth = isLeapMonth
    }
}

/// 农历日期，使用枚举避免出现非法日期值。
public enum LunarDay: Int, Codable, CaseIterable, Sendable {
    case one = 1
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case ten
    case eleven
    case twelve
    case thirteen
    case fourteen
    case fifteen
    case sixteen
    case seventeen
    case eighteen
    case nineteen
    case twenty
    case twentyOne
    case twentyTwo
    case twentyThree
    case twentyFour
    case twentyFive
    case twentySix
    case twentySeven
    case twentyEight
    case twentyNine
    case thirty

    public var chineseName: String {
        let names = [
            "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
            "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
            "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
        ]
        return names[rawValue - 1]
    }
}

public struct ChineseCalendarDate: Codable, Equatable, Sendable {
    public let gregorianDate: Date
    public let lunarYear: Int
    public let lunarMonth: LunarMonth
    public let lunarDay: LunarDay

    public var lunarMonthNumber: Int {
        lunarMonth.rawValue
    }

    public var lunarDayNumber: Int {
        lunarDay.rawValue
    }

    public init(
        gregorianDate: Date,
        lunarYear: Int,
        lunarMonth: LunarMonth,
        lunarDay: LunarDay
    ) {
        self.gregorianDate = gregorianDate
        self.lunarYear = lunarYear
        self.lunarMonth = lunarMonth
        self.lunarDay = lunarDay
    }
}
