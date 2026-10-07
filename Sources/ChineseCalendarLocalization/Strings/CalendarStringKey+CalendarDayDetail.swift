import Foundation

public extension CalendarStringKey.Calendar {
    enum DayDetail {}
}

public extension CalendarStringKey.Calendar.DayDetail {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.dayDetail.title",
            defaultValue: "选中日",
            comment: "日历页面下方当前选中日期的详情分区标题。"
        )
    }

    static var lunarExpressionLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.dayDetail.lunarExpressionLabel",
            defaultValue: "农历表达",
            comment: "日历选中日详情中，农历年月日表达字段的标签。"
        )
    }

    static var sexagenaryLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.dayDetail.sexagenaryLabel",
            defaultValue: "日干支",
            comment: "日历选中日详情中，当日天干地支字段的标签。"
        )
    }

    static var contentLevelLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.dayDetail.contentLevelLabel",
            defaultValue: "数据层级",
            comment: "日历选中日详情中，说明当前使用基础数据还是完整日期数据的字段标签。"
        )
    }

    static var civilDateLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.dayDetail.civilDateLabel",
            defaultValue: "对应日期",
            comment: "日历选中日详情中，对应公历日期字段的标签。"
        )
    }

    static func subtitle(stemBranch: String, civilDate: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.dayDetail.subtitle",
            defaultValue: "\(stemBranch)日 · \(civilDate)",
            comment: "选中日副标题；参数依次为日干支和已格式化的公历日期。"
        )
    }

    static func lunarExpression(month: String, day: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.dayDetail.lunarExpression",
            defaultValue: "\(month)\(day)",
            comment: "农历表达；参数依次为带大小月的月名和农历日名。"
        )
    }
}
