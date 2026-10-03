import Foundation

/// Load bounded child collections through SwiftData's indexed inverse relationships.
public enum ChineseCalendarRelationshipQueries {
    public static func days(inMonth month: ChineseLunarMonth) -> [ChineseLunarDay] {
        month.days.sorted { $0.dayNumberInMonth < $1.dayNumberInMonth }
    }

    public static func months(inYear year: ChineseLunarYear) -> [ChineseLunarMonth] {
        year.months.sorted { $0.lunarMonthIndex < $1.lunarMonthIndex }
    }
}
