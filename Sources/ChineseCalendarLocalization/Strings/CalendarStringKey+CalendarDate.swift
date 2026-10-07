import Foundation

public extension CalendarStringKey.Calendar {
    enum Date {}
}

public extension CalendarStringKey.Calendar.Date {
    static func year(number: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.date.year",
            defaultValue: "公元 \(number, format: .number.grouping(.never)) 年",
            comment: "农历年对应的公元纪年；参数为无千位分隔的年份。"
        )
    }

    static func beforeCommonEraYear(number: UInt) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.date.beforeCommonEraYear",
            defaultValue: "公元前 \(number, format: .number.grouping(.never)) 年",
            comment: "农历年对应的公元前纪年；参数为正整数年份。"
        )
    }

    static func sexagenaryYear(name: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.date.sexagenaryYear",
            defaultValue: "\(name)年",
            comment: "干支年标题；参数为领域模型中的干支名。"
        )
    }

    static func intercalaryMonth(prefix: String, number: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.date.intercalaryMonth",
            defaultValue: "\(prefix)\(number)月",
            comment: "非标准闰后月份；参数依次为历法前缀和月序数。"
        )
    }

    static func month(number: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.date.month",
            defaultValue: "\(number)月",
            comment: "无对应农历月名时的月份；参数为月序数。"
        )
    }

    static func sizedMonth(name: String, size: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.date.sizedMonth",
            defaultValue: "\(name)\(size)",
            comment: "农历月标题；参数依次为历法月名和大小月领域值。"
        )
    }

    static func monthDetail(days: Int, stemBranch: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.date.monthDetail",
            defaultValue: "\(days)天 · \(stemBranch)月",
            comment: "月份副标题；参数依次为天数和月干支。"
        )
    }

    static func day(number: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.date.day",
            defaultValue: "\(number)日",
            comment: "无对应农历日名时的日期；参数为日序数。"
        )
    }
}
