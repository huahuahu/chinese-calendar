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
    /// 按标准 JDN 约定，1970-01-01 的 UTC 正午对应 JDN 2,440,588。
    private static let unixEpochJulianDayNumber = 2_440_588

    /// 用 Gregorian Calendar 构造按日偏移的 UTC 正午锚点，避免手工换算秒数。
    private static let unixEpochNoonUTC: Date = {
        var components = DateComponents()
        components.timeZone = .gmt
        components.year = 1970
        components.month = 1
        components.day = 1
        components.hour = 12

        guard let date = gregorianCalendar.date(from: components) else {
            preconditionFailure("无法构造 Unix epoch 的 UTC 正午日期")
        }
        return date
    }()

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

        // 公元前日期必须带纪元；民用年的首日补全年份，其他网格日期只显示本地化月日。
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

        return date.formatted(style.era(.wide))
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
            // IntervalFormatStyle has no era option, so use a localized interval skeleton for BCE dates.
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
        return style.format(startDate ..< endDate)
    }

    /// 将绝对 JDN 转为 UTC 正午 `Date`，避免日期落在用户时区的日界线附近。
    public static func civilDate(fromJulianDayNumber julianDayNumber: Int) -> Date {
        let daysSinceUnixEpoch = julianDayNumber - unixEpochJulianDayNumber
        guard let date = gregorianCalendar.date(
            byAdding: .day,
            value: daysSinceUnixEpoch,
            to: unixEpochNoonUTC
        ) else {
            preconditionFailure("无法将 JDN \(julianDayNumber) 转换为 Foundation Date")
        }
        return date
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
