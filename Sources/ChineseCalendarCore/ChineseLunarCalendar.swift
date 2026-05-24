import Foundation

public enum ChineseLunarCalendar {
    public static func yearNumber(containing date: Date = .now, timeZone: TimeZone = .autoupdatingCurrent) -> Int {
        var lunarCalendar = Calendar(identifier: .chinese)
        lunarCalendar.timeZone = timeZone

        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = timeZone

        return yearNumber(
            containing: date,
            lunarCalendar: lunarCalendar,
            gregorianCalendar: gregorianCalendar
        )
    }

    public static func yearNumber(
        containing date: Date,
        lunarCalendar: Calendar,
        gregorianCalendar: Calendar
    ) -> Int {
        guard let lunarYearStart = lunarCalendar.dateInterval(of: .year, for: date)?.start else {
            return gregorianCalendar.component(.year, from: date)
        }

        return gregorianCalendar.component(.year, from: lunarYearStart)
    }
}
