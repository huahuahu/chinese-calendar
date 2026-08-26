import Foundation

/// 儒略日数（Julian Day Number，JDN）的换算工具；不表示儒略历日期。
public enum JulianDayNumber {
    /// 按标准 JDN 约定，1970-01-01 的 UTC 正午对应 JDN 2,440,588。
    private static let unixEpoch = 2_440_588

    private static let unixEpochNoonUTC: Date = {
        var components = DateComponents()
        components.timeZone = .gmt
        components.year = 1970
        components.month = 1
        components.day = 1
        components.hour = 12

        guard let date = gregorianUTCCalendar.date(from: components) else {
            preconditionFailure("无法构造 Unix epoch 的 UTC 正午日期")
        }
        return date
    }()

    /// 返回指定瞬间在用户时区所处 Gregorian 民用日期对应的 JDN。
    ///
    /// 这里先读取本地年、月、日，再把这组纯日期组件锚定到 UTC 正午，避免在本地午夜附近
    /// 直接按 UTC 时间戳取整而得到前一天或后一天。
    public static func forLocalGregorianDate(
        containing date: Date,
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> Int {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = timeZone
        let localComponents = localCalendar.dateComponents([.year, .month, .day], from: date)

        var utcComponents = DateComponents()
        utcComponents.timeZone = .gmt
        utcComponents.year = localComponents.year
        utcComponents.month = localComponents.month
        utcComponents.day = localComponents.day
        utcComponents.hour = 12

        guard let localDateAtNoonUTC = gregorianUTCCalendar.date(from: utcComponents),
              let dayOffset = gregorianUTCCalendar.dateComponents(
                  [.day],
                  from: unixEpochNoonUTC,
                  to: localDateAtNoonUTC
              ).day
        else {
            preconditionFailure("无法将用户本地 Gregorian 日期转换为 JDN")
        }

        return unixEpoch + dayOffset
    }

    /// 将整数 JDN 转为其对应的 UTC 正午。
    public static func dateAtNoonUTC(for julianDayNumber: Int) -> Date {
        let daysSinceUnixEpoch = julianDayNumber - unixEpoch
        guard let date = gregorianUTCCalendar.date(
            byAdding: .day,
            value: daysSinceUnixEpoch,
            to: unixEpochNoonUTC
        ) else {
            preconditionFailure("无法将 JDN \(julianDayNumber) 转换为 Foundation Date")
        }
        return date
    }

    private static var gregorianUTCCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }
}
