import Foundation

public enum LunarMonthSize: Int, Codable, CaseIterable, Sendable {
    case small = 29
    case big = 30

    public init?(dayCount: Int) {
        self.init(rawValue: dayCount)
    }

    public var chineseName: String {
        switch self {
        case .small:
            "小"
        case .big:
            "大"
        }
    }
}

public enum LunarCalendarFormatting {
    public static func yearTitle(lunarYearNumber: Int) -> String {
        "农历 \(lunarYearNumber) 年"
    }

    public static func yearSubtitle(stemIndex: Int, branchIndex: Int) -> String {
        "\(sexagenaryName(stemIndex: stemIndex, branchIndex: branchIndex))年"
    }

    public static func monthTitle(
        monthNumberInYear: Int,
        isLeapMonth: Bool,
        dayCount: Int? = nil
    ) -> String {
        let monthName: String = if let monthNumber = LunarMonthNumber(rawValue: monthNumberInYear) {
            LunarMonth(number: monthNumber, isLeapMonth: isLeapMonth).chineseName
        } else {
            isLeapMonth ? "闰\(monthNumberInYear)月" : "\(monthNumberInYear)月"
        }

        guard let dayCount, let monthSize = LunarMonthSize(dayCount: dayCount) else {
            return monthName
        }

        return monthName + monthSize.chineseName
    }

    public static func monthSubtitle(dayCount: Int, stemIndex: Int, branchIndex: Int) -> String {
        "\(dayCount)天 · \(sexagenaryName(stemIndex: stemIndex, branchIndex: branchIndex))月"
    }

    public static func dayTitle(dayNumberInMonth: Int) -> String {
        LunarDay(rawValue: dayNumberInMonth)?.chineseName ?? "\(dayNumberInMonth)日"
    }

    public static func daySubtitle(stemIndex: Int, branchIndex: Int) -> String {
        sexagenaryName(stemIndex: stemIndex, branchIndex: branchIndex)
    }

    public static func civilDateTitle(
        year: Int,
        month: Int,
        dayOfMonth: Int,
        isJulianCalendar: Bool
    ) -> String {
        let dateText = month == 1 && dayOfMonth == 1
            ? "\(year)/\(month)/\(dayOfMonth)"
            : "\(month)/\(dayOfMonth)"

        return isJulianCalendar ? "儒略 \(dateText)" : dateText
    }

    private static func sexagenaryName(stemIndex: Int, branchIndex: Int) -> String {
        SexagenaryName(stemIndex: stemIndex, branchIndex: branchIndex).chineseName
    }
}
