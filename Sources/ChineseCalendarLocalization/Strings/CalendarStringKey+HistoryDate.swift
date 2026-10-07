import Foundation

public extension CalendarStringKey.History {
    enum Date {}
}

public extension CalendarStringKey.History.Date {
    static var unknown: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.date.unknown",
            defaultValue: "时间待考",
            comment: "界面文案：History.Date.unknown。"
        )
    }

    static func beforeCommonEra(year: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.date.beforeCommonEra",
            defaultValue: "前\(year, format: .number.grouping(.never))",
            comment: "历史年份简写；参数为公元前的正整数年份，不加千位分隔。"
        )
    }

    static func range(start: String, end: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.date.range",
            defaultValue: "\(start)—\(end)",
            comment: "历史日期区间；参数依次为已格式化的起点和终点。"
        )
    }

    static func duration(years: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.date.duration",
            defaultValue: "\(years) 年",
            comment: "在位或年号使用时长；参数为年数。"
        )
    }
}
