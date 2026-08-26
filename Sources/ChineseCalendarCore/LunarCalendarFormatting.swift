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
        if lunarYearNumber > 0 {
            "公元 \(lunarYearNumber) 年"
        } else {
            "公元前 \(lunarYearNumber.magnitude + 1) 年"
        }
    }

    public static func yearSubtitle(stemIndex: Int, branchIndex: Int) -> String {
        "\(sexagenaryName(stemIndex: stemIndex, branchIndex: branchIndex))年"
    }

    public static func monthTitle(
        monthNumberInYear: Int,
        isLeapMonth: Bool,
        intercalaryMonthNameStyle: LunarIntercalaryMonthNameStyle = .leap,
        dayCount: Int? = nil
    ) -> String {
        let monthName: String = if let monthNumber = LunarMonthNumber(rawValue: monthNumberInYear) {
            LunarMonth(
                number: monthNumber,
                isLeapMonth: isLeapMonth,
                intercalaryMonthNameStyle: intercalaryMonthNameStyle
            )
            .chineseName
        } else {
            if isLeapMonth {
                "\(intercalaryMonthNameStyle.chinesePrefix)\(monthNumberInYear)月"
            } else {
                "\(monthNumberInYear)月"
            }
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
        julianDayNumber: Int,
        locale: Locale
    ) -> String {
        let date = civilDate(fromJulianDayNumber: julianDayNumber)
        let components = gregorianCalendar.dateComponents([.era, .month, .day], from: date)

        // 沿用原有网格规则：每个公历年的首日显示完整日期，用于标记年份切换；
        // 公元前日期若缺少纪元会产生年代歧义，因此始终显示包含纪元的完整日期。
        if components.era == 0 || (components.month == 1 && components.day == 1) {
            return fullCivilDateTitle(julianDayNumber: julianDayNumber, locale: locale)
        }

        return date.formatted(
            Date.FormatStyle(locale: locale, calendar: gregorianCalendar, timeZone: .gmt)
                .month(.defaultDigits)
                .day()
        )
    }

    public static func fullCivilDateTitle(
        julianDayNumber: Int,
        locale: Locale
    ) -> String {
        let date = civilDate(fromJulianDayNumber: julianDayNumber)
        let style = Date.FormatStyle(
            date: .numeric,
            time: .omitted,
            locale: locale,
            calendar: gregorianCalendar,
            timeZone: .gmt
        )

        guard gregorianCalendar.component(.era, from: date) == 0 else {
            return date.formatted(style)
        }

        return date.formatted(style.era())
    }

    public static func civilDateRangeTitle(
        fromJulianDayNumber startJulianDayNumber: Int,
        throughJulianDayNumber endJulianDayNumber: Int,
        locale: Locale
    ) -> String {
        let startDate = civilDate(fromJulianDayNumber: startJulianDayNumber)
        let endDate = civilDate(fromJulianDayNumber: endJulianDayNumber)
        let includesBeforeCommonEra = gregorianCalendar.component(.era, from: startDate) == 0
            || gregorianCalendar.component(.era, from: endDate) == 0

        if includesBeforeCommonEra {
            // IntervalFormatStyle 不支持指定纪元，因此公元前区间使用包含纪元的本地化日期骨架。
            let formatter = DateIntervalFormatter()
            formatter.locale = locale
            formatter.calendar = gregorianCalendar
            formatter.timeZone = .gmt
            formatter.dateTemplate = "GyMd"
            return formatter.string(from: startDate, to: endDate)
        }

        let style = Date.IntervalFormatStyle(
            date: .numeric,
            time: .omitted,
            locale: locale,
            calendar: gregorianCalendar,
            timeZone: .gmt
        )
        return (startDate ..< endDate).formatted(style)
    }

    /// 将整数 JDN 转为其对应的 UTC 正午；这符合 JDN 的日界线定义，并避免把纯日期锚定在午夜边界。
    public static func civilDate(fromJulianDayNumber julianDayNumber: Int) -> Date {
        JulianDayNumber.dateAtNoonUTC(for: julianDayNumber)
    }

    private static func sexagenaryName(stemIndex: Int, branchIndex: Int) -> String {
        SexagenaryName(stemIndex: stemIndex, branchIndex: branchIndex).chineseName
    }

    private static var gregorianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }
}
