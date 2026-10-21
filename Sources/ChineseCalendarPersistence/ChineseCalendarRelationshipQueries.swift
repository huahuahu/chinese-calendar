import Foundation

/// 从模型关系读取某月的日或某年的月，再按日号或连续月序排序。
/// 排序在内存中完成，不另外查询全库的日期或月份记录。
public enum ChineseCalendarRelationshipQueries {
    public static func days(inMonth month: ChineseLunarMonth) -> [ChineseLunarDay] {
        month.days.sorted { $0.dayNumberInMonth < $1.dayNumberInMonth }
    }

    public static func months(inYear year: ChineseLunarYear) -> [ChineseLunarMonth] {
        year.months.sorted { $0.lunarMonthIndex < $1.lunarMonthIndex }
    }
}
